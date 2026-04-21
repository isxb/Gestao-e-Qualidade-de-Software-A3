import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/evolution_form.dart';
import '../../providers/evolution_provider.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/responsive_grid.dart';
import '../../widgets/section_card.dart';

class StepPhysicalExam extends StatelessWidget {
  const StepPhysicalExam({super.key});

  @override
  Widget build(BuildContext context) {
    final EvolutionProvider p = context.watch<EvolutionProvider>();
    final EvolutionForm f = p.form;

    return SectionCard(
      title: '#HDA — Exame Físico',
      subtitle: 'Avaliação dos sistemas orgânicos',
      icon: Icons.monitor_heart_rounded,
      children: <Widget>[
        const SubsectionTitle('Sistema Respiratório', topPadding: 0),
        ResponsiveGrid(
          children: <Widget>[
            LabeledField(
              label: 'Padrão Respiratório',
              child: AppDropdown<String>(
                value: f.padResp,
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                      value: 'eupneico', child: Text('Eupneico')),
                  DropdownMenuItem<String>(
                      value: 'dispneico', child: Text('Dispneico')),
                  DropdownMenuItem<String>(
                      value: 'taquidispneico',
                      child: Text('Taquidispneico')),
                  DropdownMenuItem<String>(
                    value: 'em uso de ventilação mecânica invasiva',
                    child: Text('VM Invasiva'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'em uso de ventilação não invasiva',
                    child: Text('VNI'),
                  ),
                ],
                onChanged: (String? v) => p.setSelect(
                  fieldName: 'padResp',
                  value: v ?? f.padResp,
                ),
              ),
            ),
            LabeledField(
              label: 'Expansibilidade Torácica',
              child: AppDropdown<String>(
                value: f.expTor,
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                      value: 'preservada', child: Text('Preservada')),
                  DropdownMenuItem<String>(
                      value: 'diminuída bilateralmente',
                      child: Text('Diminuída bilateralmente')),
                  DropdownMenuItem<String>(
                      value: 'diminuída à direita',
                      child: Text('Diminuída à direita')),
                  DropdownMenuItem<String>(
                      value: 'diminuída à esquerda',
                      child: Text('Diminuída à esquerda')),
                ],
                onChanged: (String? v) => p.updateForm(
                  (EvolutionForm x) => x.copyWith(expTor: v ?? x.expTor),
                ),
              ),
            ),
            LabeledField(
              label: 'Murmúrio Vesicular',
              child: AppDropdown<String>(
                value: f.mv,
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                    value:
                        'presentes e distribuídos em ambos os hemitórax, sem ruídos adventícios',
                    child: Text('Presente, sem ruídos'),
                  ),
                  DropdownMenuItem<String>(
                      value: 'diminuídos globalmente',
                      child: Text('Diminuído globalmente')),
                  DropdownMenuItem<String>(
                      value: 'com estertores crepitantes',
                      child: Text('Com estertores crepitantes')),
                  DropdownMenuItem<String>(
                      value: 'com roncos', child: Text('Com roncos')),
                  DropdownMenuItem<String>(
                      value: 'com sibilos', child: Text('Com sibilos')),
                ],
                onChanged: (String? v) => p.updateForm(
                  (EvolutionForm x) => x.copyWith(mv: v ?? x.mv),
                ),
              ),
            ),
          ],
        ),
        const SubsectionTitle('Sistema Cardiovascular'),
        ResponsiveGrid(
          children: <Widget>[
            LabeledField(
              label: 'Ritmo Cardíaco',
              child: AppDropdown<String>(
                value: f.ritmo,
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                    value: 'regular em dois tempos com bulhas normofonéticas',
                    child: Text('Regular, normofonético'),
                  ),
                  DropdownMenuItem<String>(
                      value: 'irregular', child: Text('Irregular')),
                  DropdownMenuItem<String>(
                      value: 'hipofonético', child: Text('Hipofonético')),
                ],
                onChanged: (String? v) => p.updateForm(
                  (EvolutionForm x) => x.copyWith(ritmo: v ?? x.ritmo),
                ),
              ),
            ),
            LabeledField(
              label: 'Perfusão Periférica',
              child: AppDropdown<String>(
                value: f.perf,
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                    value:
                        'perfusão periférica preservada com TEC inferior a 2 segundos',
                    child: Text('Preservada (TEC < 2s)'),
                  ),
                  DropdownMenuItem<String>(
                    value:
                        'perfusão periférica lentificada com TEC superior a 2 segundos',
                    child: Text('Lentificada (TEC > 2s)'),
                  ),
                ],
                onChanged: (String? v) => p.updateForm(
                  (EvolutionForm x) => x.copyWith(perf: v ?? x.perf),
                ),
              ),
            ),
          ],
        ),
        const SubsectionTitle('Abdome e Trato Gastrointestinal'),
        ResponsiveGrid(
          children: <Widget>[
            LabeledField(
              label: 'Inspeção',
              child: AppDropdown<String>(
                value: f.abdInsp,
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(value: 'plano', child: Text('Plano')),
                  DropdownMenuItem<String>(
                      value: 'globoso', child: Text('Globoso')),
                  DropdownMenuItem<String>(
                      value: 'distendido', child: Text('Distendido')),
                  DropdownMenuItem<String>(
                      value: 'escavado', child: Text('Escavado')),
                ],
                onChanged: (String? v) => p.updateForm(
                  (EvolutionForm x) => x.copyWith(abdInsp: v ?? x.abdInsp),
                ),
              ),
            ),
            LabeledField(
              label: 'Palpação',
              child: AppDropdown<String>(
                value: f.abdPalp,
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                    value: 'flácido e indolor à palpação superficial e profunda',
                    child: Text('Flácido e indolor'),
                  ),
                  DropdownMenuItem<String>(
                      value: 'doloroso à palpação', child: Text('Doloroso')),
                  DropdownMenuItem<String>(
                      value: 'com defesa voluntária',
                      child: Text('Com defesa')),
                  DropdownMenuItem<String>(
                    value: 'com sinais de irritação peritoneal',
                    child: Text('Irritação peritoneal'),
                  ),
                ],
                onChanged: (String? v) => p.updateForm(
                  (EvolutionForm x) => x.copyWith(abdPalp: v ?? x.abdPalp),
                ),
              ),
            ),
            LabeledField(
              label: 'Ruídos Hidroaéreos (RHA)',
              child: AppDropdown<String>(
                value: f.rha,
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                      value: 'presentes em todos os quadrantes',
                      child: Text('Presentes')),
                  DropdownMenuItem<String>(
                      value: 'ausentes', child: Text('Ausentes')),
                  DropdownMenuItem<String>(
                      value: 'hipoativos', child: Text('Hipoativos')),
                  DropdownMenuItem<String>(
                      value: 'hiperativos', child: Text('Hiperativos')),
                ],
                onChanged: (String? v) => p.updateForm(
                  (EvolutionForm x) => x.copyWith(rha: v ?? x.rha),
                ),
              ),
            ),
          ],
        ),
        const SubsectionTitle('Sistema Geniturinário'),
        LabeledField(
          label: 'Diurese',
          child: AppDropdown<String>(
            value: f.diurese,
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(
                  value: 'diurese espontânea de aspecto citrino',
                  child: Text('Espontânea, citrina')),
              DropdownMenuItem<String>(
                value:
                    'diurese via sonda vesical de demora, aspecto citrino',
                child: Text('SVD, citrina'),
              ),
              DropdownMenuItem<String>(
                  value: 'diurese concentrada', child: Text('Concentrada')),
              DropdownMenuItem<String>(
                  value: 'hematúria', child: Text('Hematúria')),
              DropdownMenuItem<String>(
                  value: 'anúria', child: Text('Anúria')),
            ],
            onChanged: (String? v) => p.updateForm(
              (EvolutionForm x) => x.copyWith(diurese: v ?? x.diurese),
            ),
          ),
        ),
        const SubsectionTitle('Sistema Neurológico'),
        ResponsiveGrid(
          children: <Widget>[
            LabeledField(
              label: 'Déficit Motor/Sensitivo',
              child: AppDropdown<String>(
                value: f.defNeuro,
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                      value: 'sem déficits motores ou sensitivos focais',
                      child: Text('Sem déficits focais')),
                  DropdownMenuItem<String>(
                      value: 'com hemiparesia à direita',
                      child: Text('Hemiparesia à direita')),
                  DropdownMenuItem<String>(
                      value: 'com hemiparesia à esquerda',
                      child: Text('Hemiparesia à esquerda')),
                  DropdownMenuItem<String>(
                      value: 'com plegia', child: Text('Plegia')),
                ],
                onChanged: (String? v) => p.updateForm(
                  (EvolutionForm x) => x.copyWith(defNeuro: v ?? x.defNeuro),
                ),
              ),
            ),
            LabeledField(
              label: 'Pupilas',
              child: AppDropdown<String>(
                value: f.pupilas,
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                      value: 'isocóricas e fotorreagentes',
                      child: Text('Isocóricas e fotorreagentes')),
                  DropdownMenuItem<String>(
                      value: 'anisocóricas', child: Text('Anisocóricas')),
                  DropdownMenuItem<String>(
                      value: 'midriáticas', child: Text('Midriáticas')),
                  DropdownMenuItem<String>(
                      value: 'mióticas', child: Text('Mióticas')),
                ],
                onChanged: (String? v) => p.updateForm(
                  (EvolutionForm x) => x.copyWith(pupilas: v ?? x.pupilas),
                ),
              ),
            ),
            LabeledField(
              label: 'Escala de RASS',
              child: AppDropdown<String>(
                value: f.rass,
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                      value: '+4 (combativo)', child: Text('+4 Combativo')),
                  DropdownMenuItem<String>(
                      value: '+3 (muito agitado)',
                      child: Text('+3 Muito agitado')),
                  DropdownMenuItem<String>(
                      value: '+2 (agitado)', child: Text('+2 Agitado')),
                  DropdownMenuItem<String>(
                      value: '+1 (inquieto)', child: Text('+1 Inquieto')),
                  DropdownMenuItem<String>(
                      value: '0 (alerta e calmo)',
                      child: Text('0 Alerta e calmo')),
                  DropdownMenuItem<String>(
                      value: '-1 (sonolento)', child: Text('-1 Sonolento')),
                  DropdownMenuItem<String>(
                      value: '-2 (sedação leve)',
                      child: Text('-2 Sedação leve')),
                  DropdownMenuItem<String>(
                      value: '-3 (sedação moderada)',
                      child: Text('-3 Sedação moderada')),
                  DropdownMenuItem<String>(
                      value: '-4 (sedação intensa)',
                      child: Text('-4 Sedação intensa')),
                  DropdownMenuItem<String>(
                      value: '-5 (não desperta)',
                      child: Text('-5 Não desperta')),
                ],
                onChanged: (String? v) => p.updateForm(
                  (EvolutionForm x) => x.copyWith(rass: v ?? x.rass),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
