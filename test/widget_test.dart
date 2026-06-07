// Testes de Widget (caixa preta) — componentes reutilizáveis da UI
// Tipo: Teste de Sistema | Abordagem: Caixa Preta
// Verifica comportamento visual dos widgets sem conhecimento de implementação interna.
// Nota: testes do app completo (EvoluaProApp) requerem inicialização de plugins
// de plataforma (secure_storage, dotenv, ads) e são cobertos por testes manuais.
import 'package:evolua_pro/widgets/tag_chip.dart';
import 'package:evolua_pro/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Envolve o widget em um MaterialApp mínimo para fornecer Theme e Directionality.
Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  // =========================================================
  // TagChip
  // =========================================================
  group('TagChip', () {
    testWidgets('renderiza o rótulo informado', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(const TagChip(label: 'UTI Adulto')),
      );
      expect(find.text('UTI Adulto'), findsOneWidget);
    });

    testWidgets('sem onRemove não exibe o ícone de fechar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(const TagChip(label: 'Cirúrgico')),
      );
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('com onRemove exibe o ícone de fechar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(TagChip(label: 'UTI Neo', onRemove: () {})),
      );
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('tap em onRemove dispara o callback',
        (WidgetTester tester) async {
      bool removido = false;
      await tester.pumpWidget(
        wrap(TagChip(label: 'UCO', onRemove: () => removido = true)),
      );
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(removido, isTrue);
    });
  });

  // =========================================================
  // StatCard
  // =========================================================
  group('StatCard', () {
    testWidgets('renderiza label e value corretamente',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          const StatCard(
            icon: Icons.people_outline,
            label: 'Total de Usuários',
            value: '42',
          ),
        ),
      );
      expect(find.text('Total de Usuários'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('renderiza hint quando fornecido', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          const StatCard(
            icon: Icons.bar_chart,
            label: 'Evoluções',
            value: '128',
            hint: 'Últimas 24h',
          ),
        ),
      );
      expect(find.text('Últimas 24h'), findsOneWidget);
    });

    testWidgets('sem hint não exibe texto extra', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          const StatCard(
            icon: Icons.bar_chart,
            label: 'Evoluções',
            value: '128',
          ),
        ),
      );
      expect(find.text('Últimas 24h'), findsNothing);
    });

    testWidgets('tap em onTap dispara o callback', (WidgetTester tester) async {
      bool tocado = false;
      await tester.pumpWidget(
        wrap(
          StatCard(
            icon: Icons.touch_app,
            label: 'Toque',
            value: '1',
            onTap: () => tocado = true,
          ),
        ),
      );
      await tester.tap(find.byType(InkWell));
      await tester.pump();
      expect(tocado, isTrue);
    });

    testWidgets('exibe o ícone correto', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          const StatCard(
            icon: Icons.local_hospital,
            label: 'Hospital',
            value: '5',
          ),
        ),
      );
      expect(find.byIcon(Icons.local_hospital), findsOneWidget);
    });
  });
}
