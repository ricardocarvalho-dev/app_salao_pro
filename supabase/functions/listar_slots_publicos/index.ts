import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  try {
    const body = await req.json()
    const { salao_id, servico_id, data, profissional_id } = body

    if (!salao_id || !servico_id || !data) {
      return new Response(JSON.stringify({ erro: "Parâmetros obrigatórios." }), { status: 400 })
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")! // Use Service Role para garantir leitura
    )

    // --- 🛑 NOVO: VALIDAÇÃO DE BLOQUEIO (AGENDA_CONFIG) ---
    const { data: config, error: configError } = await supabase
      .from("agenda_config")
      .select("trabalha")
      .eq("salao_id", salao_id)
      .eq("data", data)
      .maybeSingle();

    // Se existir registro e trabalha for false, retorna lista vazia IMEDIATAMENTE
    if (config && config.trabalha === false) {
      return new Response(JSON.stringify([]), { status: 200 })
    }

    // --- SEGUIR COM A BUSCA NORMAL ---
    let query = supabase
      .from("horarios_disponiveis")
      .select("horario")
      .eq("salao_id", salao_id)
      .eq("servico_id", servico_id)
      .eq("data", data)
      .eq("status", "ativo")
      .eq("ocupado", false)
      .order("horario", { ascending: true })

    if (profissional_id) {
      query = query.eq("profissional_id", profissional_id)
    } else {
      query = query.is("profissional_id", null)
    }

    const { data: slots, error } = await query
    if (error) throw error

    // --- LÓGICA DE FILTRO DE HORÁRIO PASSADO (BRASÍLIA) ---
    const agora = new Date();
    const agoraBR = new Date(agora.getTime() - (3 * 60 * 60 * 1000));
    const dataHoje = agoraBR.toISOString().split('T')[0];
    const horaAtual = agoraBR.toISOString().split('T')[1].slice(0, 5);

    const slotsFormatados = (slots ?? [])
      .map((s: any) => s.horario?.slice(0, 5))
      .filter((horarioSlot: string) => {
        if (data === dataHoje) {
          return horarioSlot > horaAtual;
        }
        return true;
      })
      .map(h => ({ horario: h }));

    return new Response(JSON.stringify(slotsFormatados), { status: 200 })

  } catch (err) {
    console.error("Erro listar_slots_publicos:", err)
    return new Response(JSON.stringify({ erro: "Erro ao buscar horários." }), { status: 500 })
  }
})