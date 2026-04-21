import 'package:evolua_pro/models/evolution_form.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EvolutionForm', () {
    test('bradenTotal soma os 6 componentes', () {
      final EvolutionForm f = EvolutionForm()
          .copyWith(b1: 3, b2: 3, b3: 3, b4: 3, b5: 3, b6: 3);
      expect(f.bradenTotal, 18);
    });

    test('bradenRisco reflete a pontuação', () {
      final EvolutionForm alto = EvolutionForm()
          .copyWith(b1: 1, b2: 2, b3: 1, b4: 2, b5: 1, b6: 1);
      expect(alto.bradenTotal, 8);
      expect(alto.bradenRisco.toLowerCase(), contains('muito alto'));

      final EvolutionForm baixo = EvolutionForm()
          .copyWith(b1: 4, b2: 4, b3: 4, b4: 4, b5: 4, b6: 3);
      expect(baixo.bradenTotal, 23);
      expect(baixo.bradenRisco.toLowerCase(), contains('sem risco'));
    });

    test('glasgowTotal soma ocular + verbal + motor (ignora pupilar)', () {
      final EvolutionForm f = EvolutionForm().copyWith(
        glasgowOcular: 4,
        glasgowVerbal: 5,
        glasgowMotor: 6,
        glasgowPupilar: 2,
      );
      expect(f.glasgowTotal, 15);
    });

    test('copyWith preserva valores não informados', () {
      final EvolutionForm base =
          EvolutionForm().copyWith(pacienteNome: 'Maria', eva: 7);
      final EvolutionForm next = base.copyWith(locDor: 'lombar');
      expect(next.pacienteNome, 'Maria');
      expect(next.eva, 7);
      expect(next.locDor, 'lombar');
    });
  });
}
