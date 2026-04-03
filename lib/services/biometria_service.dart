import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

class BiometriaService {
  static final LocalAuthentication _auth = LocalAuthentication();

  // Método para verificar se o celular suporta biometria ou tem PIN/Senha
  static Future<bool> podeAutenticar() async {
    final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
    return canAuthenticate;
  }

  // O método que de fato chama a janelinha de senha/digital
  static Future<bool> autenticar() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Acesse o Salão Pro com sua segurança',
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Autenticação Biométrica',
            biometricHint: 'Toque no sensor',
            cancelButton: 'Ir para senha manual',
          ),
          IOSAuthMessages(
            cancelButton: 'Cancelar',
          ),
        ],
        options: const AuthenticationOptions(
          stickyAuth: true,      // Mantém a tentativa se o app for pro fundo
          biometricOnly: false,  // PERMITE usar o PIN/Senha do celular se a biometria falhar
        ),
      );
    } catch (e) {
      return false;
    }
  }
}