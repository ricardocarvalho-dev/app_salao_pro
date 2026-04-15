import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  try {
    const body = await req.json()

    const {
      salao_id,
      servico_id,
      data,
      profissional_id
    } = body

    // Validação básica
    if (!salao_id || !servico_id || !data) {
      return new Response(
        JSON.stringify({ erro: "Parâmetros obrigatórios ausentes." }),
        { status: 400 }
      )
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!
    )

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

    // --- LÓGICA DE FILTRO DE HORÁRIO PASSADO ---
    
    // 1. Pegamos a data e hora atual no fuso de Brasília/Salvador
    const agora = new Date();
    // Ajuste para o fuso UTC-3 manualmente para garantir precisão na Edge Function
    const agoraBR = new Date(agora.getTime() - (3 * 60 * 60 * 1000));
    
    const dataHoje = agoraBR.toISOString().split('T')[0];
    const horaAtual = agoraBR.toISOString().split('T')[1].slice(0, 5); // Ex: "14:31"

    // 2. Formatamos e Filtramos se a data for hoje
    const slotsFormatados = (slots ?? [])
      .map((s: any) => s.horario?.slice(0, 5)) // Formata para HH:mm
      .filter((horarioSlot: string) => {
        // Se a data solicitada for hoje, o horário do slot deve ser maior que a hora atual
        if (data === dataHoje) {
          return horarioSlot > horaAtual;
        }
        // Se for outra data (amanhã, etc), mostra todos os slots
        return true;
      })
      .map(h => ({ horario: h })); // Retorna no formato de objeto esperado

    return new Response(
      JSON.stringify(slotsFormatados),
      { status: 200 }
    )

  } catch (err) {
    console.error("Erro listar_slots_publicos:", err)
    return new Response(
      JSON.stringify({ erro: "Erro ao buscar horários." }),
      { status: 500 }
    )
  }
})