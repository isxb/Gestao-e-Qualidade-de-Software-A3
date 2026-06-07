// Testes unitários (caixa branca) — CryptoService (PBKDF2-HMAC-SHA256)
// Tipo: Teste Unitário | Abordagem: Caixa Branca (verifica lógica interna)
// Justificativa: segurança crítica — hash de senha e verificação em tempo constante
import 'package:evolua_pro/services/crypto_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CryptoService', () {
    // ---------------------------------------------------------
    // generateSalt
    // ---------------------------------------------------------
    group('generateSalt', () {
      test('retorna string não vazia em base64', () {
        final String salt = CryptoService.generateSalt();
        expect(salt, isNotEmpty);
      });

      test('cada chamada gera um salt diferente (aleatoriedade)', () {
        final String s1 = CryptoService.generateSalt();
        final String s2 = CryptoService.generateSalt();
        expect(s1, isNot(equals(s2)));
      });
    });

    // ---------------------------------------------------------
    // generateToken
    // ---------------------------------------------------------
    group('generateToken', () {
      test('retorna string não vazia e sem padding "="', () {
        final String token = CryptoService.generateToken();
        expect(token, isNotEmpty);
        expect(token, isNot(contains('=')));
      });

      test('cada chamada gera um token diferente', () {
        final String t1 = CryptoService.generateToken();
        final String t2 = CryptoService.generateToken();
        expect(t1, isNot(equals(t2)));
      });

      test('tamanho customizado gera token proporcional ao bytes pedido', () {
        final String t16 = CryptoService.generateToken(bytes: 16);
        final String t64 = CryptoService.generateToken(bytes: 64);
        expect(t64.length, greaterThan(t16.length));
      });
    });

    // ---------------------------------------------------------
    // generateTempPassword
    // ---------------------------------------------------------
    group('generateTempPassword', () {
      test('segue o formato EV-XXXX-XXXX com chars permitidos', () {
        final String pwd = CryptoService.generateTempPassword();
        expect(pwd, matches(r'^EV-[A-Z2-9]{4}-[A-Z2-9]{4}$'));
      });

      test('cada chamada gera senha diferente', () {
        final String p1 = CryptoService.generateTempPassword();
        final String p2 = CryptoService.generateTempPassword();
        expect(p1, isNot(equals(p2)));
      });
    });

    // ---------------------------------------------------------
    // hashPassword / verifyPassword (núcleo PBKDF2)
    // Caixa Branca: testamos propriedades do algoritmo
    // ---------------------------------------------------------
    group('hashPassword / verifyPassword', () {
      const String senha = 'Senha@Segura123';
      const int iter = 1; // 1 iteração para velocidade em CI

      test('hashPassword retorna base64 não vazio', () {
        final String salt = CryptoService.generateSalt();
        final String hash = CryptoService.hashPassword(
          password: senha,
          saltBase64: salt,
          iterations: iter,
        );
        expect(hash, isNotEmpty);
      });

      test('hashPassword é determinístico — mesmo input gera mesmo output', () {
        final String salt = CryptoService.generateSalt();
        final String h1 = CryptoService.hashPassword(
          password: senha,
          saltBase64: salt,
          iterations: iter,
        );
        final String h2 = CryptoService.hashPassword(
          password: senha,
          saltBase64: salt,
          iterations: iter,
        );
        expect(h1, equals(h2));
      });

      test('salts diferentes produzem hashes diferentes para a mesma senha', () {
        final String s1 = CryptoService.generateSalt();
        final String s2 = CryptoService.generateSalt();
        final String h1 = CryptoService.hashPassword(
          password: senha,
          saltBase64: s1,
          iterations: iter,
        );
        final String h2 = CryptoService.hashPassword(
          password: senha,
          saltBase64: s2,
          iterations: iter,
        );
        expect(h1, isNot(equals(h2)));
      });

      test('verifyPassword retorna true para senha correta', () {
        final String salt = CryptoService.generateSalt();
        final String hash = CryptoService.hashPassword(
          password: senha,
          saltBase64: salt,
          iterations: iter,
        );
        expect(
          CryptoService.verifyPassword(
            password: senha,
            expectedHashBase64: hash,
            saltBase64: salt,
            iterations: iter,
          ),
          isTrue,
        );
      });

      test('verifyPassword retorna false para senha incorreta', () {
        final String salt = CryptoService.generateSalt();
        final String hash = CryptoService.hashPassword(
          password: senha,
          saltBase64: salt,
          iterations: iter,
        );
        expect(
          CryptoService.verifyPassword(
            password: 'SenhaErrada!',
            expectedHashBase64: hash,
            saltBase64: salt,
            iterations: iter,
          ),
          isFalse,
        );
      });

      test('verifyPassword retorna false para senha vazia', () {
        final String salt = CryptoService.generateSalt();
        final String hash = CryptoService.hashPassword(
          password: senha,
          saltBase64: salt,
          iterations: iter,
        );
        expect(
          CryptoService.verifyPassword(
            password: '',
            expectedHashBase64: hash,
            saltBase64: salt,
            iterations: iter,
          ),
          isFalse,
        );
      });
    });

    // ---------------------------------------------------------
    // passwordStrength
    // Caixa Branca: validamos cada critério da lógica de pontuação
    // ---------------------------------------------------------
    group('passwordStrength', () {
      test('string vazia → pontuação 0', () {
        expect(CryptoService.passwordStrength(''), equals(0));
      });

      test('senha curta (< 8 chars) → pontuação baixa (< 2)', () {
        expect(CryptoService.passwordStrength('abc'), lessThan(2));
      });

      test('senha com apenas letras minúsculas de 8 chars → pontuação 1', () {
        expect(CryptoService.passwordStrength('abcdefgh'), equals(1));
      });

      test('senha com letras maiúsculas e minúsculas → +1 ponto', () {
        final int s = CryptoService.passwordStrength('Abcdefgh');
        expect(s, greaterThanOrEqualTo(2));
      });

      test('senha com dígito acrescenta ponto', () {
        final int s = CryptoService.passwordStrength('Abcdefg1');
        expect(s, greaterThanOrEqualTo(3));
      });

      test('senha forte com símbolo → pontuação máxima (4)', () {
        expect(CryptoService.passwordStrength('Senha@Forte123!'), equals(4));
      });

      test('pontuação sempre entre 0 e 4 (clampada)', () {
        for (final String pwd in <String>[
          '',
          'a',
          'Senha123',
          'Senha@Forte123!',
        ]) {
          final int score = CryptoService.passwordStrength(pwd);
          expect(score, inInclusiveRange(0, 4));
        }
      });
    });

    // ---------------------------------------------------------
    // passwordStrengthLabel
    // ---------------------------------------------------------
    group('passwordStrengthLabel', () {
      test('score 0 → "Fraca"', () {
        expect(CryptoService.passwordStrengthLabel(0), 'Fraca');
      });

      test('score 1 → "Fraca"', () {
        expect(CryptoService.passwordStrengthLabel(1), 'Fraca');
      });

      test('score 2 → "Regular"', () {
        expect(CryptoService.passwordStrengthLabel(2), 'Regular');
      });

      test('score 3 → "Boa"', () {
        expect(CryptoService.passwordStrengthLabel(3), 'Boa');
      });

      test('score 4 → "Excelente"', () {
        expect(CryptoService.passwordStrengthLabel(4), 'Excelente');
      });
    });
  });
}
