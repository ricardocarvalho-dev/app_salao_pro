import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const EVOLUTION_URL = Deno.env.get("EVOLUTION_URL");
const EVOLUTION_API_KEY = Deno.env.get("EVOLUTION_API_KEY");
const MAESTRO_URL = "https://xwbabsvbcwlqfgcnmxtj.supabase.co/functions/v1/webhook_maestro";

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Método não permitido", { status: 405 });
  }

  try {
    const { instancia, celular, salaoNome } = await req.json();

    if (!instancia || !celular || !salaoNome) {
      return new Response(
        JSON.stringify({ error: "Instância, Celular e Nome do Salão são obrigatórios" }),
        { status: 400 }
      );
    }

    console.log(`🚀 Iniciando setup para: ${instancia} (${salaoNome})`);

    // PASSO 1: Criar instância com nome do salão e celular
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
        name: salaoNome,       // nome amigável do salão cliente
        phoneNumber: celular   // número de celular vinculado
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
    console.log("Webhook response:", dataWebhook);

    if (!resWebhook.ok) {
      throw new Error(
        `Erro ao configurar webhook: ${JSON.stringify(dataWebhook)}`
      );
    }

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
    console.log("Settings response:", dataSettings);

    if (!resSettings.ok) {
      throw new Error(
        `Erro ao configurar settings: ${JSON.stringify(dataSettings)}`
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Setup concluído!",
        qrcode: dataCreate.qrcode?.base64,
      }),
      { status: 200 }
    );
  } catch (err) {
    console.error(`❌ Erro no Setup: ${err.message}`);
    return new Response(JSON.stringify({ error: err.message }), { status: 500 });
  }
});
