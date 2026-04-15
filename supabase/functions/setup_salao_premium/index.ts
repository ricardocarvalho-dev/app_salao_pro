import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const EVOLUTION_URL = Deno.env.get("EVOLUTION_URL");
const EVOLUTION_API_KEY = Deno.env.get("EVOLUTION_API_KEY");
const MAESTRO_URL = "https://xwbabsvbcwlqfgcnmxtj.supabase.co/functions/v1/webhook_maestro";

serve(async (req) => {
  // Apenas métodos POST são aceitos
  if (req.method !== 'POST') return new Response("Método não permitido", { status: 405 });

  try {
    const { instancia, celular } = await req.json();

    if (!instancia || !celular) {
      return new Response(JSON.stringify({ error: "Instância e Celular são obrigatórios" }), { status: 400 });
    }

    console.log(`🚀 Iniciando setup para: ${instancia}`);

    // PASSO 1: Criar a Instância na Evolution
    /*
    const resCreate = await fetch(`${EVOLUTION_URL}/instance/create`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "apikey": EVOLUTION_API_KEY! },
      body: JSON.stringify({
        instanceName: instancia,
        number: celular,
        qrcode: true
      })
    });
    */
    // PASSO 1: Criar a Instância na Evolution
    const resCreate = await fetch(`${EVOLUTION_URL}/instance/create`, {
      method: "POST",
      headers: { 
        "Content-Type": "application/json", 
        "apikey": EVOLUTION_API_KEY! 
      },
      body: JSON.stringify({
        instanceName: instancia,
        token: "", // A API gera o token automaticamente
        qrcode: true,
        integration: "WHATSAPP-BAILEYS" // ESSA LINHA É OBRIGATÓRIA NA V2.3.7
      })
    });

    const dataCreate = await resCreate.json();

    if (!resCreate.ok) throw new Error(`Erro ao criar instância: ${JSON.stringify(dataCreate)}`);

    // PASSO 2: Configurar o Webhook apontando para o Maestro
    /*
    await fetch(`${EVOLUTION_URL}/webhook/set/${instancia}`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "apikey": EVOLUTION_API_KEY! },
      body: JSON.stringify({
        enabled: true,
        url: MAESTRO_URL,
        webhook_by_events: false,
        events: ["MESSAGES_UPSERT", "CONNECTION_UPDATE"]
      })
    });
    */
   
    // PASSO 2: Configurar o Webhook apontando para o Maestro
    // Use o endpoint /webhook/instance/set para garantir compatibilidade
    await fetch(`${EVOLUTION_URL}/webhook/set/${instancia}`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "apikey": EVOLUTION_API_KEY! },
      body: JSON.stringify({
        enabled: true,
        url: MAESTRO_URL,
        webhook_by_events: false,
        events: [
          "MESSAGES_UPSERT",
          "CONNECTION_UPDATE",
          "TYPEOUT_UPSERT" // Opcional, mas útil
        ]
      })
    });

    // PASSO 3: Configurações de Conforto (Read, Online, Reject Calls)
    await fetch(`${EVOLUTION_URL}/settings/set/${instancia}`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "apikey": EVOLUTION_API_KEY! },
      body: JSON.stringify({
        readMessages: true,
        alwaysOnline: true,
        rejectCall: true,
        msgCall: "Olá! Este número é automático e não aceita chamadas de voz."
      })
    });

    return new Response(JSON.stringify({ 
      success: true, 
      message: "Setup concluído!",
      qrcode: dataCreate.qrcode?.base64 // Retorna o QR Code para você ver no Postman
    }), { status: 200 });

  } catch (err) {
    console.error(`❌ Erro no Setup: ${err.message}`);
    return new Response(JSON.stringify({ error: err.message }), { status: 500 });
  }
});