import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profissional_model.dart';

class ProfissionalService {
  final supabase = Supabase.instance.client;

  Future<List<ProfissionalModel>> listarPorSalao(String salaoId) async {
    final response = await supabase
        .from('profissionais')
        .select('id, nome, modo_agendamento, celular') // 1. Adicionado celular no select
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
        celular: map['celular'].toString(), // 2. Adicionado celular no retorno
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
        .select('id, nome, salao_id, modo_agendamento, celular') // 3. Adicionado celular aqui
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
      celular: response['celular'].toString(), // 4. Adicionado celular aqui
      modoAgendamento: response['modo_agendamento'].toString(),
      especialidadeIds: especs.map((e) => e['especialidade_id'].toString()).toList(),
      nomesEspecialidades: especs
          .map((e) => (e['especialidades']?['nome'] ?? '').toString())
          .where((nome) => nome.isNotEmpty)
          .toList(),
    );
  }

  Future<void> adicionar(ProfissionalModel profissional) async {
    _validarProfissional(profissional);
    final inserted = await supabase.from('profissionais').insert({
      'nome': profissional.nome,
      'salao_id': profissional.salaoId,
      'modo_agendamento': profissional.modoAgendamento,
      'celular': profissional.celular, // 5. Gravando o celular no banco
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
    _validarProfissional(profissional);
    await supabase.from('profissionais').update({
      'nome': profissional.nome,
      'modo_agendamento': profissional.modoAgendamento,
      'celular': profissional.celular, // 6. Atualizando o celular no banco
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

  bool _celularValido(String celular) {
    // Remove tudo que não é número
    final numeros = celular.replaceAll(RegExp(r'\D'), '');
    
    // Agora aceitamos:
    // 11 dígitos: Padrão nacional (ex: 71991147042)
    // 13 dígitos: Padrão internacional (ex: 5571991147042)
    return numeros.length == 11 || numeros.length == 13;
  }  

  // ===============================
  // VALIDACOES
  // ===============================
  void _validarProfissional(ProfissionalModel profissional) {
    if (profissional.nome.trim().isEmpty) {
      throw Exception('Nome é obrigatório');
    }
    if (!_celularValido(profissional.celular)) {
      throw Exception('Celular inválido. Informe DDD + número');
    }
    if (profissional.celular.trim().isEmpty) {
      throw Exception('Celular é obrigatório');
    }
    if (profissional.salaoId.trim().isEmpty) {
      throw Exception('Salão é obrigatório');
    }

  }  

}