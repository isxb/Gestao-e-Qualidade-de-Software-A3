import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/evolution_form.dart';
import '../../models/infusion.dart';
import '../../providers/evolution_provider.dart';
import '../../widgets/action_button.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/pill_buttons.dart';
import '../../widgets/responsive_grid.dart';
import '../../widgets/section_card.dart';
import '../../widgets/tag_chip.dart';

class StepDevices extends StatefulWidget {
  const StepDevices({super.key});

  @override
  State<StepDevices> createState() => _StepDevicesState();
}

class _StepDevicesState extends State<StepDevices> {
  final TextEditingController _infNome = TextEditingController();
  final TextEditingController _infDet = TextEditingController();

  static const List<Map<String, String>> _dispositivos = <Map<String, String>>[
    <String, String>{'v': 'sonda vesical de demora (SVD)', 'l': 'SVD'},
    <String, String>{'v': 'sonda nasoenteral (SNE)', 'l': 'SNE'},
    <String, String>{'v': 'sonda nasogástrica (SNG)', 'l': 'SNG'},
    <String, String>{'v': 'dreno de tórax', 'l': 'Dreno de tórax'},
    <String, String>{'v': 'dreno de portovac', 'l': 'Dreno Portovac'},
    <String, String>{'v': 'dreno de penrose', 'l': 'Dreno Penrose'},
    <String, String>{'v': 'cateter de O2', 'l': 'Cateter de O2'},
    <String, String>{'v': 'tubo orotraqueal (TOT)', 'l': 'TOT'},
    <String, String>{'v': 'traqueostomia (TQT)', 'l': 'TQT'},
  ];

  @override
  void dispose() {
    _infNome.dispose();
    _infDet.dispose();
    super.dispose();
  }

  void _addInfusion(EvolutionProvider p) {
    if (_infNome.text.trim().isEmpty) return;
    p.addInfusion(
      Infusion(nome: _infNome.text.trim(), detalhe: _infDet.text.trim()),
    );
    _infNome.clear();
    _infDet.clear();
  }

  @override
  Widget build(BuildContext context) {
    final EvolutionProvider p = context.watch<EvolutionProvider>();
    final EvolutionForm f = p.form;
    final bool hasAccess = f.tipoAcesso != 'Sem acesso venoso';

    return SectionCard(
      title: '#Dispositivos',
      subtitle: 'Acessos venosos, drenos e infusões em curso',
      icon: Icons.medication_rounded,
      children: <Widget>[
        const SubsectionTitle('Acesso Venoso', topPadding: 0),
        ResponsiveGrid(
          children: <Widget>[
            LabeledField(
              label: 'Tipo de Acesso',
              child: AppDropdown<String>(
                value: f.tipoAcesso,
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                      value: 'Acesso intravenoso periférico',
                      child: Text('Periférico')),
                  DropdownMenuItem<String>(
                      value: 'Cateter venoso central (CVC)',
                      child: Text('CVC')),
                  DropdownMenuItem<String>(
                    value:
                        'Acesso intravenoso periférico e cateter venoso central',
                    child: Text('Periférico + CVC'),
                  ),
                  DropdownMenuItem<String>(
                      value: 'PICC', child: Text('PICC')),
                  DropdownMenuItem<String>(
                      value: 'Sem acesso venoso',
                      child: Text('Sem acesso')),
                ],
                onChanged: (String? v) => p.setSelect(
                    fieldName: 'tipoAcesso', value: v ?? f.tipoAcesso),
              ),
            ),
            LabeledField(
              label: 'Local do Acesso',
              child: AppTextField(
                initialValue: f.localAcesso,
                enabled: hasAccess,
                hint: 'Ex: membro superior esquerdo (MSE)',
                onChanged: (String v) => p.updateForm(
                  (EvolutionForm x) => x.copyWith(localAcesso: v),
                ),
              ),
            ),
            LabeledField(
              label: 'Calibre do Cateter',
              child: AppTextField(
                initialValue: f.calibreCateter,
                enabled: hasAccess,
                hint: 'Ex: nº 20',
                onChanged: (String v) => p.updateForm(
                  (EvolutionForm x) => x.copyWith(calibreCateter: v),
                ),
              ),
            ),
            LabeledField(
              label: 'Escala de Maddox (Flebite)',
              child: AppDropdown<String>(
                value: f.maddox,
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                    value: '0 (sem sinais flogísticos)',
                    child: Text('0 - Sem sinais'),
                  ),
                  DropdownMenuItem<String>(
                    value: '1 (eritema com ou sem dor)',
                    child: Text('1 - Eritema'),
                  ),
                  DropdownMenuItem<String>(
                    value: '2 (dor, eritema e/ou edema)',
                    child: Text('2 - Dor / Edema'),
                  ),
                  DropdownMenuItem<String>(
                    value: '3 (dor, eritema, cordão fibroso palpável)',
                    child: Text('3 - Cordão fibroso'),
                  ),
                  DropdownMenuItem<String>(
                    value:
                        '4 (dor, eritema, cordão > 2.5cm, drenagem purulenta)',
                    child: Text('4 - Drenagem purulenta'),
                  ),
                ],
                onChanged: (String? v) => p.updateForm(
                  (EvolutionForm x) => x.copyWith(maddox: v ?? x.maddox),
                ),
              ),
            ),
          ],
        ),
        const SubsectionTitle('Outros Dispositivos'),
        PillGroup(
          children: <Widget>[
            for (final Map<String, String> o in _dispositivos)
              Pill(
                label: o['l']!,
                selected: f.outrosDisp.contains(o['v']),
                onTap: () => p.toggleChecklist(
                  fieldName: 'outrosDisp',
                  value: o['v']!,
                ),
              ),
          ],
        ),
        const SubsectionTitle('Infusões Contínuas'),
        if (p.infusions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              children: <Widget>[
                for (int i = 0; i < p.infusions.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TagChip(
                      label: p.infusions[i].display,
                      onRemove: () => p.removeInfusion(i),
                    ),
                  ),
              ],
            ),
          ),
        ResponsiveGrid(
          minItemWidth: 220,
          children: <Widget>[
            LabeledField(
              label: 'Solução / Droga',
              child: TextField(
                controller: _infNome,
                decoration: const InputDecoration(hintText: 'Ex: Noradrenalina'),
              ),
            ),
            LabeledField(
              label: 'Vazão / Detalhes',
              child: TextField(
                controller: _infDet,
                decoration: const InputDecoration(hintText: 'Ex: 10 ml/h'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: ActionButton(
            label: 'Adicionar Infusão',
            icon: Icons.add_rounded,
            kind: ActionButtonKind.secondary,
            onPressed: () => _addInfusion(p),
          ),
        ),
      ],
    );
  }
}
