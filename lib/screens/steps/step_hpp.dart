import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/evolution_form.dart';
import '../../models/medication.dart';
import '../../providers/evolution_provider.dart';
import '../../widgets/action_button.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/pill_buttons.dart';
import '../../widgets/responsive_grid.dart';
import '../../widgets/section_card.dart';
import '../../widgets/tag_chip.dart';

class StepHpp extends StatefulWidget {
  const StepHpp({super.key});

  @override
  State<StepHpp> createState() => _StepHppState();
}

class _StepHppState extends State<StepHpp> {
  final TextEditingController _comorbidade = TextEditingController();
  final TextEditingController _medNome = TextEditingController();
  final TextEditingController _medDose = TextEditingController();
  final Set<String> _medPeriodos = <String>{};

  @override
  void dispose() {
    _comorbidade.dispose();
    _medNome.dispose();
    _medDose.dispose();
    super.dispose();
  }

  void _addComorbidade(EvolutionProvider p) {
    p.addComorbidity(_comorbidade.text);
    _comorbidade.clear();
    setState(() {});
  }

  void _addMedicacao(EvolutionProvider p) {
    if (_medNome.text.trim().isEmpty) return;
    p.addMedication(
      Medication(
        nome: _medNome.text.trim(),
        dose: _medDose.text.trim(),
        periodos: _medPeriodos.toList(),
      ),
    );
    _medNome.clear();
    _medDose.clear();
    _medPeriodos.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final EvolutionProvider p = context.watch<EvolutionProvider>();
    final EvolutionForm f = p.form;

    return SectionCard(
      title: '#HPP — Histórico Patológico Pregresso',
      subtitle: 'Comorbidades, medicações e cirurgias anteriores',
      icon: Icons.receipt_long_rounded,
      children: <Widget>[
        Text(
          'Comorbidades',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        if (f.comorbidades.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (int i = 0; i < f.comorbidades.length; i++)
                  TagChip(
                    label: f.comorbidades[i],
                    onRemove: () => p.removeComorbidity(i),
                  ),
              ],
            ),
          ),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final bool wide = c.maxWidth > 480;
            return Flex(
              direction: wide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  flex: wide ? 1 : 0,
                  child: LabeledField(
                    label: 'Adicionar Comorbidade',
                    child: TextField(
                      controller: _comorbidade,
                      decoration: const InputDecoration(
                        hintText: 'Ex: Hipertensão Arterial Sistêmica',
                      ),
                      onSubmitted: (_) => _addComorbidade(p),
                    ),
                  ),
                ),
                SizedBox(width: wide ? 12 : 0, height: wide ? 0 : 10),
                ActionButton(
                  label: 'Adicionar',
                  icon: Icons.add_rounded,
                  kind: ActionButtonKind.secondary,
                  onPressed: () => _addComorbidade(p),
                ),
              ],
            );
          },
        ),
        const SubsectionTitle('Alergias'),
        PillGroup(
          children: <Widget>[
            Pill(
              label: 'Nega alergias',
              selected: f.alergiasOp == 'nega',
              onTap: () => p.updateForm(
                (EvolutionForm x) => x.copyWith(alergiasOp: 'nega'),
              ),
            ),
            Pill(
              label: 'Refere alergias',
              selected: f.alergiasOp == 'refere',
              onTap: () => p.updateForm(
                (EvolutionForm x) => x.copyWith(alergiasOp: 'refere'),
              ),
            ),
          ],
        ),
        if (f.alergiasOp == 'refere') ...<Widget>[
          const SizedBox(height: 12),
          LabeledField(
            label: 'Detalhar alergia(s)',
            child: AppTextField(
              initialValue: f.alergiasTexto,
              hint: 'Ex: dipirona, látex...',
              onChanged: (String v) => p.updateForm(
                (EvolutionForm x) => x.copyWith(alergiasTexto: v),
              ),
            ),
          ),
        ],
        const SubsectionTitle('Medicações em Uso Domiciliar'),
        if (p.medications.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              children: <Widget>[
                for (int i = 0; i < p.medications.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TagChip(
                      label: p.medications[i].display,
                      onRemove: () => p.removeMedication(i),
                    ),
                  ),
              ],
            ),
          ),
        ResponsiveGrid(
          minItemWidth: 220,
          children: <Widget>[
            LabeledField(
              label: 'Medicamento',
              child: TextField(
                controller: _medNome,
                decoration: const InputDecoration(hintText: 'Nome'),
              ),
            ),
            LabeledField(
              label: 'Dose',
              child: TextField(
                controller: _medDose,
                decoration: const InputDecoration(hintText: 'Ex: 50mg'),
              ),
            ),
            LabeledField(
              label: 'Períodos',
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  for (final String pr in <String>['Manhã', 'Tarde', 'Noite'])
                    Pill(
                      label: pr,
                      selected: _medPeriodos.contains(pr),
                      onTap: () {
                        setState(() {
                          if (_medPeriodos.contains(pr)) {
                            _medPeriodos.remove(pr);
                          } else {
                            _medPeriodos.add(pr);
                          }
                        });
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: ActionButton(
            label: 'Adicionar Medicação',
            icon: Icons.add_rounded,
            kind: ActionButtonKind.secondary,
            onPressed: () => _addMedicacao(p),
          ),
        ),
        const SizedBox(height: 14),
        LabeledField(
          label: 'Adesão à Terapêutica',
          child: AppDropdown<String>(
            value: f.adesao,
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(
                value: 'com boa adesão à terapêutica',
                child: Text('Boa adesão'),
              ),
              DropdownMenuItem<String>(
                value: 'com adesão parcial à terapêutica',
                child: Text('Adesão parcial'),
              ),
              DropdownMenuItem<String>(
                value: 'com má adesão à terapêutica',
                child: Text('Má adesão'),
              ),
              DropdownMenuItem<String>(
                value: 'desconhecida',
                child: Text('Desconhecida'),
              ),
            ],
            onChanged: (String? v) => p.updateForm(
              (EvolutionForm x) => x.copyWith(adesao: v ?? x.adesao),
            ),
          ),
        ),
        const SubsectionTitle('Histórico Cirúrgico'),
        PillGroup(
          children: <Widget>[
            Pill(
              label: 'Nega cirurgias',
              selected: f.cirurgiaOp == 'nega cirurgias anteriores',
              onTap: () => p.updateForm(
                (EvolutionForm x) =>
                    x.copyWith(cirurgiaOp: 'nega cirurgias anteriores'),
              ),
            ),
            Pill(
              label: 'Refere cirurgia(s)',
              selected: f.cirurgiaOp == 'refere',
              onTap: () => p.updateForm(
                (EvolutionForm x) => x.copyWith(cirurgiaOp: 'refere'),
              ),
            ),
          ],
        ),
        if (f.cirurgiaOp == 'refere') ...<Widget>[
          const SizedBox(height: 12),
          AppTextField(
            initialValue: f.cirurgiaTexto,
            hint: 'Ex: colecistectomia videolaparoscópica há 5 anos',
            onChanged: (String v) => p.updateForm(
              (EvolutionForm x) => x.copyWith(cirurgiaTexto: v),
            ),
          ),
        ],
        const SubsectionTitle('Internações Recentes'),
        PillGroup(
          children: <Widget>[
            Pill(
              label: 'Nega internações recentes',
              selected: f.internacoesOp == 'nega internações recentes',
              onTap: () => p.updateForm(
                (EvolutionForm x) =>
                    x.copyWith(internacoesOp: 'nega internações recentes'),
              ),
            ),
            Pill(
              label: 'Refere internação recente',
              selected:
                  f.internacoesOp == 'refere internação recente por',
              onTap: () => p.updateForm(
                (EvolutionForm x) => x.copyWith(
                  internacoesOp: 'refere internação recente por',
                ),
              ),
            ),
          ],
        ),
        if (f.internacoesOp == 'refere internação recente por') ...<Widget>[
          const SizedBox(height: 12),
          AppTextField(
            initialValue: f.internacoesTexto,
            hint: 'Ex: pneumonia há 3 meses',
            onChanged: (String v) => p.updateForm(
              (EvolutionForm x) => x.copyWith(internacoesTexto: v),
            ),
          ),
        ],
      ],
    );
  }
}
