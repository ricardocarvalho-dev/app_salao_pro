import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

Deno.serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response(
        JSON.stringify({ error: "Método não permitido" }),
        { status: 405 }
      )
    }

    const { salao_id, profissional_id } = await req.json()

    if (!salao_id) {
      return new Response(
        JSON.stringify({ error: "salao_id é obrigatório." }),
        { status: 400 }
      )
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    )

    // 🔹 Se NÃO escolher profissional → lista todos serviços ativos do salão
    if (!profissional_id) {
      const { data, error } = await supabase
        .from("servicos")
        .select("id, nome")
        .eq("salao_id", salao_id)
        .eq("ativo", true)
        .order("nome", { ascending: true })

      if (error) throw error

      return new Response(JSON.stringify(data ?? []), { status: 200 })
    }

    // 🔒 Verifica se o profissional pertence ao salão
    const { data: profissionalExiste, error: erroProf } = await supabase
      .from("profissionais")
      .select("id")
      .eq("id", profissional_id)
      .eq("salao_id", salao_id)
      .single()

    if (erroProf || !profissionalExiste) {
      return new Response(JSON.stringify([]), { status: 200 })
    }

    // 1️⃣ Buscar especialidades do profissional
    const { data: especialidades, error: erroEsp } = await supabase
      .from("profissional_especialidades")
      .select("especialidade_id")
      .eq("profissional_id", profissional_id)

    if (erroEsp) throw erroEsp

    const especialidadeIds = [
      ...new Set(especialidades?.map(e => e.especialidade_id) ?? [])
    ]

    if (especialidadeIds.length === 0) {
      return new Response(JSON.stringify([]), { status: 200 })
    }

    // 2️⃣ Buscar serviços ativos dessas especialidades
    const { data: servicos, error: erroServ } = await supabase
      .from("servicos")
      .select("id, nome")
      .eq("salao_id", salao_id)
      .eq("ativo", true)
      .in("especialidade_id", especialidadeIds)
      .order("nome", { ascending: true })

    if (erroServ) throw erroServ

    return new Response(JSON.stringify(servicos ?? []), { status: 200 })

  } catch (error: any) {
    console.error("Erro listar_servicos_publicos:", error)

    return new Response(
      JSON.stringify({ error: "Erro interno ao buscar serviços." }),
      { status: 500 }
    )
  }
})