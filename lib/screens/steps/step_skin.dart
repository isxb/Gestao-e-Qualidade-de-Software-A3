import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/evolution_form.dart';
import '../../providers/evolution_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/pill_buttons.dart';
import '../../widgets/responsive_grid.dart';
import '../../widgets/section_card.dart';

class StepSkin extends StatelessWidget {
  const StepSkin({super.key});

  static const List<Map<String, String>> _aspectos = <Map<String, String>>[
    <String, String>{'v': 'íntegra', 'l': 'Íntegra'},
    <String, String>{'v': 'corada', 'l': 'Corada'},
    <String, String>{'v': 'descorada', 'l': 'Descorada'},
    <String, String>{'v': 'hidratada', 'l': 'Hidratada'},
    <String, String>{'v': 'ressecada', 'l': 'Ressecada'},
    <String, String>{'v': 'ictérica', 'l': 'Ictérica'},
    <String, String>{'v': 'cianótica', 'l': 'Cianótica'},
    <String, String>{'v': 'com equimoses', 'l': 'Equimoses'},
    <String, String>{'v': 'com hematomas', 'l': 'Hematomas'},
  ];

  static const List<Map<String, String>> _lesoes = <Map<String, String>>[
    <String, String>{'v': 'não possui lesões', 'l': 'Não possui lesões'},
    <String, String>{'v': 'LPP estágio 1', 'l': 'LPP Estágio 1'},
    <String, String>{'v': 'LPP estágio 2', 'l': 'LPP Estágio 2'},
    <String, String>{'v': 'LPP estágio 3', 'l': 'LPP Estágio 3'},
    <String, String>{'v': 'LPP estágio 4', 'l': 'LPP Estágio 4'},
    <String, String>{'v': 'lesão não estadiável', 'l': 'Não estadiável'},
    <String, String>{'v': 'lesão por fricção', 'l': 'Fricção'},
    <String, String>{'v': 'ferida operatória', 'l': 'Ferida operatória'},
    <String, String>{'v': 'úlcera venosa', 'l': 'Úlcera venosa'},
  ];

  @override
  Widget build(BuildContext context) {
    final EvolutionProvider p = context.watch<EvolutionProvider>();
    final EvolutionForm f = p.form;

    return SectionCard(
      title: '#Integridade Cutânea',
      subtitle: 'Avaliação da pele e risco de lesão por pressão',
      icon: Icons.healing_rounded,
      children: <Widget>[
        const SubsectionTitle('Aspecto da Pele', topPadding: 0),
        PillGroup(
          children: <Widget>[
            for (final Map<String, String> o in _aspectos)
              Pill(
                label: o['l']!,
                selected: f.peleAspecto.contains(o['v']),
                onTap: () => p.toggleChecklist(
                  fieldName: 'peleAspecto',
                  value: o['v']!,
                ),
              ),
          ],
        ),
        const SubsectionTitle('Lesões por Pressão / Feridas'),
        PillGroup(
          children: <Widget>[
            for (final Map<String, String> o in _lesoes)
              Pill(
                label: o['l']!,
                selected: f.lesoes.contains(o['v']),
                onTap: () => p.toggleChecklist(
                  fieldName: 'lesoes',
                  value: o['v']!,
                ),
              ),
          ],
        ),
        const SubsectionTitle('Escala de Braden'),
        ResponsiveGrid(
          children: <Widget>[
            LabeledField(
              label: 'Percepção Sensorial',
              child: _bradenSelect(
                context,
                f.b1,
                const <String>[
                  '1 – Completamente limitada',
                  '2 – Muito limitada',
                  '3 – Levemente limitada',
                  '4 – Sem limitação',
                ],
                (int v) => p.updateForm(
                  (EvolutionForm x) => x.copyWith(b1: v),
                ),
              ),
            ),
            LabeledField(
              label: 'Umidade',
              child: _bradenSelect(
                context,
                f.b2,
                const <String>[
                  '1 – Constantemente úmida',
                  '2 – Muito úmida',
                  '3 – Ocasionalmente úmida',
                  '4 – Raramente úmida',
                ],
                (int v) => p.updateForm(
                  (EvolutionForm x) => x.copyWith(b2: v),
                ),
              ),
            ),
            LabeledField(
              label: 'Atividade',
              child: _bradenSelect(
                context,
                f.b3,
                const <String>[
                  '1 – Acamado',
                  '2 – Restrito à cadeira',
                  '3 – Anda ocasionalmente',
                  '4 – Deambula com frequência',
                ],
                (int v) => p.updateForm(
                  (EvolutionForm x) => x.copyWith(b3: v),
                ),
              ),
            ),
            LabeledField(
              label: 'Mobilidade',
              child: _bradenSelect(
                context,
                f.b4,
                const <String>[
                  '1 – Totalmente imóvel',
                  '2 – Muito limitada',
                  '3 – Levemente limitada',
                  '4 – Sem limitação',
                ],
                (int v) => p.updateForm(
                  (EvolutionForm x) => x.copyWith(b4: v),
                ),
              ),
            ),
            LabeledField(
              label: 'Nutrição',
              child: _bradenSelect(
                context,
                f.b5,
                const <String>[
                  '1 – Muito pobre',
                  '2 – Provavelmente inadequada',
                  '3 – Adequada',
                  '4 – Excelente',
                ],
                (int v) => p.updateForm(
                  (EvolutionForm x) => x.copyWith(b5: v),
                ),
              ),
            ),
            LabeledField(
              label: 'Fricção / Cisalhamento',
              child: _bradenSelect(
                context,
                f.b6,
                const <String>[
                  '1 – Problema',
                  '2 – Problema potencial',
                  '3 – Sem problema aparente',
                ],
                (int v) => p.updateForm(
                  (EvolutionForm x) => x.copyWith(b6: v),
                ),
                startAtOne: true,
                max: 3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _BradenResult(total: f.bradenTotal, risco: f.bradenRisco),
      ],
    );
  }

  Widget _bradenSelect(
    BuildContext context,
    int current,
    List<String> labels,
    ValueChanged<int> onChanged, {
    bool startAtOne = true,
    int max = 4,
  }) {
    return AppDropdown<int>(
      value: current,
      items: <DropdownMenuItem<int>>[
        for (int i = 0; i < labels.length; i++)
          DropdownMenuItem<int>(
            value: startAtOne ? i + 1 : i,
            child: Text(labels[i]),
          ),
      ],
      onChanged: (int? v) => onChanged(v ?? current),
    );
  }
}

class _BradenResult extends StatelessWidget {
  const _BradenResult({required this.total, required this.risco});

  final int total;
  final String risco;

  Color get _color {
    if (total <= 9) return AppColors.danger;
    if (total <= 12) return AppColors.warning;
    if (total <= 14) return const Color(0xFFCA8A04);
    if (total <= 18) return const Color(0xFF2563EB);
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.insights_rounded, color: _color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pontuação Braden: $total pontos — $risco',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
