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
        .order('nome')
        .execute();

    final data = response.data as List;
    return data.map((item) => ClienteModel.fromMap(item)).toList();
  }

  Future<void> adicionar(ClienteModel cliente) async {
    _validarCliente(cliente);
    await _verificarDuplicidade(cliente: cliente, isAtualizacao: false);

    await supabase.from('clientes').insert({
      'nome': cliente.nome,
      'celular': cliente.celular,
      'email': cliente.email.isNotEmpty ? cliente.email : null,
      'salao_id': cliente.salaoId,
    }).execute();
  }

  Future<void> atualizar(ClienteModel cliente) async {
    _validarCliente(cliente);
    await _verificarDuplicidade(cliente: cliente, isAtualizacao: true);

    await supabase.from('clientes').update({
      'nome': cliente.nome,
      'celular': cliente.celular,
      'email': cliente.email.isNotEmpty ? cliente.email : null,
    }).eq('id', cliente.id).execute();
  }

  Future<void> excluir(String id) async {
    await supabase.from('clientes').delete().eq('id', id).execute();
  }

  void _validarCliente(ClienteModel cliente) {
    if (cliente.nome.trim().isEmpty) {
      throw Exception('Nome é obrigatório');
    }
    if (cliente.celular.trim().isEmpty) {
      throw Exception('Celular é obrigatório');
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
    // Verificar celular duplicado
    final celularResponse = await supabase
        .from('clientes')
        .select('id')
        .eq('salao_id', cliente.salaoId)
        .eq('celular', cliente.celular)
        .execute();

    final celularData = celularResponse.data as List;

    if (isAtualizacao) {
      if (celularData.any((item) => item['id'] != cliente.id)) {
        throw Exception('Já existe um cliente com este celular');
      }
    } else {
      if (celularData.isNotEmpty) {
        throw Exception('Já existe um cliente com este celular');
      }
    }

    // Verificar e-mail duplicado (se houver)
    if (cliente.email.isNotEmpty) {
      final emailResponse = await supabase
          .from('clientes')
          .select('id')
          .eq('salao_id', cliente.salaoId)
          .eq('email', cliente.email)
          .execute();

      final emailData = emailResponse.data as List;

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
}
