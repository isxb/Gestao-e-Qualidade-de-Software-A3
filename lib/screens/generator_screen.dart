import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/evolution_template.dart';
import '../providers/evolution_provider.dart';
import '../providers/template_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/action_button.dart';
import '../widgets/app_header.dart';
import '../widgets/progress_stepper.dart';
import 'steps/step_admission.dart';
import 'steps/step_devices.dart';
import 'steps/step_exams.dart';
import 'steps/step_hpp.dart';
import 'steps/step_output.dart';
import 'steps/step_physical_exam.dart';
import 'steps/step_signature.dart';
import 'steps/step_skin.dart';
import 'steps/step_vital_signs.dart';

class GeneratorScreen extends StatelessWidget {
  const GeneratorScreen({super.key});

  static const List<String> _labels = <String>[
    'Admissão',
    'HPP',
    'Exame Físico',
    'Sinais Vitais',
    'Pele',
    'Dispositivos',
    'Exames',
    'Assinatura',
    'Gerar',
  ];

  @override
  Widget build(BuildContext context) {
    final int step = context.watch<EvolutionProvider>().currentStep;

    return Scaffold(
      appBar: AppHeader(
        showHomeButton: true,
        onHomeTap: () =>
            Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst),
      ),
      body: Column(
        children: <Widget>[
          ProgressStepper(
            labels: _labels,
            currentStep: step,
            onStepTap: (int i) => context.read<EvolutionProvider>().setStep(i),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppTheme.contentMaxWidth(context),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.horizontalPadding(context),
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (step == 0) ...<Widget>[
                        _TemplateBanner(),
                        const SizedBox(height: 12),
                      ],
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        transitionBuilder:
                            (Widget child, Animation<double> a) {
                          return FadeTransition(
                            opacity: a,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.04),
                                end: Offset.zero,
                              ).animate(a),
                              child: child,
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey<int>(step),
                          child: _StepContent(step: step),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _NavButtons(step: step),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepContent extends StatelessWidget {
  const _StepContent({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    switch (step) {
      case 0:
        return const StepAdmission();
      case 1:
        return const StepHpp();
      case 2:
        return const StepPhysicalExam();
      case 3:
        return const StepVitalSigns();
      case 4:
        return const StepSkin();
      case 5:
        return const StepDevices();
      case 6:
        return const StepExams();
      case 7:
        return const StepSignature();
      case 8:
        return const StepOutput();
      default:
        return const SizedBox.shrink();
    }
  }
}

/// Faixa exibida no passo 0 quando o usuário possui templates cadastrados.
/// Permite carregar um template com um toque para pré-preencher o formulário.
class _TemplateBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final TemplateProvider tProv = context.watch<TemplateProvider>();
    if (!tProv.hasTemplates) return const SizedBox.shrink();

    final ThemeData theme = Theme.of(context);
    return Material(
      color: AppColors.indigoLight,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        onTap: () => _showPicker(context, tProv),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: <Widget>[
              const Icon(Icons.auto_fix_high_rounded,
                  color: AppColors.indigo, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Carregar template',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.indigoDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.expand_more_rounded,
                  color: AppColors.indigo, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPicker(
      BuildContext context, TemplateProvider tProv) async {
    final EvolutionTemplate? chosen = await showModalBottomSheet<EvolutionTemplate>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) => _TemplatePicker(templates: tProv.templates),
    );
    if (chosen == null || !context.mounted) return;

    final EvolutionProvider evoProv = context.read<EvolutionProvider>();
    final TemplateProvider tp = context.read<TemplateProvider>();
    final dynamic newForm = await tp.applyTemplate(
      templateId: chosen.id,
      currentForm: evoProv.form,
    );
    evoProv.updateForm((_) => newForm);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Template "${chosen.name}" aplicado.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

class _TemplatePicker extends StatelessWidget {
  const _TemplatePicker({required this.templates});
  final List<EvolutionTemplate> templates;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      maxChildSize: 0.85,
      builder: (BuildContext ctx, ScrollController sc) => Column(
        children: <Widget>[
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Escolha um template',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              controller: sc,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: templates.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (BuildContext _, int i) {
                final EvolutionTemplate t = templates[i];
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.indigoLight),
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.indigoLight,
                    child: Icon(Icons.bookmark_rounded,
                        color: AppColors.indigo, size: 20),
                  ),
                  title: Text(t.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: t.description.isNotEmpty
                      ? Text(t.description, maxLines: 1,
                          overflow: TextOverflow.ellipsis)
                      : Text('${t.setor}  ·  ${t.tipoAcesso}',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).pop(t),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _NavButtons extends StatelessWidget {
  const _NavButtons({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    // context.read é seguro aqui pois só é chamado dentro de callbacks (onPressed),
    // nunca durante o build tree. Garantido pelos closures abaixo.
    if (step == 8) return const SizedBox.shrink();

    final bool isLast = step == 7;

    return Row(
      children: <Widget>[
        if (step > 0)
          ActionButton(
            label: 'Anterior',
            kind: ActionButtonKind.secondary,
            icon: Icons.arrow_back_rounded,
            onPressed: () => context.read<EvolutionProvider>().previous(),
          ),
        const Spacer(),
        Text(
          'Passo ${step + 1} de 9',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const Spacer(),
        if (!isLast)
          ActionButton(
            label: 'Próximo',
            kind: ActionButtonKind.primary,
            icon: Icons.arrow_forward_rounded,
            onPressed: () => context.read<EvolutionProvider>().next(),
          )
        else
          ActionButton(
            label: 'Gerar Evolução',
            kind: ActionButtonKind.success,
            icon: Icons.auto_awesome_rounded,
            onPressed: () => context.read<EvolutionProvider>().gerarEvolucao(),
          ),
      ],
    );
  }
}
