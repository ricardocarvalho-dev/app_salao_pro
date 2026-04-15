// Edge Function: listar_profissionais_publicos

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

    const { salao_id } = await req.json()

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

    const { data, error } = await supabase
      .from("profissionais")
      .select("id, nome")
      .eq("salao_id", salao_id)
      .eq("modo_agendamento", "por_profissional")
      .order("nome", { ascending: true })

    if (error) throw error

    return new Response(
      JSON.stringify(data ?? []),
      { status: 200 }
    )

  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500 }
    )
  }
})