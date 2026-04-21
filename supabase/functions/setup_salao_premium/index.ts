import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const EVOLUTION_URL = Deno.env.get("EVOLUTION_URL");
const EVOLUTION_API_KEY = Deno.env.get("EVOLUTION_API_KEY");
const MAESTRO_URL = "https://xwbabsvbcwlqfgcnmxtj.supabase.co/functions/v1/webhook_maestro";

// 🔹 1. Definição dos Headers de CORS
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

serve(async (req) => {
  // 🔹 2. Resposta para a requisição de "preflight" (o navegador testa antes de enviar o POST)
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // 🔹 3. Bloqueia outros métodos que não sejam POST
  if (req.method !== "POST") {
    return new Response("Método não permitido", { 
      status: 405, 
      headers: corsHeaders 
    });
  }

  try {
    const { instancia, celular, salaoNome } = await req.json();

    if (!instancia || !celular || !salaoNome) {
      return new Response(
        JSON.stringify({ error: "Instância, Celular e Nome do Salão são obrigatórios" }),
        { 
          status: 400, 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        }
      );
    }

    console.log(`🔍 Verificando se a instância ${instancia} já existe...`);

    // --- CHECK DE EXISTÊNCIA ---
    const resCheck = await fetch(`${EVOLUTION_URL}/instance/connectionState/${instancia}`, {
      method: "GET",
      headers: { apikey: EVOLUTION_API_KEY! }
    });    
    
    if (resCheck.ok) {
      console.log(`✅ Instância ${instancia} já existe. Recuperando QR Code...`);
      const resConnect = await fetch(`${EVOLUTION_URL}/instance/connect/${instancia}`, {
        method: "GET",
        headers: { apikey: EVOLUTION_API_KEY! }
      });
      const dataConnect = await resConnect.json();

      return new Response(JSON.stringify({
        success: true,
        message: "Instância já existente e pronta.",
        qrcode: dataConnect.base64 || null
      }), { 
        status: 200, 
        headers: { ...corsHeaders, "Content-Type": "application/json" } 
      });
    }
    
    console.log(`🚀 Iniciando setup para: ${instancia} (${salaoNome})`);

    // PASSO 1: Criar instância
    const resCreate = await fetch(`${EVOLUTION_URL}/instance/create`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: EVOLUTION_API_KEY!,
      },
      body: JSON.stringify({
        instanceName: instancia,
        token: "",
        qrcode: true,
        integration: "WHATSAPP-BAILEYS",
        name: salaoNome,
        phoneNumber: celular
      }),
    });

    const dataCreate = await resCreate.json();
    if (!resCreate.ok) {
      throw new Error(`Erro ao criar instância: ${JSON.stringify(dataCreate)}`);
    }

    // PASSO 2: Configuração do Webhook
    const resWebhook = await fetch(`${EVOLUTION_URL}/webhook/set/${instancia}`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: EVOLUTION_API_KEY!,
      },
      body: JSON.stringify({
        webhook: {
          enabled: true,
          url: MAESTRO_URL,
          webhook_by_events: true,
          events: [
            "MESSAGES_UPSERT",
            "CONNECTION_UPDATE",
            "MESSAGES_UPDATE",
            "MESSAGES_DELETE"
          ],
        },
      }),
    });

    const dataWebhook = await resWebhook.json();
    if (!resWebhook.ok) throw new Error(`Erro no webhook: ${JSON.stringify(dataWebhook)}`);

    // PASSO 3: Configurações de Conforto
    const resSettings = await fetch(`${EVOLUTION_URL}/settings/set/${instancia}`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: EVOLUTION_API_KEY!,
      },
      body: JSON.stringify({
        readMessages: true,
        alwaysOnline: true,
        rejectCall: true,
        msgCall: "Olá! Este número é automático e não aceita chamadas de voz.",
        groupsIgnore: false,
        readStatus: true,
        syncFullHistory: false
      }),
    });

    const dataSettings = await resSettings.json();
    if (!resSettings.ok) throw new Error(`Erro nas settings: ${JSON.stringify(dataSettings)}`);

    // 🔹 4. Resposta Final com Sucesso
    return new Response(
      JSON.stringify({
        success: true,
        message: "Setup concluído!",
        qrcode: dataCreate.qrcode?.base64,
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, "Content-Type": "application/json" } 
      }
    );

  } catch (err) {
    console.error(`❌ Erro no Setup: ${err.message}`);
    return new Response(
      JSON.stringify({ error: err.message }), 
      { 
        status: 500, 
        headers: { ...corsHeaders, "Content-Type": "application/json" } 
      }
    );
  }
});