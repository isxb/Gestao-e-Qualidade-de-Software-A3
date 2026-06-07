// Testes unitários (caixa preta) — modelo SavedEvolution
// Tipo: Teste Unitário | Abordagem: Caixa Preta
import 'package:evolua_pro/models/saved_evolution.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SavedEvolution', () {
    final SavedEvolution sample = SavedEvolution(
      id: 'ev-001',
      date: '07/06/2025',
      time: '14:30',
      patientName: 'João da Silva',
      text: 'Paciente orientado, hemodinamicamente estável...',
    );

    test('copyWith altera apenas o campo especificado', () {
      final SavedEvolution copia = sample.copyWith(time: '15:00');
      expect(copia.time, '15:00');
      expect(copia.patientName, 'João da Silva');
      expect(copia.id, 'ev-001');
      expect(copia.date, '07/06/2025');
    });

    test('copyWith sem argumentos retorna cópia idêntica', () {
      final SavedEvolution copia = sample.copyWith();
      expect(copia.id, sample.id);
      expect(copia.text, sample.text);
    });

    test('toJson contém todas as chaves esperadas', () {
      final Map<String, dynamic> json = sample.toJson();
      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('date'), isTrue);
      expect(json.containsKey('time'), isTrue);
      expect(json.containsKey('patientName'), isTrue);
      expect(json.containsKey('text'), isTrue);
    });

    test('toJson / fromJson é round-trip fiel', () {
      final SavedEvolution restaurado = SavedEvolution.fromJson(sample.toJson());
      expect(restaurado.id, sample.id);
      expect(restaurado.patientName, sample.patientName);
      expect(restaurado.date, sample.date);
      expect(restaurado.time, sample.time);
      expect(restaurado.text, sample.text);
    });

    test('fromJson com campos ausentes usa string vazia como default', () {
      final SavedEvolution ev =
          SavedEvolution.fromJson(<String, dynamic>{});
      expect(ev.id, '');
      expect(ev.patientName, '');
      expect(ev.text, '');
    });
  });
}
