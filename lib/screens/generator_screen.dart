import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/evolution_provider.dart';
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
