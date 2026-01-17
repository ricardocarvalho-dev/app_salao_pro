import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profissional_model.dart';

class ProfissionalService {
  final supabase = Supabase.instance.client;

  Future<List<ProfissionalModel>> listarPorSalao(String salaoId) async {
    final response = await supabase
        .from('profissionais')
        .select('id, nome, modo_agendamento')
        .eq('salao_id', salaoId)
        .order('nome');

    final lista = List<Map<String, dynamic>>.from(response);

    return Future.wait(lista.map((map) async {
      final especsResponse = await supabase
          .from('profissional_especialidades')
          .select('especialidade_id, especialidades(nome)')
          .eq('profissional_id', map['id']);

      final especs = List<Map<String, dynamic>>.from(especsResponse);

      return ProfissionalModel(
        id: map['id'].toString(),
        nome: map['nome'].toString(),
        salaoId: salaoId,
        modoAgendamento: map['modo_agendamento'].toString(),
        especialidadeIds: especs.map((e) => e['especialidade_id'].toString()).toList(),
        nomesEspecialidades: especs
            .map((e) => (e['especialidades']?['nome'] ?? '').toString())
            .where((nome) => nome.isNotEmpty)
            .toList(),
      );
    }).toList());
  }

  Future<ProfissionalModel> buscarPorId(String profissionalId) async {
    final response = await supabase
        .from('profissionais')
        .select('id, nome, salao_id, modo_agendamento')
        .eq('id', profissionalId)
        .single();

    final especsResponse = await supabase
        .from('profissional_especialidades')
        .select('especialidade_id, especialidades(nome)')
        .eq('profissional_id', profissionalId);

    final especs = List<Map<String, dynamic>>.from(especsResponse);

    return ProfissionalModel(
      id: response['id'].toString(),
      nome: response['nome'].toString(),
      salaoId: response['salao_id'].toString(),
      modoAgendamento: response['modo_agendamento'].toString(),
      especialidadeIds: especs.map((e) => e['especialidade_id'].toString()).toList(),
      nomesEspecialidades: especs
          .map((e) => (e['especialidades']?['nome'] ?? '').toString())
          .where((nome) => nome.isNotEmpty)
          .toList(),
    );
  }

  Future<void> adicionar(ProfissionalModel profissional) async {
    final inserted = await supabase.from('profissionais').insert({
      'nome': profissional.nome,
      'salao_id': profissional.salaoId,
      'modo_agendamento': profissional.modoAgendamento,
    }).select().single();

    final profissionalId = inserted['id'].toString();

    for (final espId in profissional.especialidadeIds) {
      await supabase.from('profissional_especialidades').insert({
        'profissional_id': profissionalId,
        'especialidade_id': espId,
      });
    }
  }

  Future<void> atualizar(ProfissionalModel profissional) async {
    await supabase.from('profissionais').update({
      'nome': profissional.nome,
      'modo_agendamento': profissional.modoAgendamento,
    }).eq('id', profissional.id);

    await supabase.from('profissional_especialidades').delete().eq('profissional_id', profissional.id);

    for (final espId in profissional.especialidadeIds) {
      await supabase.from('profissional_especialidades').insert({
        'profissional_id': profissional.id,
        'especialidade_id': espId,
      });
    }
  }

  Future<void> excluir(String profissionalId) async {
    await supabase.from('profissional_especialidades').delete().eq('profissional_id', profissionalId);
    await supabase.from('profissionais').delete().eq('id', profissionalId);
  }
}