import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profissional_model.dart';

class ProfissionalService {
  final supabase = Supabase.instance.client;

  Future<List<ProfissionalModel>> listarPorSalao(String salaoId) async {
    final data = await supabase
        .from('profissionais')
        .select()
        .eq('salao_id', salaoId)
        .order('nome');

    return (data as List).map((item) => ProfissionalModel.fromMap(item)).toList();
  }

  Future<void> adicionar(ProfissionalModel profissional) async {
    if (profissional.nome.isEmpty || profissional.especialidadeId.isEmpty || profissional.salaoId.isEmpty) {
      throw Exception('Dados do profissional incompletos');
    }

    await supabase.from('profissionais').insert({
      'nome': profissional.nome,
      'especialidade_id': profissional.especialidadeId,
      'salao_id': profissional.salaoId,
    });
  }

  Future<void> atualizar(ProfissionalModel profissional) async {
    await supabase.from('profissionais').update({
      'nome': profissional.nome,
      'especialidade_id': profissional.especialidadeId,
    }).eq('id', profissional.id);
  }

  Future<void> excluir(String id) async {
    await supabase.from('profissionais').delete().eq('id', id);
  }
}
