import 'package:flutter/material.dart';

/// Barra de passos horizontal, rolável, totalmente clicável.
class ProgressStepper extends StatefulWidget {
  const ProgressStepper({
    super.key,
    required this.labels,
    required this.currentStep,
    required this.onStepTap,
  });

  final List<String> labels;
  final int currentStep;
  final ValueChanged<int> onStepTap;

  @override
  State<ProgressStepper> createState() => _ProgressStepperState();
}

class _ProgressStepperState extends State<ProgressStepper> {
  final ScrollController _controller = ScrollController();

  @override
  void didUpdateWidget(covariant ProgressStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _centerActive());
    }
  }

  void _centerActive() {
    if (!_controller.hasClients) return;
    const double approxWidth = 140;
    final double target = widget.currentStep * approxWidth;
    _controller.animateTo(
      target.clamp(0.0, _controller.position.maxScrollExtent),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: List<Widget>.generate(widget.labels.length, (int i) {
            final bool active = i == widget.currentStep;
            final bool done = i < widget.currentStep;
            final Color fg = active
                ? scheme.primary
                : done
                    ? scheme.primary.withValues(alpha: 0.8)
                    : scheme.onSurface.withValues(alpha: 0.55);
            final Color bg = active
                ? scheme.primary.withValues(alpha: 0.12)
                : Colors.transparent;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => widget.onStepTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: active
                          ? scheme.primary.withValues(alpha: 0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done
                              ? scheme.primary
                              : active
                                  ? scheme.primary.withValues(alpha: 0.2)
                                  : scheme.surfaceContainerHighest,
                        ),
                        child: done
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 13,
                              )
                            : Text(
                                i == widget.labels.length - 1
                                    ? '✦'
                                    : '${i + 1}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: fg,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.labels[i],
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(
                              color: fg,
                              fontSize: 13,
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
