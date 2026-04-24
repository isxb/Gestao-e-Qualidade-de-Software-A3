import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/evolution_provider.dart';
import '../../utils/markdown_bold.dart';
import '../../widgets/action_button.dart';

class StepOutput extends StatefulWidget {
  const StepOutput({super.key});

  @override
  State<StepOutput> createState() => _StepOutputState();
}

class _StepOutputState extends State<StepOutput> {
  bool _saved = false;

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Texto copiado para a área de transferência.'),
      ),
    );
  }

  Future<void> _save(EvolutionProvider p) async {
    await p.saveCurrentEvolution();
    if (!mounted) return;
    setState(() => _saved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Evolução salva no banco de dados.')),
    );
  }

  void _newEvolution(EvolutionProvider p) {
    p.startNewEvolution();
    setState(() => _saved = false);
  }

  @override
  Widget build(BuildContext context) {
    final EvolutionProvider p = context.watch<EvolutionProvider>();

    switch (p.status) {
      case GenerationStatus.loading:
        return const _LoadingState();
      case GenerationStatus.error:
        return _ErrorState(
          message: p.errorMessage ?? 'Erro desconhecido.',
          onRetry: () => p.gerarEvolucao(),
          onBack: p.previous,
        );
      case GenerationStatus.success:
        return _SuccessState(
          text: p.generatedText,
          saved: _saved,
          onCopy: () => _copy(p.generatedText),
          onSave: () => _save(p),
          onEdit: () => p.setStep(7),
          onNew: () => _newEvolution(p),
          onTextChanged: (String v) => p.setGeneratedText(v),
        );
      case GenerationStatus.idle:
        return _IdleState(onGenerate: () => p.gerarEvolucao());
    }
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 20),
        child: Column(
          children: <Widget>[
            const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(strokeWidth: 3.4),
            ),
            const SizedBox(height: 24),
            Text(
              'Gerando evolução...',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'O sistema está processando os dados e formatando a evolução de acordo com as normas da instituição.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.error_outline_rounded,
                    color: scheme.error, size: 26),
                const SizedBox(width: 10),
                Text(
                  'Falha ao gerar evolução',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: scheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: scheme.error.withValues(alpha: 0.3)),
              ),
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ActionButton(
                  label: 'Voltar',
                  kind: ActionButtonKind.secondary,
                  icon: Icons.arrow_back_rounded,
                  onPressed: onBack,
                ),
                ActionButton(
                  label: 'Tentar Novamente',
                  kind: ActionButtonKind.primary,
                  icon: Icons.refresh_rounded,
                  onPressed: onRetry,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IdleState extends StatelessWidget {
  const _IdleState({required this.onGenerate});

  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 20),
        child: Column(
          children: <Widget>[
            Icon(
              Icons.auto_awesome_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Pronto para gerar',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Clique no botão abaixo para gerar a evolução de enfermagem baseada no formulário.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 22),
            ActionButton(
              label: 'Gerar Evolução',
              kind: ActionButtonKind.success,
              icon: Icons.auto_awesome_rounded,
              onPressed: onGenerate,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessState extends StatefulWidget {
  const _SuccessState({
    required this.text,
    required this.saved,
    required this.onCopy,
    required this.onSave,
    required this.onEdit,
    required this.onNew,
    required this.onTextChanged,
  });

  final String text;
  final bool saved;
  final VoidCallback onCopy;
  final VoidCallback onSave;
  final VoidCallback onEdit;
  final VoidCallback onNew;
  final ValueChanged<String> onTextChanged;

  @override
  State<_SuccessState> createState() => _SuccessStateState();
}

class _SuccessStateState extends State<_SuccessState> {
  bool _editing = false;
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.text);
  }

  @override
  void didUpdateWidget(covariant _SuccessState oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.text != widget.text) {
      _ctrl.text = widget.text;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D52).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF2E7D52).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF2E7D52),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.saved
                      ? 'Evolução salva no banco de dados.'
                      : 'Evolução gerada com sucesso. Você pode copiar, editar ou salvar abaixo.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF1F5B3B),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.description_rounded,
                      color: scheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Evolução de Enfermagem',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                if (_editing)
                  TextField(
                    controller: _ctrl,
                    maxLines: null,
                    minLines: 16,
                    decoration: const InputDecoration(
                      hintText: 'Texto da evolução',
                    ),
                    style: Theme.of(context).textTheme.bodyLarge,
                    onChanged: widget.onTextChanged,
                  )
                else
                  BoldMarkdown(widget.text),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ActionButton(
              label: 'Voltar ao formulário',
              kind: ActionButtonKind.subtle,
              icon: Icons.arrow_back_rounded,
              onPressed: widget.onEdit,
            ),
            ActionButton(
              label: _editing ? 'Concluir edição' : 'Editar texto',
              kind: ActionButtonKind.secondary,
              icon: _editing ? Icons.check_rounded : Icons.edit_rounded,
              onPressed: () {
                setState(() {
                  if (_editing) {
                    widget.onTextChanged(_ctrl.text);
                  }
                  _editing = !_editing;
                });
              },
            ),
            ActionButton(
              label: 'Copiar',
              kind: ActionButtonKind.primary,
              icon: Icons.copy_rounded,
              onPressed: widget.onCopy,
            ),
            if (!widget.saved)
              ActionButton(
                label: 'Salvar no Banco',
                kind: ActionButtonKind.success,
                icon: Icons.save_rounded,
                onPressed: widget.onSave,
              ),
            ActionButton(
              label: 'Nova Evolução',
              kind: ActionButtonKind.primary,
              icon: Icons.add_rounded,
              onPressed: widget.onNew,
            ),
          ],
        ),
      ],
    );
  }
}