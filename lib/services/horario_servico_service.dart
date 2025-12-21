import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/horario_servico_model.dart';

class HorarioServicoService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<HorarioServicoModel>> listarPorServico(String servicoId) async {
    final data = await _client
        .from('horarios_servicos')
        .select()
        .eq('servico_id', servicoId)
        .order('dia_semana')
        .order('horario_inicio');

    return (data as List).map((e) => HorarioServicoModel.fromMap(e)).toList();
  }

  Future<void> adicionar(HorarioServicoModel horario) async {
    await _client.from('horarios_servicos').insert({
      'servico_id': horario.servicoId,
      'dia_semana': horario.diaSemana,
      'horario_inicio': horario.horarioInicio,
      'horario_fim': horario.horarioFim,
      'ativo': horario.ativo,
    });
  }

  Future<void> excluir(String id) async {
    await _client.from('horarios_servicos').delete().eq('id', id);
  }

  Future<void> atualizarStatus(String id, bool ativo) async {
    await _client.from('horarios_servicos').update({'ativo': ativo}).eq('id', id);
  }

  Future<void> atualizar(HorarioServicoModel horario) async {
    await _client.from('horarios_servicos').update({
      'dia_semana': horario.diaSemana,
      'horario_inicio': horario.horarioInicio,
      'horario_fim': horario.horarioFim,
      'ativo': horario.ativo,
    }).eq('id', horario.id);
  }

}
