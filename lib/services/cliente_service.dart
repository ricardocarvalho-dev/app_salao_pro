import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cliente_model.dart';

class ClienteService {
  final SupabaseClient supabase = Supabase.instance.client;

  final _emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");

  Future<List<ClienteModel>> listarPorSalao(String salaoId) async {
    final response = await supabase
        .from('clientes')
        .select()
        .eq('salao_id', salaoId)
        .order('nome');

    final data = response as List;
    return data.map((item) => ClienteModel.fromMap(item)).toList();
  }

  /// ===============================
  /// ADICIONAR (SEM RETORNO – já existia)
  /// ===============================
  Future<void> adicionar(ClienteModel cliente) async {
    _validarCliente(cliente);
    await _verificarDuplicidade(cliente: cliente, isAtualizacao: false);

    await supabase.from('clientes').insert({
      'nome': cliente.nome,
      'celular': cliente.celular,
      'email': cliente.email.isNotEmpty ? cliente.email : null,
      'salao_id': cliente.salaoId,
    });
  }

  /// ===============================
  /// ✅ ADICIONAR RETORNANDO ID (NOVO)
  /// ===============================
  Future<String> adicionarRetornandoId(ClienteModel cliente) async {
    _validarCliente(cliente);
    await _verificarDuplicidade(cliente: cliente, isAtualizacao: false);

    final response = await supabase
        .from('clientes')
        .insert({
          'nome': cliente.nome,
          'celular': cliente.celular,
          'email': cliente.email.isNotEmpty ? cliente.email : null,
          'salao_id': cliente.salaoId,
        })
        .select('id')
        .single();

    return response['id'].toString();
  }

  Future<void> atualizar(ClienteModel cliente) async {
    _validarCliente(cliente);
    await _verificarDuplicidade(cliente: cliente, isAtualizacao: true);

    await supabase.from('clientes').update({
      'nome': cliente.nome,
      'celular': cliente.celular,
      'email': cliente.email.isNotEmpty ? cliente.email : null,
    }).eq('id', cliente.id);
  }

  Future<void> excluir(String id) async {
    await supabase.from('clientes').delete().eq('id', id);
  }

  // ===============================
  // VALIDACOES
  // ===============================
  void _validarCliente(ClienteModel cliente) {
    if (cliente.nome.trim().isEmpty) {
      throw Exception('Nome é obrigatório');
    }
    if (cliente.celular.trim().isEmpty) {
      throw Exception('Celular é obrigatório');
    }
    if (!_celularValido(cliente.celular)) {
      throw Exception('Celular inválido. Informe DDD + número');
    }    
    if (cliente.email.isNotEmpty && !_emailRegex.hasMatch(cliente.email)) {
      throw Exception('E-mail inválido');
    }
    if (cliente.salaoId.trim().isEmpty) {
      throw Exception('Salão é obrigatório');
    }
  }

  Future<void> _verificarDuplicidade({
    required ClienteModel cliente,
    required bool isAtualizacao,
  }) async {
    final celularResponse = await supabase
        .from('clientes')
        .select('id')
        .eq('salao_id', cliente.salaoId)
        .eq('celular', cliente.celular);

    final celularData = celularResponse as List;

    if (isAtualizacao) {
      if (celularData.any((item) => item['id'] != cliente.id)) {
        throw Exception('Já existe um cliente com este celular');
      }
    } else {
      if (celularData.isNotEmpty) {
        throw Exception('Já existe um cliente com este celular');
      }
    }

    if (cliente.email.isNotEmpty) {
      final emailResponse = await supabase
          .from('clientes')
          .select('id')
          .eq('salao_id', cliente.salaoId)
          .eq('email', cliente.email);

      final emailData = emailResponse as List;

      if (isAtualizacao) {
        if (emailData.any((item) => item['id'] != cliente.id)) {
          throw Exception('Já existe um cliente com este e-mail');
        }
      } else {
        if (emailData.isNotEmpty) {
          throw Exception('Já existe um cliente com este e-mail');
        }
      }
    }
  }

  bool _celularValido(String celular) {
    final numeros = celular.replaceAll(RegExp(r'\D'), '');
    return numeros.length == 11;
  }

}
