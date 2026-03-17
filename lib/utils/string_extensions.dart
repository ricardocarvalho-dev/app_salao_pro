extension TelefoneFormatter on String {
  // Transforma 5571991147042 em +55 (71) 99114-7042
  String toTelefoneElegante() {
    String numeros = this.replaceAll(RegExp(r'\D'), '');
    
    if (numeros.length == 13 && numeros.startsWith('55')) {
      return '+55 (${numeros.substring(2, 4)}) ${numeros.substring(4, 9)}-${numeros.substring(9)}';
    }
    // Caso o número venha sem o 55 mas com DDD
    if (numeros.length == 11) {
      return '(${numeros.substring(0, 2)}) ${numeros.substring(2, 7)}-${numeros.substring(7)}';
    }
    return this; 
  }

  // Transforma (71) 99114-7042 em 5571991147042 (Para enviar ao Supabase)
  String limparParaBanco() {
    String limpo = this.replaceAll(RegExp(r'\D'), '');
    if (limpo.isNotEmpty && !limpo.startsWith('55')) {
      limpo = '55$limpo';
    }
    return limpo;
  }
}