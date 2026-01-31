import 'package:flutter/material.dart';

class DropdownSeguro<T> extends StatelessWidget {
  final String? value;
  final List<T> items;
  final String Function(T) getId;
  final String Function(T) getLabel;
  final String labelText;
  final String hintText;
  final bool enabled;
  final bool mostrarOpcaoVazia;
  final String textoOpcaoVazia;
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
    this.mostrarOpcaoVazia = false,
    this.textoOpcaoVazia = 'Sem seleção',
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Remove duplicados pelo ID
    final itensUnicos = {
      for (final item in items) getId(item): item,
    }.values.toList();

    // Verifica se o value atual existe nos itens
    final valueValido = value != null &&
        itensUnicos.any((item) => getId(item) == value);

    final List<DropdownMenuItem<String?>> dropdownItems = [];

    // 🔹 OPÇÃO NULA REAL (CRÍTICA)
    if (mostrarOpcaoVazia) {
      dropdownItems.add(
        DropdownMenuItem<String?>(
          value: null,
          child: Text(
            textoOpcaoVazia,
            style: TextStyle(
              color: Theme.of(context).hintColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    // 🔹 ITENS NORMAIS
    dropdownItems.addAll(
      itensUnicos.map(
        (item) => DropdownMenuItem<String?>(
          value: getId(item),
          child: Text(getLabel(item)),
        ),
      ),
    );

    return DropdownButtonFormField<String?>(
      isExpanded: true,
      value: valueValido ? value : null,
      hint: Text(hintText),
      decoration: InputDecoration(
        labelText: labelText,
      ),
      items: dropdownItems,
      onChanged: enabled ? onChanged : null,
    );
  }
}
