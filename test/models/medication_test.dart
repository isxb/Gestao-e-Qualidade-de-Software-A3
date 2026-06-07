// Testes unitários (caixa preta) — modelo Medication
// Tipo: Teste Unitário | Abordagem: Caixa Preta (verifica comportamento externo)
import 'package:evolua_pro/models/medication.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Medication', () {
    test('display inclui nome, dose e períodos quando todos informados', () {
      final Medication med = Medication(
        nome: 'Dipirona',
        dose: '500mg',
        periodos: <String>['06h', '12h', '18h'],
      );
      expect(med.display, contains('Dipirona'));
      expect(med.display, contains('500mg'));
      expect(med.display, contains('06h'));
      expect(med.display, contains('18h'));
    });

    test('display sem dose não inclui separador de dose', () {
      final Medication med = Medication(nome: 'Paracetamol', dose: '');
      expect(med.display, 'Paracetamol');
      expect(med.display, isNot(contains('—')));
    });

    test('display com dose mas sem períodos não inclui parênteses', () {
      final Medication med = Medication(nome: 'Omeprazol', dose: '20mg');
      expect(med.display, 'Omeprazol — 20mg');
      expect(med.display, isNot(contains('(')));
    });

    test('display sem dose e sem períodos retorna apenas o nome', () {
      final Medication med = Medication(nome: 'Água Destilada');
      expect(med.display, 'Água Destilada');
    });

    test('copyWith substitui apenas o campo informado', () {
      final Medication original = Medication(
        nome: 'Amoxicilina',
        dose: '500mg',
        periodos: <String>['08h', '20h'],
      );
      final Medication copia = original.copyWith(dose: '1g');
      expect(copia.nome, 'Amoxicilina');
      expect(copia.dose, '1g');
      expect(copia.periodos, <String>['08h', '20h']);
    });

    test('copyWith com nova lista de periodos é independente da original', () {
      final Medication original = Medication(
        nome: 'X',
        periodos: <String>['08h'],
      );
      final List<String> novosPeriodos = <String>['08h', '20h'];
      final Medication copia = original.copyWith(periodos: novosPeriodos);
      novosPeriodos.add('00h');
      expect(copia.periodos.length, 2);
    });

    test('toJson / fromJson é round-trip fiel', () {
      final Medication original = Medication(
        nome: 'Dipirona',
        dose: '500mg',
        periodos: <String>['06h', '18h'],
      );
      final Medication restaurado = Medication.fromJson(original.toJson());
      expect(restaurado.nome, original.nome);
      expect(restaurado.dose, original.dose);
      expect(restaurado.periodos, original.periodos);
    });

    test('fromJson com campos ausentes usa defaults', () {
      final Medication med =
          Medication.fromJson(<String, dynamic>{'nome': 'Genérico'});
      expect(med.dose, '');
      expect(med.periodos, isEmpty);
    });

    test('fromJson com periodos nulo usa lista vazia', () {
      final Medication med = Medication.fromJson(<String, dynamic>{
        'nome': 'X',
        'dose': '10mg',
        'periodos': null,
      });
      expect(med.periodos, isEmpty);
    });
  });
}
