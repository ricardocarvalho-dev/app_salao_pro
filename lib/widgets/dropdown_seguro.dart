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
    ///
    /*
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
    */  

    // Adiciona a opção vazia ou "Selecione" quando a lista está vazia
    ///*
    if (itensUnicos.isEmpty || mostrarOpcaoVazia) {
      dropdownItems.add(
        //DropdownMenuItem<String?>(
        DropdownMenuItem<String?>(
          value: null, // Valor nulo para indicar "Sem Seleção"
          //value: '', // usar string vazia em vez de null
          child: Text(
            textoOpcaoVazia, // Aqui usamos o texto customizado da opção vazia
            style: TextStyle(
              color: Theme.of(context).hintColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    } 
    //*/   

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
      initialValue: valueValido ? value : null,
      hint: Text(hintText),
      decoration: InputDecoration(
        labelText: labelText,
      ),
      //items: dropdownItems,
      items: [ 
        if (mostrarOpcaoVazia || itensUnicos.isEmpty) 
          DropdownMenuItem<String?>( 
            value: null, 
            child: Text( 
              textoOpcaoVazia, 
              style: Theme.of(context).textTheme.bodyMedium?.copyWith( 
                color: Theme.of(context).hintColor, 
                fontStyle: FontStyle.italic, 
              ), 
            ), 
          ), 
        ...itensUnicos.map( 
          (item) => DropdownMenuItem<String?>( 
            value: getId(item), 
            child: Text(getLabel(item)),
          ), 
        ), 
      ],      
      onChanged: enabled ? onChanged : null,
    );
  }
}
