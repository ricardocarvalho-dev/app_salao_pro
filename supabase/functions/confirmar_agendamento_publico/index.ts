import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  try {
    const body = await req.json()

    const {
      salao_id,
      servico_id,
      cliente_id,
      data,
      hora,
      profissional_id
    } = body

    if (!salao_id || !servico_id || !cliente_id || !data || !hora) {
      return new Response(
        JSON.stringify({ erro: "Parâmetros obrigatórios ausentes." }),
        { status: 400 }
      )
    }

    // 🔒 Validação de data
    const hoje = new Date()
    hoje.setHours(0, 0, 0, 0)

    const dataSolicitada = new Date(data + "T00:00:00")

    if (dataSolicitada < hoje) {
      return new Response(
        JSON.stringify({ erro: "Não é permitido agendar datas passadas." }),
        { status: 400 }
      )
    }

    const limite = new Date()
    limite.setDate(limite.getDate() + 30)

    if (dataSolicitada > limite) {
      return new Response(
        JSON.stringify({ erro: "Data fora da janela permitida para agendamento." }),
        { status: 400 }
      )
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    )

    const { error } = await supabase.rpc(
      "criar_agendamento_grade",
      {
        p_salao_id: salao_id,
        p_servico_id: servico_id,
        p_cliente_id: cliente_id,
        p_data: data,
        p_hora: hora,
        p_status: "pendente",
        p_profissional_id: profissional_id ?? null
      }
    )

    if (error) {
      if (error.code === "23505") {
        return new Response(
          JSON.stringify({
            sucesso: false,
            mensagem: "Esse horário acabou de ser ocupado. Escolha outro horário."
          }),
          { status: 409 }
        )
      }

      console.error("Erro RPC criar_agendamento_grade:", error)
      throw error
    }

    return new Response(
      JSON.stringify({
        sucesso: true,
        mensagem: "Agendamento confirmado com sucesso!"
      }),
      { status: 200 }
    )

  } catch (err) {
    console.error("Erro confirmar_agendamento_publico:", err)

    return new Response(
      JSON.stringify({ erro: "Erro interno ao confirmar agendamento." }),
      { status: 500 }
    )
  }
})