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
    /// Remove duplicados pelo ID
    final itensUnicos = {
      for (final item in items) getId(item): item,
    }.values.toList();

    /// Verifica se o value existe na lista
    final bool valueValido =
        value != null && itensUnicos.any((item) => getId(item) == value);

    if (value != null && !valueValido) {
      debugPrint(
        '⚠️ DropdownSeguro [$labelText]: value ($value) não encontrado. Resetando para null.',
      );
    }

    final List<DropdownMenuItem<String?>> dropdownItems = [];

    /// Opção vazia real
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

    /// Itens normais
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
