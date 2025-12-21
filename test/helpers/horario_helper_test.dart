import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

Future<List<Map<String, dynamic>>> gerarHorariosFake({
  required DateTime data,
  required int duracaoMinutos,
  required String horaInicio,
  required String horaFim,
  required List<String> horariosOcupados,
}) async {
  final inicioParts = horaInicio.split(':').map(int.parse).toList();
  final fimParts = horaFim.split(':').map(int.parse).toList();

  final inicio = TimeOfDay(hour: inicioParts[0], minute: inicioParts[1]);
  final fim = TimeOfDay(hour: fimParts[0], minute: fimParts[1]);

  final List<Map<String, dynamic>> horarios = [];
  var horaAtual = DateTime(data.year, data.month, data.day, inicio.hour, inicio.minute);
  final fimDateTime = DateTime(data.year, data.month, data.day, fim.hour, fim.minute);

  while (horaAtual.add(Duration(minutes: duracaoMinutos)).isBefore(fimDateTime) ||
      horaAtual.add(Duration(minutes: duracaoMinutos)).isAtSameMomentAs(fimDateTime)) {
    final horaStr = '${horaAtual.hour.toString().padLeft(2, '0')}:${horaAtual.minute.toString().padLeft(2, '0')}';
    final ocupado = horariosOcupados.contains(horaStr);

    horarios.add({
      'hora': horaStr,
      'ocupado': ocupado,
    });

    horaAtual = horaAtual.add(Duration(minutes: duracaoMinutos));
  }

  return horarios;
}

void main() {
  group('gerarHorariosFake', () {
    test('gera horários corretamente com duração e faixa', () async {
      final data = DateTime(2025, 10, 7);
      final horarios = await gerarHorariosFake(
        data: data,
        duracaoMinutos: 30,
        horaInicio: '09:00',
        horaFim: '12:00',
        horariosOcupados: [],
      );

      expect(horarios.length, 6); // 09:00, 09:30, ..., 11:30
      expect(horarios.first['hora'], '09:00');
      expect(horarios.last['hora'], '11:30');
      expect(horarios.every((h) => h['ocupado'] == false), true);
    });

    test('marca horários como ocupados corretamente', () async {
      final data = DateTime(2025, 10, 7);
      final horarios = await gerarHorariosFake(
        data: data,
        duracaoMinutos: 30,
        horaInicio: '09:00',
        horaFim: '12:00',
        horariosOcupados: ['10:00', '11:00'],
      );

      final h10 = horarios.firstWhere((h) => h['hora'] == '10:00');
      final h11 = horarios.firstWhere((h) => h['hora'] == '11:00');

      expect(h10['ocupado'], true);
      expect(h11['ocupado'], true);
    });

    test('não gera horários se duração não cabe na faixa', () async {
      final data = DateTime(2025, 10, 7);
      final horarios = await gerarHorariosFake(
        data: data,
        duracaoMinutos: 60,
        horaInicio: '11:30',
        horaFim: '12:00',
        horariosOcupados: [],
      );

      expect(horarios.isEmpty, true);
    });

    test('gera horário que termina exatamente no limite da faixa', () async {
      final data = DateTime(2025, 10, 7);
      final horarios = await gerarHorariosFake(
        data: data,
        duracaoMinutos: 30,
        horaInicio: '11:30',
        horaFim: '12:00',
        horariosOcupados: [],
      );

      expect(horarios.length, 1);
      expect(horarios.first['hora'], '11:30');
    });

    test('gera horários com faixa iniciando em minutos quebrados', () async {
      final data = DateTime(2025, 10, 7);
      final horarios = await gerarHorariosFake(
        data: data,
        duracaoMinutos: 30,
        horaInicio: '09:15',
        horaFim: '10:45',
        horariosOcupados: [],
      );

      expect(horarios.map((h) => h['hora']), ['09:15', '09:45', '10:15']);
    });
  });
}
