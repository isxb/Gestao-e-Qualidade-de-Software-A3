import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/evolution_form.dart';
import '../../providers/evolution_provider.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/pill_buttons.dart';
import '../../widgets/responsive_grid.dart';
import '../../widgets/section_card.dart';

class StepAdmission extends StatelessWidget {
  const StepAdmission({super.key});

  static const List<Map<String, String>> _consciencia = <Map<String, String>>[
    <String, String>{
      'v': 'consciente e orientado em tempo e espaço',
      'l': 'Consciente e orientado',
    },
    <String, String>{
      'v': 'consciente, porém desorientado',
      'l': 'Desorientado',
    },
    <String, String>{
      'v': 'com rebaixamento do nível de consciência',
      'l': 'Rebaixado',
    },
    <String, String>{'v': 'inconsciente', 'l': 'Inconsciente'},
  ];

  static const List<Map<String, String>> _aspectos = <Map<String, String>>[
    <String, String>{'v': 'calmo', 'l': 'Calmo'},
    <String, String>{'v': 'agitado', 'l': 'Agitado'},
    <String, String>{'v': 'ansioso', 'l': 'Ansioso'},
    <String, String>{'v': 'com dor', 'l': 'Com dor'},
    <String, String>{'v': 'hipocorado', 'l': 'Hipocorado'},
    <String, String>{'v': 'cianótico', 'l': 'Cianótico'},
    <String, String>{'v': 'ictérico', 'l': 'Ictérico'},
    <String, String>{'v': 'sudoreico', 'l': 'Sudoreico'},
  ];

  @override
  Widget build(BuildContext context) {
    final EvolutionProvider p = context.watch<EvolutionProvider>();
    final EvolutionForm f = p.form;

    return SectionCard(
      title: 'Dados de Admissão',
      subtitle: 'Identificação do paciente e motivo da internação',
      icon: Icons.local_hospital_rounded,
      children: <Widget>[
        ResponsiveGrid(
          children: <Widget>[
            LabeledField(
              label: 'Iniciais do Paciente',
              child: AppTextField(
                initialValue: f.pacienteNome,
                hint: 'Ex: J.M.S.',
                maxLength: 20,
                onChanged: (String v) => p.updateForm(
                  (EvolutionForm x) => x.copyWith(pacienteNome: v),
                ),
              ),
            ),
            LabeledField(
              label: 'Idade (anos)',
              child: AppTextField(
                initialValue: f.pacienteIdade,
                hint: '72',
                keyboardType: TextInputType.number,
                onChanged: (String v) => p.updateForm(
                  (EvolutionForm x) => x.copyWith(pacienteIdade: v),
                ),
              ),
            ),
            LabeledField(
              label: 'Setor de Destino',
              child: AppDropdown<String>(
                value: f.setor,
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                    value: 'unidade de terapia intensiva',
                    child: Text('UTI'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'unidade de internação',
                    child: Text('Internação'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'unidade semi-intensiva',
                    child: Text('Semi-intensiva'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'pronto-socorro',
                    child: Text('Pronto-socorro'),
                  ),
                ],
                onChanged: (String? v) => p.updateForm(
                  (EvolutionForm x) => x.copyWith(setor: v ?? x.setor),
                ),
              ),
            ),
            LabeledField(
              label: 'Setor de Origem',
              child: AppDropdown<String>(
                value: f.origem,
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                    value: 'unidade de emergência',
                    child: Text('Emergência'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'bloco cirúrgico',
                    child: Text('Bloco cirúrgico'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'pronto-socorro',
                    child: Text('Pronto-socorro'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'outra unidade hospitalar',
                    child: Text('Transferência inter-hospitalar'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'domicílio',
                    child: Text('Domicílio'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'ambulatório',
                    child: Text('Ambulatório'),
                  ),
                ],
                onChanged: (String? v) => p.updateForm(
                  (EvolutionForm x) => x.copyWith(origem: v ?? x.origem),
                ),
              ),
            ),
            LabeledField(
              label: 'Data de Admissão',
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  final DateTime initial =
                      DateTime.tryParse(f.dataAdmissao) ?? DateTime.now();
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    locale: const Locale('pt', 'BR'),
                  );
                  if (picked != null) {
                    p.updateForm(
                      (EvolutionForm x) => x.copyWith(
                        dataAdmissao: DateFormat('yyyy-MM-dd').format(picked),
                      ),
                    );
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(),
                  child: Text(
                    _formatDate(f.dataAdmissao),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
            LabeledField(
              label: 'Horário de Admissão',
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  final List<String> parts = f.horaAdmissao.split(':');
                  final TimeOfDay initial = TimeOfDay(
                    hour: int.tryParse(parts.first) ?? 0,
                    minute: parts.length > 1
                        ? int.tryParse(parts[1]) ?? 0
                        : 0,
                  );
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: initial,
                    builder: (BuildContext ctx, Widget? child) =>
                        MediaQuery(
                      data: MediaQuery.of(ctx).copyWith(
                        alwaysUse24HourFormat: true,
                      ),
                      child: child ?? const SizedBox.shrink(),
                    ),
                  );
                  if (picked != null) {
                    final String hh =
                        picked.hour.toString().padLeft(2, '0');
                    final String mm =
                        picked.minute.toString().padLeft(2, '0');
                    p.updateForm(
                      (EvolutionForm x) =>
                          x.copyWith(horaAdmissao: '$hh:$mm'),
                    );
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(),
                  child: Text(
                    f.horaAdmissao,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SubsectionTitle('Queixa Principal'),
        LabeledField(
          label: 'Descrição da Queixa Principal',
          child: AppTextField(
            initialValue: f.queixaPrincipal,
            maxLines: 4,
            minLines: 3,
            hint:
                'Ex: dor precordial súbita de caráter opressivo com irradiação para membro superior esquerdo...',
            onChanged: (String v) => p.updateForm(
              (EvolutionForm x) => x.copyWith(queixaPrincipal: v),
            ),
          ),
        ),
        const SizedBox(height: 14),
        ResponsiveGrid(
          children: <Widget>[
            LabeledField(
              label: 'Modo de Transporte',
              child: AppDropdown<String>(
                value: f.transporte,
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                    value: 'maca com monitorização cardíaca contínua',
                    child: Text('Maca c/ monitorização cardíaca'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'cadeira de rodas',
                    child: Text('Cadeira de rodas'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'deambulando',
                    child: Text('Deambulando'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'maca',
                    child: Text('Maca'),
                  ),
                ],
                onChanged: (String? v) => p.updateForm(
                  (EvolutionForm x) =>
                      x.copyWith(transporte: v ?? x.transporte),
                ),
              ),
            ),
            LabeledField(
              label: 'Suporte durante transporte',
              child: AppDropdown<String>(
                value: f.suporteTransporte,
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                    value: 'oxigenoterapia suplementar via cateter nasal',
                    child: Text('O₂ via cateter nasal'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'oxigenoterapia via máscara facial',
                    child: Text('O₂ via máscara'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'oxigenoterapia via máscara não reinalante',
                    child: Text('O₂ máscara não reinalante'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'ventilação mecânica invasiva',
                    child: Text('Ventilação mecânica'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'sem suporte respiratório',
                    child: Text('Sem suporte respiratório'),
                  ),
                ],
                onChanged: (String? v) => p.updateForm(
                  (EvolutionForm x) => x.copyWith(
                    suporteTransporte: v ?? x.suporteTransporte,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SubsectionTitle('Estado na Admissão'),
        LabeledField(
          label: 'Nível de Consciência',
          child: PillGroup(
            children: <Widget>[
              for (final Map<String, String> opt in _consciencia)
                Pill(
                  label: opt['l']!,
                  selected: f.consciencia == opt['v'],
                  onTap: () => p.updateForm(
                    (EvolutionForm x) =>
                        x.copyWith(consciencia: opt['v']),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Aspectos na Admissão',
          child: PillGroup(
            children: <Widget>[
              for (final Map<String, String> opt in _aspectos)
                Pill(
                  label: opt['l']!,
                  selected: f.aspectosAdmissao.contains(opt['v']),
                  onTap: () => p.toggleChecklist(
                    fieldName: 'aspectosAdmissao',
                    value: opt['v']!,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String iso) {
    try {
      final DateTime d = DateTime.parse(iso);
      return DateFormat('dd/MM/yyyy').format(d);
    } catch (_) {
      return iso;
    }
  }
}
