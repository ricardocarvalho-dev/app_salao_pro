import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Trata requisições de preflight do CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { cliente_id } = await req.json()

    if (!cliente_id) {
      return new Response(JSON.stringify({ erro: "cliente_id obrigatório" }), { 
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      })
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    )

    // Chama a RPC que você acabou de criar no banco
    const { data, error } = await supabase.rpc('listar_meus_agendamentos', {
      p_cliente_id: cliente_id
    })

    if (error) throw error

    return new Response(JSON.stringify(data), { 
      status: 200, 
      headers: { ...corsHeaders, "Content-Type": "application/json" } 
    })

  } catch (err) {
    return new Response(JSON.stringify({ erro: err.message }), { 
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" }
    })
  }
})