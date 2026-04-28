import '../models/user.dart';
import 'auth_service.dart';

/// Serviço de autenticação federada com Google.
///
/// **Status atual:** estrutura pronta, integração desabilitada.
///
/// Para habilitar de verdade é preciso:
///   1. Criar projeto no Google Cloud Console e gerar OAuth 2.0 Client IDs
///      por plataforma (Android, iOS, Web; Windows desktop usa flow via
///      browser externo);
///   2. Adicionar o pacote `google_sign_in` (mobile/web) ou implementar
///      OAuth via `url_launcher` + servidor local de callback (Windows);
///   3. No callback, chamar [signInOrRegisterFromGoogle] com os dados
///      retornados pelo Google;
///   4. Avaliar o impacto na proposta "100% offline" do app — passa a
///      existir comunicação com servidores Google e o e-mail do usuário
///      é compartilhado com a plataforma.
///
/// Enquanto a integração não é configurada, [signIn] devolve um erro
/// explícito em vez de fingir que funciona.
class GoogleAuthService {
  GoogleAuthService._();
  static final GoogleAuthService instance = GoogleAuthService._();

  /// Tenta iniciar o fluxo de login com Google.
  /// Hoje, sempre lança [AuthException] explicando o que falta.
  Future<AppUser> signIn() async {
    throw AuthException(
      'google-not-configured',
      'Login com Google ainda não está configurado neste dispositivo. '
          'Veja a documentação para habilitar.',
    );
  }

  /// Ponto de extensão futuro: dado o e-mail/nome retornados pelo Google,
  /// localiza um usuário existente ou cria um novo (role standard).
  /// Não é chamado hoje — fica pronto para quando o OAuth for plugado.
  Future<AppUser> signInOrRegisterFromGoogle({
    required String email,
    required String displayName,
  }) async {
    throw AuthException(
      'google-not-configured',
      'Integração com Google pendente de configuração.',
    );
  }
}
