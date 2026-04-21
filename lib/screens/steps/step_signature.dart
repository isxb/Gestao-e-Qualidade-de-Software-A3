import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/evolution_form.dart';
import '../../providers/evolution_provider.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/responsive_grid.dart';
import '../../widgets/section_card.dart';

class StepSignature extends StatelessWidget {
  const StepSignature({super.key});

  @override
  Widget build(BuildContext context) {
    final EvolutionProvider p = context.watch<EvolutionProvider>();
    final EvolutionForm f = p.form;

    return SectionCard(
      title: 'Identificação Profissional',
      subtitle: 'Assinatura e registro do enfermeiro responsável',
      icon: Icons.verified_user_rounded,
      children: <Widget>[
        const SubsectionTitle('Observações Adicionais', topPadding: 0),
        LabeledField(
          label: 'Intercorrências, orientações ou condutas extras',
          child: AppTextField(
            initialValue: f.obsAdicionais,
            maxLines: 4,
            minLines: 3,
            hint:
                'Ex: Paciente orientado quanto aos riscos de queda. Familiares cientes do quadro clínico...',
            onChanged: (String v) => p.updateForm(
              (EvolutionForm x) => x.copyWith(obsAdicionais: v),
            ),
          ),
        ),
        const SizedBox(height: 22),
        ResponsiveGrid(
          children: <Widget>[
            LabeledField(
              label: 'Nome Completo do Enfermeiro',
              child: AppTextField(
                initialValue: f.enfermeiroNome,
                hint: 'Ex: Thiago Andrade',
                onChanged: (String v) => p.updateForm(
                  (EvolutionForm x) => x.copyWith(enfermeiroNome: v),
                ),
              ),
            ),
            LabeledField(
              label: 'COREN — UF e Número',
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 100,
                    child: AppDropdown<String>(
                      value: f.corenUF,
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem<String>(
                            value: 'RJ', child: Text('RJ')),
                        DropdownMenuItem<String>(
                            value: 'SP', child: Text('SP')),
                        DropdownMenuItem<String>(
                            value: 'MG', child: Text('MG')),
                        DropdownMenuItem<String>(
                            value: 'RS', child: Text('RS')),
                        DropdownMenuItem<String>(
                            value: 'PR', child: Text('PR')),
                        DropdownMenuItem<String>(
                            value: 'SC', child: Text('SC')),
                        DropdownMenuItem<String>(
                            value: 'BA', child: Text('BA')),
                        DropdownMenuItem<String>(
                            value: 'PE', child: Text('PE')),
                        DropdownMenuItem<String>(
                            value: 'CE', child: Text('CE')),
                        DropdownMenuItem<String>(
                            value: 'DF', child: Text('DF')),
                        DropdownMenuItem<String>(
                            value: 'GO', child: Text('GO')),
                        DropdownMenuItem<String>(
                            value: 'ES', child: Text('ES')),
                      ],
                      onChanged: (String? v) => p.updateForm(
                        (EvolutionForm x) =>
                            x.copyWith(corenUF: v ?? x.corenUF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      key: ValueKey<String>('coren-${f.corenUF}'),
                      initialValue: f.corenNumero,
                      decoration: const InputDecoration(hintText: '000.000'),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        _CorenFormatter(),
                      ],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                      onChanged: (String v) => p.updateForm(
                        (EvolutionForm x) => x.copyWith(corenNumero: v),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CorenFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 6) digits = digits.substring(0, 6);
    String formatted = digits;
    if (digits.length > 3) {
      formatted = '${digits.substring(0, 3)}.${digits.substring(3)}';
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
