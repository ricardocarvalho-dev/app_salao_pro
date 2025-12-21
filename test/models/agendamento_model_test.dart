import 'package:flutter_test/flutter_test.dart';
import 'package:app_salao_pro/models/agendamento_model.dart';

void main() {
  group('AgendamentoModel.fromMapSafe', () {
    test('Retorna objeto válido com dados completos', () {
      final map = {
        'id': 'abc123',
        'data_hora': '2025-09-16T15:00:00.000Z',
        'profissional_id': 'prof1',
        'servico_id': 'serv1',
        'cliente_id': 'cli1',
        'salao_id': 'salao1',
      };

      final agendamento = AgendamentoModel.fromMapSafe(map);

      expect(agendamento, isNotNull);
      expect(agendamento!.id, equals('abc123'));
      expect(agendamento.profissionalId, equals('prof1'));
      expect(agendamento.dataHora.isUtc, isFalse); // convertido para local
    });

    test('Retorna null com campos vazios', () {
      final map = {
        'id': '',
        'data_hora': '',
        'profissional_id': '',
        'servico_id': '',
        'cliente_id': '',
        'salao_id': '',
      };

      final agendamento = AgendamentoModel.fromMapSafe(map);

      expect(agendamento, isNull);
    });

    test('Retorna null com data inválida', () {
      final map = {
        'id': 'abc123',
        'data_hora': 'data inválida',
        'profissional_id': 'prof1',
        'servico_id': 'serv1',
        'cliente_id': 'cli1',
        'salao_id': 'salao1',
      };

      final agendamento = AgendamentoModel.fromMapSafe(map);

      expect(agendamento, isNull);
    });

    test('Retorna null com campo ausente', () {
      final map = {
        'id': 'abc123',
        'data_hora': '2025-09-16T15:00:00.000Z',
        // faltando profissional_id
        'servico_id': 'serv1',
        'cliente_id': 'cli1',
        'salao_id': 'salao1',
      };

      final agendamento = AgendamentoModel.fromMapSafe(map);

      expect(agendamento, isNull);
    });

    test('Aceita data local sem UTC e converte corretamente', () {
      final map = {
        'id': 'abc123',
        'data_hora': '2025-09-16T15:00:00',
        'profissional_id': 'prof1',
        'servico_id': 'serv1',
        'cliente_id': 'cli1',
        'salao_id': 'salao1',
      };

      final agendamento = AgendamentoModel.fromMapSafe(map);

      expect(agendamento, isNotNull);
      expect(agendamento!.dataHora.hour, 15);
    });
  });

  group('AgendamentoModel.toMap', () {
    test('Converte AgendamentoModel para Map corretamente', () {
      final agendamento = AgendamentoModel(
        id: 'abc123',
        dataHora: DateTime(2025, 9, 16, 15, 0),
        profissionalId: 'prof1',
        servicoId: 'serv1',
        clienteId: 'cli1',
        salaoId: 'salao1',
        status: 'pendente',
        createdAt: DateTime(2025, 9, 10, 12, 0),
      );

      final map = agendamento.toMap();

      expect(map['id'], 'abc123');
      expect(map['data_hora'], isNotNull);
      expect(map['profissional_id'], 'prof1');
      expect(map['status'], 'pendente');
    });
  });
}
