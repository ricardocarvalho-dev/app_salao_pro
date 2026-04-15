import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const supabase = createClient(supabaseUrl, supabaseKey);
const BASE_URL = "https://xwbabsvbcwlqfgcnmxtj.supabase.co/functions/v1";

function nEmoji(num: number | string): string {
  const map: any = { "0": "0️⃣", "1": "1️⃣", "2": "2️⃣", "3": "3️⃣", "4": "4️⃣", "5": "5️⃣", "6": "6️⃣", "7": "7️⃣", "8": "8️⃣", "9": "9️⃣" };
  return num.toString().split("").map(d => map[d] || d).join("");
}

function interpretarData(texto: string): string | null {
  const hoje = new Date();
  const anoAtual = hoje.getFullYear();
  const mesAtual = hoje.getMonth() + 1;
  texto = texto.toLowerCase().trim();
  if (texto === "hoje") return hoje.toISOString().split('T')[0];
  if (texto === "amanhã" || texto === "amanha") {
    const amanha = new Date();
    amanha.setDate(hoje.getDate() + 1);
    return amanha.toISOString().split('T')[0];
  }
  const match = texto.match(/(\d{1,2})\/(\d{1,2})/);
  if (match) {
    const dia = match[1].padStart(2, '0');
    const mesDigitado = parseInt(match[2]);
    const anoResultado = (mesDigitado < mesAtual) ? anoAtual + 1 : anoAtual;
    return `${anoResultado}-${match[2].padStart(2, '0')}-${dia}`;
  }
  return null;
}

serve(async (req) => {
  try {
    const body = await req.json();
    const { celular, nome, salaoId, originalBody } = body;

    // --- 1. BUSCA DINÂMICA DO SALÃO ---
    const { data: dadosSalao } = await supabase
      .from("saloes")
      .select("nome, instancia_whatsapp")
      .eq("id", salaoId)
      .single();

    const nomeDoSalao = dadosSalao?.nome || "Salão";
    
    // Prioriza a instância que o Maestro detectou no payload original
    const instanciaFinal = originalBody?.instance || dadosSalao?.instancia_whatsapp || "salao_rico"; 

    const input = (originalBody?.data?.message?.conversation || originalBody?.data?.message?.extendedTextMessage?.text || "").trim();
    let num = celular.length === 12 ? celular.slice(0, 4) + '9' + celular.slice(4) : celular;

    let { data: cliente } = await supabase.from("clientes").select("*").eq("salao_id", salaoId).or(`celular.eq.${celular},celular.eq.${num}`).maybeSingle();
    
    if (!cliente) {
      const { data: n } = await supabase.from("clientes").insert([{ celular: num, nome, salao_id: salaoId, status_chat: 'menu_principal' }]).select().single();
      cliente = n;
    }

    let resposta = "", novoStatus = cliente.status_chat || 'menu_principal';

    const ultimaAtividade = cliente.updated_at ? new Date(cliente.updated_at).getTime() : new Date().getTime();
    const agora = new Date().getTime();
    const minutosPassados = (agora - ultimaAtividade) / (1000 * 60);

    const textoMenuPrincipal = `Olá *${cliente.nome}*! Bem-vindo ao *${nomeDoSalao}*! ✂️\n\nComo podemos te ajudar hoje?\n\n${nEmoji(1)} - Agendamento\n${nEmoji(2)} - Meus agendamentos\n${nEmoji(3)} - Falar com atendente\n${nEmoji(4)} - Encerrar`;

    if (minutosPassados > 30 && novoStatus !== 'menu_principal') {
      await supabase.from("atendimento_contexto").delete().eq("cliente_id", cliente.id);
      novoStatus = 'menu_principal';
      resposta = textoMenuPrincipal;
    }

    if ((novoStatus === 'atendimento_humano' || novoStatus === 'atendimento_encerrado') && input !== "0") {
      return new Response(JSON.stringify({ ok: true }), { status: 200 });
    }

    if (input === "0") {
      await supabase.from("atendimento_contexto").delete().eq("cliente_id", cliente.id);
      novoStatus = 'menu_principal';
      resposta = textoMenuPrincipal;
    }

    if (!resposta) {
      if (novoStatus === 'menu_principal') {
        if (input === "1") {
          resposta = "*Agendamento* 📅\n\nComo você prefere escolher?\n\n" + nEmoji(1) + " - Por SERVIÇO\n" + nEmoji(2) + " - Por PROFISSIONAL\n\n" + nEmoji(0) + " - Voltar ao início";
          novoStatus = 'aguardando_tipo_agendamento';
        } else if (input === "2") {
          const resAg = await fetch(`${BASE_URL}/listar_agendamentos_publicos`, { method: "POST", headers: { "Content-Type": "application/json", "Authorization": `Bearer ${supabaseKey}` }, body: JSON.stringify({ cliente_id: cliente.id }) });
          const agendamentos = await resAg.json();
          if (agendamentos?.length > 0) {
            let lista = "📝 *Seus Agendamentos:*\n\n";
            agendamentos.forEach((ag: any) => {
              const dataBR = ag.data.split('-').reverse().join('/');
              const horaCurta = ag.hora.split(':').slice(0, 2).join(':');
              lista += `🗓️ *${dataBR}* às *${horaCurta}*\n🔹 ${ag.servico_nome}\n👤 Prof: ${ag.profissional_nome || 'Por demanda'}\n\n`;
            });
            resposta = lista + "Digite *0* para voltar ao menu principal. ↩️";
          } else { resposta = "Você ainda não possui agendamentos ativos. 🗓️\n\nQue tal marcar um agora? Digite *1*."; }
        } else if (input === "3") {
          resposta = "👤 *Atendimento Humano*\n\nEntendi! Vou chamar um atendente. 😊\n\n_Para voltar ao menu, digite *0*._";
          novoStatus = 'atendimento_humano';
        } else if (input === "4") {
          resposta = `Obrigado pelo contato, *${cliente.nome}*! 👋\n\nAtendimento encerrado com sucesso. Para voltar, digite *0*.`;
          novoStatus = 'atendimento_encerrado';
        } else { resposta = textoMenuPrincipal; }

      } else if (novoStatus === 'aguardando_tipo_agendamento') {
        if (input === "1" || input === "2") {
          const porServ = (input === "1");
          const res = await fetch(`${BASE_URL}/${porServ ? "listar_servicos_publicos" : "listar_profissionais_publicos"}`, { method: "POST", headers: { "Content-Type": "application/json", "Authorization": `Bearer ${supabaseKey}` }, body: JSON.stringify({ salao_id: salaoId }) });
          const dados = await res.json();
          if (dados?.length > 0) {
            await supabase.from("atendimento_contexto").delete().eq("cliente_id", cliente.id);
            let lista = porServ ? "✂️ *Escolha o Serviço:*\n\n" : "💈 *Escolha o Profissional:*\n\n";
            const inserts = dados.map((item: any, i: number) => {
              const n = (i + 1).toString();
              lista += nEmoji(n) + " - " + item.nome + "\n";
              return { cliente_id: cliente.id, opcao_numero: n, valor_id: item.id, tipo_dado: porServ ? 'servico' : 'profissional' };
            });
            await supabase.from("atendimento_contexto").insert(inserts);
            resposta = lista + "\n" + nEmoji(0) + " - Voltar ↩️";
            novoStatus = porServ ? 'aguardando_selecao_servico' : 'aguardando_selecao_profissional';
          }
        } else {
          resposta = "⚠️ *Opção inválida.*\n\n" + nEmoji(1) + " - Por SERVIÇO\n" + nEmoji(2) + " - Por PROFISSIONAL\n\n" + nEmoji(0) + " - Voltar";
        }

      } else if (novoStatus === 'aguardando_selecao_profissional') {
        const { data: ctx } = await supabase.from("atendimento_contexto").select("valor_id").eq("cliente_id", cliente.id).eq("opcao_numero", input).eq("tipo_dado", 'profissional').maybeSingle();
        if (ctx) {
          const res = await fetch(`${BASE_URL}/listar_servicos_publicos`, { method: "POST", headers: { "Content-Type": "application/json", "Authorization": `Bearer ${supabaseKey}` }, body: JSON.stringify({ salao_id: salaoId, profissional_id: ctx.valor_id }) });
          const servs = await res.json();
          await supabase.from("atendimento_contexto").delete().eq("cliente_id", cliente.id);
          let lista = "✂️ *Serviços deste Profissional:*\n\n";
          const inserts = servs.map((s: any, i: number) => { 
            const n = (i + 1).toString(); 
            lista += nEmoji(n) + " - " + s.nome + "\n"; 
            return { cliente_id: cliente.id, opcao_numero: n, valor_id: s.id, profissional_id: ctx.valor_id, tipo_dado: 'servico' }; 
          });
          await supabase.from("atendimento_contexto").insert(inserts);
          resposta = lista + "\n" + nEmoji(0) + " - Voltar ↩️";
          novoStatus = 'aguardando_selecao_servico';
        } else {
          resposta = "⚠️ *Profissional não encontrado.*\n\nPor favor, escolha um número da lista ou digite *0* para voltar. ↩️";
        }

      } else if (novoStatus === 'aguardando_selecao_servico') {
        const { data: ctxServ } = await supabase.from("atendimento_contexto").select("*").eq("cliente_id", cliente.id).eq("opcao_numero", input).eq("tipo_dado", 'servico').maybeSingle();
        if (ctxServ) {
          await supabase.from("atendimento_contexto").delete().eq("cliente_id", cliente.id);
          await supabase.from("atendimento_contexto").insert({ cliente_id: cliente.id, servico_id: ctxServ.valor_id, profissional_id: ctxServ.profissional_id, tipo_dado: 'servico_selecionado', opcao_numero: '99' });
          resposta = "✅ *Ótima escolha!*\n\nDigite a *DATA* (Ex: Hoje, Amanhã, 15/03) 📅";
          novoStatus = 'aguardando_data';
        } else {
          resposta = "⚠️ *Serviço não encontrado.*\n\nPor favor, escolha um número da lista ou digite *0* para voltar. ↩️";
        }

      } else if (novoStatus === 'aguardando_data') {
        const dataFormatada = interpretarData(input);
        if (dataFormatada) {
          const { data: ctxS } = await supabase.from("atendimento_contexto").select("servico_id, profissional_id").eq("cliente_id", cliente.id).eq("tipo_dado", 'servico_selecionado').maybeSingle();
          const resSlots = await fetch(`${BASE_URL}/listar_slots_publicos`, { method: "POST", headers: { "Content-Type": "application/json", "Authorization": `Bearer ${supabaseKey}` }, body: JSON.stringify({ salao_id: salaoId, servico_id: ctxS.servico_id, data: dataFormatada, profissional_id: ctxS.profissional_id || "" }) });
          const slots = await resSlots.json();
          if (slots?.length > 0) {
            await supabase.from("atendimento_contexto").delete().eq("cliente_id", cliente.id);
            let lista = `📅 *Horários para ${input}:*\n\n`;
            const inserts = slots.map((s: any, i: number) => { 
              const n = (i + 1).toString(); 
              lista += nEmoji(n) + " - " + s.horario + "\n"; 
              return { cliente_id: cliente.id, opcao_numero: n, servico_id: ctxS.servico_id, profissional_id: ctxS.profissional_id, data_selecionada: dataFormatada, horario_selecionado: s.horario, tipo_dado: 'horario' }; 
            });
            await supabase.from("atendimento_contexto").insert(inserts);
            resposta = lista + "\n" + nEmoji(0) + " - Voltar ↩️";
            novoStatus = 'aguardando_horario';
          } else { resposta = "Não há horários livres para esta data. 😕 Tente outra!"; }
        } else { resposta = "⚠️ Data inválida. Digite Ex: 15/03 ou 'Amanhã'."; }

      } else if (novoStatus === 'aguardando_horario') {
        const { data: ctxH } = await supabase.from("atendimento_contexto").select("*").eq("cliente_id", cliente.id).eq("opcao_numero", input).eq("tipo_dado", 'horario').maybeSingle();
        if (ctxH) {
          const { data: srv } = await supabase.from("servicos").select("nome").eq("id", ctxH.servico_id).single();
          const { data: prof } = ctxH.profissional_id ? await supabase.from("profissionais").select("nome").eq("id", ctxH.profissional_id).single() : { data: { nome: "Qualquer disponível" } };
          const dataBR = ctxH.data_selecionada.split('-').reverse().join('/');
          await supabase.from("atendimento_contexto").update({ tipo_dado: 'confirmacao_pendente' }).eq("id", ctxH.id);
          resposta = `📝 *CONFIRMAÇÃO DO AGENDAMENTO*\n\n✂️ *Serviço:* ${srv.nome}\n👤 *Profissional:* ${prof.nome}\n📅 *Data:* ${dataBR}\n⏰ *Hora:* ${ctxH.horario_selecionado}\n\nPodemos confirmar?\n\n${nEmoji(1)} - Sim, confirmar!\n${nEmoji(2)} - Não, quero mudar algo`;
          novoStatus = 'aguardando_confirmacao_final';
        } else {
          resposta = "⚠️ *Horário inválido.*\n\nEscolha um número da lista de horários ou digite *0* para voltar. ↩️";
        }

      } else if (novoStatus === 'aguardando_confirmacao_final') {
        if (input === "1") {
          const { data: final } = await supabase.from("atendimento_contexto").select("*").eq("cliente_id", cliente.id).eq("tipo_dado", 'confirmacao_pendente').maybeSingle();
          if (final) {
            const resConfirmar = await fetch(`${BASE_URL}/confirmar_agendamento_publico`, { method: "POST", headers: { "Content-Type": "application/json", "Authorization": `Bearer ${supabaseKey}` }, body: JSON.stringify({ salao_id: salaoId, servico_id: final.servico_id, cliente_id: cliente.id, data: final.data_selecionada, hora: final.horario_selecionado, profissional_id: final.profissional_id }) });
            const resultado = await resConfirmar.json();
            if (resultado.sucesso) {
              resposta = `✅ *AGENDAMENTO CONCLUÍDO!*\n\nTudo certo! Te esperamos no *${nomeDoSalao}*. 😊`;
              novoStatus = 'menu_principal';
              await supabase.from("atendimento_contexto").delete().eq("cliente_id", cliente.id);
            } else { resposta = `❌ Erro: ${resultado.mensagem}. Digite *0* para recomeçar.`; }
          }
        } else if (input === "2") {
          await supabase.from("atendimento_contexto").delete().eq("cliente_id", cliente.id);
          novoStatus = 'menu_principal';
          resposta = "Agendamento cancelado. Voltando ao menu...\n\n" + textoMenuPrincipal;
        } else {
          resposta = `⚠️ Opção inválida.\n\n${nEmoji(1)} - Sim, confirmar!\n${nEmoji(2)} - Não, mudar algo`;
        }
      }
    }

    if (novoStatus !== cliente.status_chat || resposta) {
      await supabase.from("clientes").update({ status_chat: novoStatus }).eq("id", cliente.id);
    }
    
    if (resposta) {
      // --- AJUSTE DE ENVIO DINÂMICO ---
      const evolutionUrl = Deno.env.get("EVOLUTION_URL")?.replace(/\/$/, ""); 
      console.log(`[Chatbot] Respondendo para ${num} via instância: ${instanciaFinal}`);

      const resEvo = await fetch(`${evolutionUrl}/message/sendText/${instanciaFinal}`, { 
        method: "POST", 
        headers: { 
          "Content-Type": "application/json", 
          "apikey": Deno.env.get("EVOLUTION_API_KEY")! 
        }, 
        body: JSON.stringify({ 
          "number": num, 
          "text": resposta 
        }) 
      });

      const resText = await resEvo.text();
      console.log(`[Evolution Response] Status: ${resEvo.status} - Body: ${resText}`);
    }

    return new Response(JSON.stringify({ ok: true }), { status: 200 });
  } catch (err) { 
    console.error("[Erro Crítico Function]:", err.message);
    return new Response(JSON.stringify({ error: err.message }), { status: 500 }); 
  }
});