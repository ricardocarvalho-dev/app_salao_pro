// supabase/functions/chatbot-agenda/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const { celular, salao_id } = await req.json();
    const celularLimpo = celular.split('@')[0].replace(/\D/g, ''); 

    // 1. Identificar o cliente
    const { data: cliente } = await supabase
      .from('clientes')
      .select('id, nome')
      .eq('celular', celularLimpo)
      .eq('salao_id', salao_id)
      .maybeSingle();

    const nomeTratado = cliente ? cliente.nome.split(' ')[0] : "amigo(a)";

    // 2. Buscar Horários
    const hoje = new Date().toISOString().split('T')[0];
    const { data: horarios, error: errorHorarios } = await supabase
      .from('horarios_disponiveis')
      .select('data, horario')
      .eq('salao_id', salao_id)
      .eq('ocupado', false)
      .eq('status', 'ativo')
      .gte('data', hoje)
      .order('data', { ascending: true })
      .order('horario', { ascending: true })
      .limit(8);

    if (errorHorarios) throw errorHorarios;

    // 3. Retorno para o Typebot (Aqui está a mudança!)
    return new Response(
      JSON.stringify({
        success: true,
        nome_cliente: nomeTratado,
        // Enviamos a lista pura para os botões dinâmicos
        lista_horarios: horarios 
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    );

  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: error.message }), 
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    );
  }
});