import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/servico_model.dart';

class ServicoService {
  final String salaoId;
  final SupabaseClient _client = Supabase.instance.client;

  ServicoService(this.salaoId);

  Future<List<ServicoModel>> listar() async {
    final data = await _client
        .from('servicos')
        .select('id, nome, preco, duracao_minutos, salao_id, especialidade_id, especialidades (nome)')
        .eq('salao_id', salaoId)
        .order('nome', ascending: true);
    
    print('📦 Dados recebidos: $data');
    return (data as List).map((item) => ServicoModel.fromMap(item)).toList();
  }

  Future<void> adicionar(ServicoModel servico) async {
    await _client.from('servicos').insert({
      'nome': servico.nome,
      'preco': servico.preco,
      'duracao_minutos': servico.duracaoMinutos,
      'salao_id': salaoId,
      'especialidade_id': servico.especialidadeId,
    });
  }

  Future<void> atualizar(ServicoModel servico) async {
    await _client
        .from('servicos')
        .update({
          'nome': servico.nome,
          'preco': servico.preco,
          'duracao_minutos': servico.duracaoMinutos,
          'especialidade_id': servico.especialidadeId,
        })
        .eq('id', servico.id)
        .eq('salao_id', salaoId);
  }

  Future<void> excluir(String id) async {
    final agendamentos = await _client
        .from('agendamentos')
        .select('id')
        .eq('servico_id', id)
        .limit(1);

    if (agendamentos != null && agendamentos.isNotEmpty) {
      throw Exception('Este serviço possui agendamentos e não pode ser excluído.');
    }

    await _client
        .from('servicos')
        .delete()
        .eq('id', id)
        .eq('salao_id', salaoId);
  }

  Future<ServicoModel?> buscarPorId(String id) async {
    /*
    final data = await _client
        .from('servicos')
        .select('id, nome, preco, duracao_minutos, salao_id, especialidade_id')
        .eq('id', id)
        .eq('salao_id', salaoId)
        .maybeSingle();
    */
    final data = await _client
      .from('servicos')
      .select('id, nome, preco, duracao_minutos, salao_id, especialidade_id, especialidade (nome)')
      .eq('id', id)
      .eq('salao_id', salaoId)
      .maybeSingle();

    if (data == null) return null;
    return ServicoModel.fromMap(data);
  }
}
