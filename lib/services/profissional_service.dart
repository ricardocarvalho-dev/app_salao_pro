import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profissional_model.dart';

class ProfissionalService {
  final supabase = Supabase.instance.client;

  /// Lista todos os profissionais de um salão com suas especialidades
  Future<List<ProfissionalModel>> listarPorSalao(String salaoId) async {
    // Busca profissionais
    final data = await supabase
        .from('profissionais')
        .select()
        .eq('salao_id', salaoId)
        .order('nome');

    final profissionais = (data as List<dynamic>)
        .map((item) => ProfissionalModel.fromMap(item as Map<String, dynamic>))
        .toList();

    // Para cada profissional, buscar especialidades vinculadas
    for (var prof in profissionais) {
      final especs = await supabase
          .from('profissional_especialidades')
          .select('especialidade_id, especialidades(nome)')
          .eq('profissional_id', prof.id);

      final especList = (especs as List<dynamic>);

      // Converte IDs e nomes explicitamente para String
      final especIds = especList
          .map((e) => (e['especialidade_id'] as dynamic).toString())
          .toList();

      final especNomes = especList
          .map((e) => (e['especialidades']?['nome'] as dynamic).toString())
          .toList();

      prof.especialidadeIds = especIds;
      prof.nomesEspecialidades = especNomes;
    }

    return profissionais;
  }

  /// Adiciona um novo profissional com suas especialidades
  Future<void> adicionar(ProfissionalModel profissional) async {
    if (profissional.nome.isEmpty || profissional.salaoId.isEmpty) {
      throw Exception('Dados do profissional incompletos');
    }

    // Insere o profissional
    final inserted = await supabase.from('profissionais').insert({
      'nome': profissional.nome,
      'salao_id': profissional.salaoId,
      'modo_agendamento': profissional.modoAgendamento,
    }).select().single();

    final profissionalId = (inserted['id'] as dynamic).toString();

    // Insere vínculos de especialidades
    for (final especId in profissional.especialidadeIds) {
      await supabase.from('profissional_especialidades').insert({
        'profissional_id': profissionalId,
        'especialidade_id': especId,
      });
    }
  }

  /// Atualiza dados do profissional e suas especialidades
  Future<void> atualizar(ProfissionalModel profissional) async {
    await supabase.from('profissionais').update({
      'nome': profissional.nome,
      'modo_agendamento': profissional.modoAgendamento,
    }).eq('id', profissional.id);

    // Remove vínculos antigos
    await supabase
        .from('profissional_especialidades')
        .delete()
        .eq('profissional_id', profissional.id);

    // Insere vínculos novos
    for (final especId in profissional.especialidadeIds) {
      await supabase.from('profissional_especialidades').insert({
        'profissional_id': profissional.id,
        'especialidade_id': especId,
      });
    }
  }

  /// Exclui profissional e vínculos
  Future<void> excluir(String id) async {
    await supabase.from('profissionais').delete().eq('id', id);
    await supabase.from('profissional_especialidades').delete().eq('profissional_id', id);
  }
}
