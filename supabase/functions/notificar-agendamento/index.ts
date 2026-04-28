import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { create } from "https://deno.land/x/djwt@v2.8/mod.ts"

serve(async (req) => {
  try {
    const { record, old_record, type } = await req.json()
    
    // 🛑 SEGURANÇA: Se não for INSERT ou DELETE, ignoramos para evitar duplicidade
    if (type !== 'INSERT' && type !== 'DELETE') {
      return new Response(JSON.stringify({ message: "Tipo de evento ignorado" }), { status: 200 })
    }
    
    // Se for DELETE, usamos o 'old_record', se for INSERT usamos o 'record'
    const dadosAgendamento = type === 'DELETE' ? old_record : record

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 1. Buscar detalhes (Nome do Cliente, Serviço, Profissional e Salão)
    const [clienteRes, servicoRes, profissionalRes, salaoRes] = await Promise.all([
      supabaseAdmin.from('clientes').select('nome, celular').eq('id', dadosAgendamento.cliente_id).single(),
      supabaseAdmin.from('servicos').select('nome').eq('id', dadosAgendamento.servico_id).single(),
      dadosAgendamento.profissional_id 
        ? supabaseAdmin.from('profissionais').select('nome').eq('id', dadosAgendamento.profissional_id).single()
        : { data: { nome: 'Qualquer disponível' }, error: null },
      supabaseAdmin.from('saloes').select('nome, dono_id, instancia_whatsapp').eq('id', dadosAgendamento.salao_id).single()
    ])

    const nomeCliente = clienteRes.data?.nome ?? 'Cliente'
    const nomeServico = servicoRes.data?.nome ?? 'Serviço'
    const nomeProfissional = profissionalRes.data?.nome ?? 'Qualquer disponível'
    const nomeSalao = salaoRes.data?.nome ?? 'nosso salão'
    const donoId = salaoRes.data?.dono_id

    // 2. Definir Textos baseados no Tipo de Operação
    const isCancelamento = type === 'DELETE'
    const tituloNotificacao = isCancelamento ? "❌ AGENDAMENTO CANCELADO" : "📝 NOVO AGENDAMENTO RECEBIDO"
    const rodapeWhatsApp = isCancelamento ? "Agendamento cancelado! Obrigado!" : `Tudo certo! Te esperamos no ${nomeSalao}. 😊`

    const dataFormatada = dadosAgendamento.data.split('-').reverse().join('/')
    const horaFormatada = dadosAgendamento.hora.substring(0, 5)

    const corpoBase = 
`👤 Cliente: ${nomeCliente}
✂️ Serviço: ${nomeServico}
🧔 Profissional: ${nomeProfissional}
📅 Data: ${dataFormatada}
⏰ Hora: ${horaFormatada}`

    const mensagemWhatsApp = `${corpoBase}\n\n${rodapeWhatsApp}`

    // 3. Buscar os tokens FCM do dono para notificação Push
    const { data: tokens } = await supabaseAdmin
      .from('fcm_tokens')
      .select('token')
      .eq('usuario_id', donoId)

    // 4. Autenticação Firebase (JWT)
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

    // 5. Enviar Notificação Push para o Dono
    if (tokens && tokens.length > 0) {
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
                title: tituloNotificacao,
                body: isCancelamento ? `O agendamento de ${nomeCliente} foi cancelado.` : corpoBase
              },
              android: { 
                priority: "high",
                notification: { sound: "default", click_action: "FLUTTER_NOTIFICATION_CLICK" }
              }
            }
          })
        })
      }
    }

    // 6. Envio do WhatsApp para o Cliente (Evolution API)
    if (clienteRes.data?.celular) {
      const evolutionUrl = Deno.env.get('EVOLUTION_URL')?.replace(/\/$/, '');
      const evolutionApiKey = Deno.env.get('EVOLUTION_API_KEY');
      const instanciaWhatsapp = salaoRes.data?.instancia_whatsapp;

      if (evolutionUrl && evolutionApiKey && instanciaWhatsapp) {
        const urlFinal = `${evolutionUrl}/message/sendText/${instanciaWhatsapp}`;
        await fetch(urlFinal, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'apikey': evolutionApiKey },
          body: JSON.stringify({
            "number": clienteRes.data.celular,
            "text": mensagemWhatsApp,
            "options": { "delay": 1200, "presence": "composing" }
          }),
        });
      }
    }

    return new Response(JSON.stringify({ success: true }), { status: 200 })

  } catch (error) {
    console.error('💥 Erro:', error.message)
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
})