import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_salao_pro/pages/agendamento_movel_page.dart';

void main() {
  group('AgendamentoMovelPage', () {
    testWidgets('Renderiza campos principais da tela', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: AgendamentoMovelPage(
          clienteId: 'cli123',
          salaoId: 'sal123',
          dataSelecionada: DateTime(2025, 10, 7),
          modoAgendamento: 'por_servico',
        ),
      ));

      // Verifica se os campos principais estão visíveis
      expect(find.text('Especialidade'), findsOneWidget);
      expect(find.text('Serviço'), findsOneWidget);
      expect(find.text('Horários disponíveis:'), findsOneWidget);
    });

    testWidgets('Exibe botão de confirmação quando horário é selecionado', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: AgendamentoMovelPage(
          clienteId: 'cli123',
          salaoId: 'sal123',
          dataSelecionada: DateTime(2025, 10, 7),
          modoAgendamento: 'por_servico',
        ),
      ));

      // Simula seleção de horário (exemplo genérico — ajuste conforme seu widget real)
      await tester.tap(find.text('10:00'));
      await tester.pump();

      expect(find.text('Confirmar Agendamento'), findsOneWidget);
    });
  });
}
