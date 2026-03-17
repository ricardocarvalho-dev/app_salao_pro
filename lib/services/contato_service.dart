import 'package:fast_contacts/fast_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Adicione esta linha

class ContatoService {
  // Adicione este método dentro da sua classe ContatoService
  static Future<bool> pedirPermissao() async {
    // Se estiver no navegador, ignoramos a checagem e retornamos true
    if (kIsWeb) return true;    
    
    var status = await Permission.contacts.status;
    if (status.isDenied) {
      status = await Permission.contacts.request();
    }
    return status.isGranted;
  }  
  /// Recebe o telefone no formato do seu banco (ex: (71) 98765-9043)
  /// e tenta encontrar um nome correspondente na agenda do celular do dono.
  static Future<String?> buscarNomeNaAgenda(String telefoneBanco) async {
    // 1. Verifica/Pede permissão de contatos
    var status = await Permission.contacts.status;
    if (status.isDenied) {
      status = await Permission.contacts.request();
    }

    if (status.isGranted) {
      try {
        final contacts = await FastContacts.getAllContacts();
        
        // 2. Limpa o telefone que vem do banco (remove (, ), - e espaços)
        // Ex: (71) 98765-9043 -> 71987659043
        String numLimpoBanco = telefoneBanco.replaceAll(RegExp(r'\D'), '');

        // Se o número for muito curto (erro de cadastro), cancela a busca
        if (numLimpoBanco.length < 8) return null;

        for (var contact in contacts) {
          for (var phone in contact.phones) {
            // 3. Limpa o telefone da agenda do celular (remove tudo que não é número)
            String p = phone.number.replaceAll(RegExp(r'\D'), '');
            
            // 4. Comparação inteligente de sufixo (pega os últimos 8 ou 9 dígitos)
            // Isso resolve problemas de DDI (55) ou DDD (071 vs 71)
            if (p.length >= 8 && numLimpoBanco.length >= 8) {
              if (p.endsWith(numLimpoBanco) || numLimpoBanco.endsWith(p)) {
                return contact.displayName;
              }
            }
          }
        }
      } catch (e) {
        print("Erro ao buscar contatos: $e");
        return null;
      }
    }
    return null; // Retorna null se não houver permissão ou não encontrar
  }
}