import 'package:flutter/material.dart';

class DropdownSeguro<T> extends StatelessWidget {
  final String? value;
  final List<T> items;
  final String Function(T) getId;
  final String Function(T) getLabel;
  final String labelText;
  final String hintText;
  final bool enabled;
  final bool mostrarOpcaoVazia; // ✅ Novo parâmetro
  final void Function(String?)? onChanged;

  const DropdownSeguro({
    super.key,
    required this.items,
    required this.getId,
    required this.getLabel,
    required this.labelText,
    this.hintText = 'Selecione',
    this.value,
    this.enabled = true,
    this.mostrarOpcaoVazia = false, // ✅ Padrão é falso para não afetar os outros
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final itensUnicos = {
      for (var item in items) getId(item): item
    }.values.toList();

    final valueValido =
        value != null && itensUnicos.any((i) => getId(i) == value);

    return DropdownButtonFormField<String>(
      value: valueValido ? value : null,
      hint: Text(hintText),
      decoration: InputDecoration(
        labelText: labelText,
        // ... seus estilos de decoração permanecem iguais
      ),
      items: [
        // ✅ Só adiciona o item nulo se você pedir explicitamente
        if (mostrarOpcaoVazia)
          DropdownMenuItem<String>(
            value: null,
            child: Text(hintText),
          ),
        ...itensUnicos.map(
          (item) => DropdownMenuItem<String>(
            value: getId(item),
            child: Text(getLabel(item)),
          ),
        ),
      ],
      onChanged: enabled ? onChanged : null,
    );
  }
}