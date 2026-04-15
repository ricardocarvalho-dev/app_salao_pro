import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { create } from "https://deno.land/x/djwt@v2.8/mod.ts"

serve(async (req) => {
  try {
    const { record } = await req.json()
    
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const [clienteRes, servicoRes, profissionalRes, salaoRes] = await Promise.all([
      supabaseAdmin.from('clientes').select('nome, celular').eq('id', record.cliente_id).single(),
      supabaseAdmin.from('servicos').select('nome').eq('id', record.servico_id).single(),
      record.profissional_id 
        ? supabaseAdmin.from('profissionais').select('nome').eq('id', record.profissional_id).single()
        : { data: { nome: 'Qualquer disponível' }, error: null },
      supabaseAdmin.from('saloes').select('dono_id, instancia_whatsapp').eq('id', record.salao_id).single()
    ])

    const nomeCliente = clienteRes.data?.nome ?? 'Cliente não identificado'
    const nomeServico = servicoRes.data?.nome ?? 'Serviço não identificado'
    const nomeProfissional = profissionalRes.data?.nome ?? 'Qualquer disponível'
    const donoId = salaoRes.data?.dono_id

    // 2. Buscar os tokens FCM do dono
    const { data: tokens } = await supabaseAdmin
      .from('fcm_tokens')
      .select('token')
      .eq('usuario_id', donoId)

    if (!tokens || tokens.length === 0) return new Response("Sem tokens", { status: 200 })

    // 3. Autenticação Google Firebase (OAuth2)
    const client_email = Deno.env.get('FIREBASE_CLIENT_EMAIL')
    const private_key = Deno.env.get('FIREBASE_PRIVATE_KEY')?.replace(/\\n/g, '\n')
    const project_id = Deno.env.get('FIREBASE_PROJECT_ID')

    const header = { alg: "RS256", typ: "JWT" }
    const now = Math.floor(Date.now() / 1000)
    const payload = {
      iss: client_email,
      sub: client_email,
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
      scope: "https://www.googleapis.com/auth/firebase.messaging"
    }

    const keyContent = private_key!.split("-----")[2].replace(/\s/g, "")
    const key = await crypto.subtle.importKey(
      "pkcs8",
      Uint8Array.from(atob(keyContent), c => c.charCodeAt(0)),
      { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
      false,
      ["sign"]
    )
    
    const jwt = await create(header, payload, key)
    const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      body: new URLSearchParams({ grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion: jwt })
    })
    const { access_token } = await tokenRes.json()

    // 4. Montar o Corpo Estilizado (Incluindo o Cliente)
    const dataFormatada = record.data.split('-').reverse().join('/')
    const horaFormatada = record.hora.substring(0, 5)

    const corpoNotificacao = 
`👤 Cliente: ${nomeCliente}
✂️ Serviço: ${nomeServico}
🧔 Profissional: ${nomeProfissional}
📅 Data: ${dataFormatada}
⏰ Hora: ${horaFormatada}`

    // 5. Enviar para os dispositivos
    for (const item of tokens) {
      await fetch(`https://fcm.googleapis.com/v1/projects/${project_id}/messages:send`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${access_token}`,
        },
        body: JSON.stringify({
          message: {
            token: item.token,
            notification: {
              title: "📝 NOVO AGENDAMENTO RECEBIDO",
              body: corpoNotificacao
            },
            // 🚀 O SEGREDO ESTÁ AQUI:
            data: {
              tipo: "novo_agendamento",
              salaoId: record.salao_id.toString(),
              dataAgendamento: record.data, // Garante que envie "2026-03-19"
              clienteId: record.cliente_id.toString(),
              profissionalId: (record.profissional_id ?? "").toString(),
              servicoId: record.servico_id.toString(),
            },
            // 📱 CONFIGURAÇÕES PARA GARANTIR QUE A NOTIFICAÇÃO CHEGUE COM SOM E SEJA ABERTA AO TOCAR
            android: { 
              priority: "high",
              notification: {
                sound: "default",
                click_action: "FLUTTER_NOTIFICATION_CLICK"
              }
            }
          }
        })
      })
    }

    // 6. Envio do WhatsApp (Evolution API)
    if (clienteRes.data?.celular) {
      const evolutionUrl = Deno.env.get('EVOLUTION_URL');
      const evolutionApiKey = Deno.env.get('EVOLUTION_API_KEY');
       const instanciaWhatsapp = salaoRes.data?.instancia_whatsapp;
       const telefoneCliente = clienteRes.data?.celular;

      if (evolutionUrl && evolutionApiKey && instanciaWhatsapp) {
        try {
          const urlLimpa = evolutionUrl.replace(/\/$/, '');
          const urlFinal = `${urlLimpa}/message/sendText/${instanciaWhatsapp}`;

          const celular = clienteRes.data?.celular;
          const payload = {
            "number": celular,
            "text": corpoNotificacao,
            "options": {
              "delay": 1200,
              "presence": "composing",
              "linkPreview": false
            }
          };

          const response = await fetch(urlFinal, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'apikey': evolutionApiKey
            },
            body: JSON.stringify(payload),
          });

          if (!response.ok) {
            const errorText = await response.text();
            console.error('Resposta da Evolution:', errorText);
            console.error('Erro ao enviar mensagem via Evolution API:', response.status, response.statusText);
          } else {
            console.log('Notificação enviada com sucesso para o ID:', record.id);
          }
        } catch (error) {
          console.error('Erro ao enviar mensagem via Evolution API:', error.message);
        }
      } else {
        console.warn('Variáveis de ambiente EVOLUTION_URL, EVOLUTION_API_KEY ou instancia_whatsapp não configuradas.');
      }
     } else {
       console.warn('Celular do cliente não encontrado. Mensagem não enviada.');
     }

    return new Response(JSON.stringify({ success: true }), { status: 200 })

  } catch (error) {
    console.error('💥 Erro:', error.message)
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
})