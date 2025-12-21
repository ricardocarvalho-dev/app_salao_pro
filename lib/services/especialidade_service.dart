import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/especialidade_model.dart';

class EspecialidadeService {
  final String salaoId;
  final SupabaseClient supabase = Supabase.instance.client;

  EspecialidadeService(this.salaoId);

  Future<List<EspecialidadeModel>> listar() async {
    try {
      final data = await supabase
          .from('especialidades')
          .select()
          .eq('salao_id', salaoId)
          .order('nome');

      return (data as List<dynamic>)
          .map((item) => EspecialidadeModel.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Erro ao listar especialidades: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<void> adicionar(EspecialidadeModel especialidade) async {
    try {
      await supabase.from('especialidades').insert({
        'nome': especialidade.nome,
        'salao_id': especialidade.salaoId,
      });
    } on PostgrestException catch (e) {
      throw Exception('Erro ao adicionar especialidade: ${e.message}');
    }
  }

  Future<void> atualizar(EspecialidadeModel especialidade) async {
    try {
      await supabase
          .from('especialidades')
          .update({
            'nome': especialidade.nome,
            'salao_id': especialidade.salaoId,
          })
          .eq('id', especialidade.id)
          .eq('salao_id', salaoId);
    } on PostgrestException catch (e) {
      throw Exception('Erro ao atualizar especialidade: ${e.message}');
    }
  }

  Future<void> excluir(String id) async {
    try {
      await supabase
          .from('especialidades')
          .delete()
          .eq('id', id)
          .eq('salao_id', salaoId);
    } on PostgrestException catch (e) {
      throw Exception('Erro ao excluir especialidade: ${e.message}');
    }
  }
}
