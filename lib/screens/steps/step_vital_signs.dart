import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/evolution_form.dart';
import '../../providers/evolution_provider.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/responsive_grid.dart';
import '../../widgets/section_card.dart';
import '../../widgets/vital_card.dart';

class StepVitalSigns extends StatelessWidget {
  const StepVitalSigns({super.key});

  @override
  Widget build(BuildContext context) {
    final EvolutionProvider p = context.watch<EvolutionProvider>();
    final EvolutionForm f = p.form;

    return SectionCard(
      title: '#Sinais Vitais',
      subtitle: 'Parâmetros hemodinâmicos e escalas',
      icon: Icons.favorite_rounded,
      children: <Widget>[
        ResponsiveGrid(
          minItemWidth: 160,
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            VitalCard(
              label: 'PRESSÃO ARTERIAL',
              unit: 'mmHg',
              reference: 'ref: <120/80',
              value: f.pa,
              hint: '120x80',
              onChanged: (String v) => p.updateForm(
                (EvolutionForm x) => x.copyWith(pa: v),
              ),
            ),
            VitalCard(
              label: 'FREQ. CARDÍACA',
              unit: 'bpm',
              reference: 'ref: 60–100',
              value: f.fc,
              hint: '75',
              keyboardType: TextInputType.number,
              onChanged: (String v) => p.updateForm(
                (EvolutionForm x) => x.copyWith(fc: v),
              ),
            ),
            VitalCard(
              label: 'FREQ. RESPIRATÓRIA',
              unit: 'irpm',
              reference: 'ref: 12–20',
              value: f.fr,
              hint: '16',
              keyboardType: TextInputType.number,
              onChanged: (String v) => p.updateForm(
                (EvolutionForm x) => x.copyWith(fr: v),
              ),
            ),
            VitalCard(
              label: 'TEMPERATURA',
              unit: '°C',
              reference: 'ref: 36,0–37,5',
              value: f.temp,
              hint: '36.5',
              keyboardType: TextInputType.number,
              onChanged: (String v) => p.updateForm(
                (EvolutionForm x) => x.copyWith(temp: v),
              ),
            ),
            VitalCard(
              label: 'GLICEMIA CAPILAR',
              unit: 'mg/dL',
              reference: 'ref: 70–99',
              value: f.hgt,
              hint: '90',
              keyboardType: TextInputType.number,
              onChanged: (String v) => p.updateForm(
                (EvolutionForm x) => x.copyWith(hgt: v),
              ),
            ),
            VitalCard(
              label: 'SATURAÇÃO O₂',
              unit: '%',
              reference: 'ref: ≥95',
              value: f.sato2,
              hint: '98',
              keyboardType: TextInputType.number,
              onChanged: (String v) => p.updateForm(
                (EvolutionForm x) => x.copyWith(sato2: v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Suporte de O₂',
          child: AppDropdown<String>(
            value: f.o2,
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(
                  value: 'em ar ambiente', child: Text('Ar ambiente')),
              DropdownMenuItem<String>(
                  value: 'em uso de cateter nasal de O2',
                  child: Text('Cateter nasal')),
              DropdownMenuItem<String>(
                  value: 'em uso de máscara de O2',
                  child: Text('Máscara de O2')),
              DropdownMenuItem<String>(
                  value: 'em ventilação mecânica',
                  child: Text('Ventilação mecânica')),
            ],
            onChanged: (String? v) =>
                p.setSelect(fieldName: 'o2', value: v ?? f.o2),
          ),
        ),
        const SubsectionTitle('Avaliação de Dor (EVA)'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: LabeledField(
                label: 'Escala Visual Analógica (0-10)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Slider(
                      value: f.eva.toDouble(),
                      min: 0,
                      max: 10,
                      divisions: 10,
                      label: '${f.eva}',
                      onChanged: (double v) => p.updateForm(
                        (EvolutionForm x) => x.copyWith(eva: v.round()),
                      ),
                    ),
                    Center(
                      child: Text(
                        '${f.eva} / 10',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: LabeledField(
                label: 'Local da Dor',
                child: AppTextField(
                  initialValue: f.locDor,
                  hint: 'Ex: região lombar, precordial...',
                  enabled: f.eva > 0,
                  onChanged: (String v) => p.updateForm(
                    (EvolutionForm x) => x.copyWith(locDor: v),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SubsectionTitle('Escala de Coma de Glasgow'),
        ResponsiveGrid(
          children: <Widget>[
            LabeledField(
              label: 'Abertura Ocular',
              child: AppDropdown<int>(
                value: f.glasgowOcular,
                items: const <DropdownMenuItem<int>>[
                  DropdownMenuItem<int>(
                      value: 4, child: Text('4 - Espontânea')),
                  DropdownMenuItem<int>(value: 3, child: Text('3 - À voz')),
                  DropdownMenuItem<int>(value: 2, child: Text('2 - À dor')),
                  DropdownMenuItem<int>(value: 1, child: Text('1 - Nenhuma')),
                ],
                onChanged: (int? v) => p.updateForm(
                  (EvolutionForm x) =>
                      x.copyWith(glasgowOcular: v ?? x.glasgowOcular),
                ),
              ),
            ),
            LabeledField(
              label: 'Resposta Verbal',
              child: AppDropdown<int>(
                value: f.glasgowVerbal,
                items: const <DropdownMenuItem<int>>[
                  DropdownMenuItem<int>(value: 5, child: Text('5 - Orientada')),
                  DropdownMenuItem<int>(value: 4, child: Text('4 - Confusa')),
                  DropdownMenuItem<int>(
                      value: 3, child: Text('3 - Palavras inapropriadas')),
                  DropdownMenuItem<int>(
                      value: 2, child: Text('2 - Sons incompreensíveis')),
                  DropdownMenuItem<int>(value: 1, child: Text('1 - Nenhuma')),
                  DropdownMenuItem<int>(
                      value: 0, child: Text('T - Tubo/Traqueostomia')),
                ],
                onChanged: (int? v) => p.updateForm(
                  (EvolutionForm x) =>
                      x.copyWith(glasgowVerbal: v ?? x.glasgowVerbal),
                ),
              ),
            ),
            LabeledField(
              label: 'Resposta Motora',
              child: AppDropdown<int>(
                value: f.glasgowMotor,
                items: const <DropdownMenuItem<int>>[
                  DropdownMenuItem<int>(
                      value: 6, child: Text('6 - Obedece a comandos')),
                  DropdownMenuItem<int>(
                      value: 5, child: Text('5 - Localiza a dor')),
                  DropdownMenuItem<int>(
                      value: 4, child: Text('4 - Flexão normal (retirada)')),
                  DropdownMenuItem<int>(
                      value: 3, child: Text('3 - Flexão anormal (decorticação)')),
                  DropdownMenuItem<int>(
                      value: 2,
                      child: Text('2 - Extensão anormal (descerebração)')),
                  DropdownMenuItem<int>(value: 1, child: Text('1 - Nenhuma')),
                ],
                onChanged: (int? v) => p.updateForm(
                  (EvolutionForm x) =>
                      x.copyWith(glasgowMotor: v ?? x.glasgowMotor),
                ),
              ),
            ),
            LabeledField(
              label: 'Resposta Pupilar',
              child: AppDropdown<int>(
                value: f.glasgowPupilar,
                items: const <DropdownMenuItem<int>>[
                  DropdownMenuItem<int>(
                      value: 0, child: Text('0 - Bilateral (Reagem)')),
                  DropdownMenuItem<int>(
                      value: 1, child: Text('1 - Unilateral')),
                  DropdownMenuItem<int>(value: 2, child: Text('2 - Nenhuma')),
                ],
                onChanged: (int? v) => p.updateForm(
                  (EvolutionForm x) =>
                      x.copyWith(glasgowPupilar: v ?? x.glasgowPupilar),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.calculate_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Total Glasgow: ${f.glasgowTotal}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
