import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  try {
    const { 
      salao_id, 
      servico_id, 
      profissional_id, 
      data, 
      horario_selecionado, 
      cliente_id 
    } = await req.json()

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 1. VALIDAÇÃO D+30 (SEGURANÇA LADO SERVIDOR)
    const hoje = new Date()
    const limiteD30 = new Date()
    limiteD30.setDate(hoje.getDate() + 30)
    const dataAlvo = new Date(data)

    if (dataAlvo > limiteD30) {
      return new Response(JSON.stringify({ error: "Data fora do limite de 30 dias. Por favor, escolha uma data dentro do prazo." }), { status: 400 })
    }

    // 2. INSERIR O AGENDAMENTO DEFINITIVO
    const { data: agendamento, error: erroAgenda } = await supabase
      .from('agendamentos')
      .insert([{
        salao_id,
        cliente_id,
        servico_id,
        profissional_id: profissional_id || null,
        data,
        hora: horario_selecionado,
        status: 'confirmado' 
      }])
      .select()
      .single()

    if (erroAgenda) throw erroAgenda

    // 3. MARCAR COMO OCUPADO NA TABELA DE HORÁRIOS (SLOTS)
    // Como a data já passou pela validação D+30, atualizamos o status
    const { error: erroUpdate } = await supabase
      .from('horarios_disponiveis')
      .update({ ocupado: true })
      .match({
        salao_id,
        data,
        horario: horario_selecionado,
        profissional_id: profissional_id || null
      })

    if (erroUpdate) console.error("Aviso: Falha ao marcar slot como ocupado:", erroUpdate)

    return new Response(JSON.stringify({ 
      success: true, 
      agendamento_id: agendamento.id 
    }), { headers: { "Content-Type": "application/json" } })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { 
      status: 400,
      headers: { "Content-Type": "application/json" }
    })
  }
})