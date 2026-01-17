import 'package:flutter/material.dart';
import '../providers/agendamento_provider.dart'; // para usar HorarioSlot

class HorariosSeguro extends StatelessWidget {
  final List<HorarioSlot> horarios;          // agora tipado corretamente
  final String? selecionado;
  final bool carregando;
  final bool buscaIniciada;
  final void Function(String?) onSelecionar;
  final dynamic theme; // mesmo hTheme que você já usa

  const HorariosSeguro({
    super.key,
    required this.horarios,
    required this.selecionado,
    required this.onSelecionar,
    required this.carregando,
    required this.buscaIniciada,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // 🔒 valida seleção
    final selecaoValida =
        selecionado != null && horarios.any((h) => h.hora == selecionado);

    final selecionadoSeguro = selecaoValida ? selecionado : null;

    if (carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (buscaIniciada && horarios.isEmpty) {
      return Text(
        '🔴 Nenhum horário cadastrado para este serviço na data selecionada.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
      );
    }

    if (horarios.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: horarios.map((h) {
        final ocupado = h.ocupado;
        final hora = h.hora;
        final passado = h.passado;
        final selecionadoChip = selecionadoSeguro == hora;

        Color background;
        Color textColor;

        if (selecionadoChip) {
          background = theme.selecionadoBackground;
          textColor = theme.selecionadoText;
        } else if (ocupado) {
          background = theme.ocupadoBackground;
          textColor = theme.ocupadoText;
        } else if (passado) {
          background = theme.passadoBackground;
          textColor = theme.passadoText;
        } else {
          background = theme.livreBackground;
          textColor = theme.livreText;
        }

        return ChoiceChip(
          label: Text(hora, style: TextStyle(color: textColor)),
          selected: selecionadoChip,
          onSelected: (ocupado || passado)
              ? null
              : (selected) => onSelecionar(selected ? hora : null),
          selectedColor: theme.selecionadoBackground,
          backgroundColor: background,
          disabledColor: background,
        );
      }).toList(),
    );
  }
}