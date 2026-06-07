// Testes unitários (caixa preta) — modelo Infusion
// Tipo: Teste Unitário | Abordagem: Caixa Preta
import 'package:evolua_pro/models/infusion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Infusion', () {
    test('display com detalhe concatena nome e detalhe com separador', () {
      final Infusion inf = Infusion(nome: 'SF 0,9%', detalhe: '500ml em 4h');
      expect(inf.display, 'SF 0,9% — 500ml em 4h');
    });

    test('display sem detalhe retorna apenas o nome', () {
      final Infusion inf = Infusion(nome: 'Soro Fisiológico');
      expect(inf.display, 'Soro Fisiológico');
      expect(inf.display, isNot(contains('—')));
    });

    test('display com detalhe vazio retorna apenas o nome', () {
      final Infusion inf = Infusion(nome: 'SG 5%', detalhe: '');
      expect(inf.display, 'SG 5%');
    });

    test('toJson serializa com chave "det" (não "detalhe")', () {
      final Infusion inf = Infusion(nome: 'Ringer Lactato', detalhe: '125ml/h');
      final Map<String, dynamic> json = inf.toJson();
      expect(json['nome'], 'Ringer Lactato');
      expect(json['det'], '125ml/h');
      expect(json.containsKey('detalhe'), isFalse);
    });

    test('toJson / fromJson é round-trip fiel', () {
      final Infusion original = Infusion(nome: 'KCl 10%', detalhe: '10ml/h');
      final Infusion restaurado = Infusion.fromJson(original.toJson());
      expect(restaurado.nome, original.nome);
      expect(restaurado.detalhe, original.detalhe);
    });

    test('fromJson com campos ausentes usa string vazia como default', () {
      final Infusion inf = Infusion.fromJson(<String, dynamic>{});
      expect(inf.nome, '');
      expect(inf.detalhe, '');
    });
  });
}
