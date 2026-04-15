import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

const IDENTIFICAR_FUNCTION_URL = "https://xwbabsvbcwlqfgcnmxtj.supabase.co/functions/v1/identificar_ou_criar_cliente";

serve(async (req) => {
  try {
    const payload = await req.json();
    console.log("[Maestro] Payload recebido:", JSON.stringify(payload));

    // --- FLUXO A: AGENDAMENTO (SAÍDA) ---
    // Se o payload vier do Database Webhook do Supabase
    if (payload.table === 'agendamentos' && payload.type === 'INSERT') {
      console.log("📅 Novo Agendamento! Preparando notificação...");
      // Lógica de notificação de saída entra aqui
      return new Response("Notificação Processada", { status: 200 });
    }

    // --- FLUXO B: CHATBOT (ENTRADA) ---
    // Ajuste para pegar o celular do salão (instância) de forma resiliente
    const celularOriginalSalao = payload.instanceId?.split("-")[0] || payload.sender?.split("@")[0];
    const dadosMensagem = payload.data;
    
    // Evita processar mensagens enviadas pelo PRÓPRIO salão
    if (dadosMensagem?.key?.fromMe === true) {
      return new Response("Mensagem enviada pela instância, ignorando.", { status: 200 });
    }

    if (!celularOriginalSalao) {
      console.error("❌ Identificador da instância não encontrado no payload");
      return new Response("Instance ID não encontrado", { status: 200 });
    }

    // Lógica do Nono Dígito
    let celularSalaoComNove = celularOriginalSalao.length === 12 
      ? celularOriginalSalao.slice(0, 4) + '9' + celularOriginalSalao.slice(4) 
      : celularOriginalSalao;

    // Busca do Salão
    const { data: salao, error } = await supabase
      .from("saloes")
      .select("id, nome, chatbot_ativo")
      .or(`celular.eq.${celularOriginalSalao},celular.eq.${celularSalaoComNove}`)
      .maybeSingle();

    if (error || !salao) {
      console.error(`❌ Salão [${celularOriginalSalao}] não encontrado no banco.`);
      return new Response("Salão não cadastrado", { status: 200 });
    }

    if (!salao.chatbot_ativo) {
      console.log(`🛑 Chatbot inativo para: ${salao.nome}`);
      return new Response("Chatbot desativado", { status: 200 });
    }

    // Encaminhamento
    const celularCliente = dadosMensagem?.key?.remoteJid?.split("@")[0];
    const nomeCliente = dadosMensagem?.pushName || "Cliente";

    console.log(`✅ Encaminhando mensagem de [${nomeCliente}] para o salão [${salao.nome}]`);

    await fetch(IDENTIFICAR_FUNCTION_URL, {
      method: "POST",
      headers: { 
        "Content-Type": "application/json",
        "Authorization": `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`
      },
      body: JSON.stringify({
        celular: celularCliente,
        nome: nomeCliente,
        salaoId: salao.id,
        originalBody: payload
      }),
    });

    return new Response("OK", { status: 200 });

  } catch (err) {
    console.error("[Maestro] Erro Crítico:", err.message);
    return new Response(err.message, { status: 500 });
  }
});