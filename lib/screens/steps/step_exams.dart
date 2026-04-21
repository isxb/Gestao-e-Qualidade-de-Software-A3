import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/evolution_form.dart';
import '../../providers/evolution_provider.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/pill_buttons.dart';
import '../../widgets/section_card.dart';

class StepExams extends StatelessWidget {
  const StepExams({super.key});

  static const List<Map<String, String>> _realizados = <Map<String, String>>[
    <String, String>{
      'v': 'eletrocardiograma de 12 derivações',
      'l': 'ECG 12 derivações'
    },
    <String, String>{'v': 'radiografia de tórax em AP', 'l': 'Rx tórax AP'},
    <String, String>{'v': 'ecocardiograma', 'l': 'Ecocardiograma'},
    <String, String>{'v': 'tomografia de tórax', 'l': 'TC tórax'},
    <String, String>{'v': 'tomografia de crânio', 'l': 'TC crânio'},
    <String, String>{'v': 'ultrassonografia abdominal', 'l': 'USG abdome'},
    <String, String>{'v': 'gasometria arterial', 'l': 'Gasometria arterial'},
  ];

  static const List<Map<String, String>> _coletas = <Map<String, String>>[
    <String, String>{'v': 'hemograma completo', 'l': 'Hemograma'},
    <String, String>{'v': 'eletrólitos (Na, K, Mg, Ca)', 'l': 'Eletrólitos'},
    <String, String>{
      'v': 'função renal (ureia, creatinina)',
      'l': 'Função Renal'
    },
    <String, String>{
      'v': 'marcadores de necrose miocárdica',
      'l': 'Marcadores Cardíacos'
    },
    <String, String>{'v': 'coagulograma', 'l': 'Coagulograma'},
    <String, String>{
      'v': 'culturas (sangue, urina, secreção)',
      'l': 'Culturas'
    },
    <String, String>{'v': 'PCR / VHS', 'l': 'Provas Inflamatórias'},
  ];

  static const List<Map<String, String>> _resOptions = <Map<String, String>>[
    <String, String>{
      'v': 'resultados pendentes, aguardando processamento pelo laboratório',
      'l': 'Pendentes',
    },
    <String, String>{
      'v': 'resultados laboratoriais sem alterações significativas',
      'l': 'Sem alterações',
    },
    <String, String>{
      'v': 'resultados com alterações',
      'l': 'Com alterações',
    },
    <String, String>{'v': 'não realizados', 'l': 'Não realizados'},
  ];

  @override
  Widget build(BuildContext context) {
    final EvolutionProvider p = context.watch<EvolutionProvider>();
    final EvolutionForm f = p.form;

    return SectionCard(
      title: '#Exames',
      subtitle: 'Exames realizados e aguardando resultados',
      icon: Icons.biotech_rounded,
      children: <Widget>[
        const SubsectionTitle('Exames Realizados / Conferidos', topPadding: 0),
        PillGroup(
          children: <Widget>[
            for (final Map<String, String> o in _realizados)
              Pill(
                label: o['l']!,
                selected: f.examesRealizados.contains(o['v']),
                onTap: () => p.toggleChecklist(
                  fieldName: 'examesRealizados',
                  value: o['v']!,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        LabeledField(
          label: 'Achados Relevantes dos Exames de Imagem/Gráficos',
          child: AppTextField(
            initialValue: f.achadosExames,
            hint: 'Ex: Rx de tórax com infiltrado em base direita...',
            maxLines: 3,
            minLines: 2,
            onChanged: (String v) => p.updateForm(
              (EvolutionForm x) => x.copyWith(achadosExames: v),
            ),
          ),
        ),
        const SubsectionTitle('Exames Laboratoriais'),
        Text(
          'Coletas Realizadas',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 8),
        PillGroup(
          children: <Widget>[
            for (final Map<String, String> o in _coletas)
              Pill(
                label: o['l']!,
                selected: f.coletas.contains(o['v']),
                onTap: () => p.toggleChecklist(
                  fieldName: 'coletas',
                  value: o['v']!,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Status dos Resultados',
          child: PillGroup(
            children: <Widget>[
              for (final Map<String, String> o in _resOptions)
                Pill(
                  label: o['l']!,
                  selected: f.resLab == o['v'],
                  onTap: () => p.updateForm(
                    (EvolutionForm x) => x.copyWith(resLab: o['v']),
                  ),
                ),
            ],
          ),
        ),
        if (f.resLab == 'resultados com alterações') ...<Widget>[
          const SizedBox(height: 14),
          LabeledField(
            label: 'Descrever Alterações Laboratoriais',
            child: AppTextField(
              initialValue: f.obsLab,
              hint: 'Ex: Leucocitose (15.000), PCR elevado (120)...',
              maxLines: 3,
              minLines: 2,
              onChanged: (String v) => p.updateForm(
                (EvolutionForm x) => x.copyWith(obsLab: v),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
