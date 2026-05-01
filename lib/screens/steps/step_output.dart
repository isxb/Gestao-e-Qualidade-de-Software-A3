import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/evolution_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/ad_service.dart';
import '../../services/export_service.dart';
import '../../utils/markdown_bold.dart';
import '../../utils/platform_check.dart';
import '../../widgets/action_button.dart';
import '../subscription/plans_screen.dart';

class StepOutput extends StatefulWidget {
  const StepOutput({super.key});

  @override
  State<StepOutput> createState() => _StepOutputState();
}

class _StepOutputState extends State<StepOutput> {
  bool _saved = false;

  /// True enquanto um anúncio está sendo exibido na tela.
  /// Impede que o usuário dispare dois anúncios simultâneos.
  bool _showingAd = false;

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
    setState(() {
      _saved = false;
      _showingAd = false;
    });
  }

  /// Solicita ao AdService que exiba o próximo anúncio recompensado.
  /// Quando o usuário conclui o anúncio, [EvolutionProvider.markAdWatched]
  /// é chamado, incrementando o contador e notificando a UI via Provider.
  Future<void> _watchNextAd(EvolutionProvider p) async {
    if (_showingAd) return;
    setState(() => _showingAd = true);

    await AdService.instance.showRewardedInterstitial(
      onComplete: () {
        p.markAdWatched();
        if (mounted) setState(() => _showingAd = false);
      },
      onSkipped: () {
        // Rewarded interstitial não permite pular normalmente,
        // mas cobrimos o caso de fechamento inesperado do SDK.
        if (mounted) setState(() => _showingAd = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final EvolutionProvider p = context.watch<EvolutionProvider>();
    final SubscriptionProvider sub = context.watch<SubscriptionProvider>();
    final String pName = p.form.pacienteNome.trim().isEmpty
        ? 'Paciente Não Identificado'
        : p.form.pacienteNome.trim();

    switch (p.status) {
      case GenerationStatus.loading:
        return const _LoadingState();

      case GenerationStatus.error:
        return _ErrorState(
          message: p.errorMessage ?? 'Erro desconhecido.',
          onRetry: () => p.gerarEvolucao(),
          onBack: p.previous,
        );

      case GenerationStatus.idle:
        return _IdleState(onGenerate: () => p.gerarEvolucao());

      case GenerationStatus.success:
        // Em mobile sem premium: exige que o usuário assista 2 anúncios
        // antes de visualizar o conteúdo gerado.
        // Em premium, Windows, macOS, Linux e web: acesso direto.
        final bool needsAds =
            PlatformCheck.supportsAds && !sub.isPremium && !p.adsCompleted;

        if (needsAds) {
          return _AdGateState(
            adsWatched: p.adsWatched,
            requiredAds: EvolutionProvider.requiredAdsCount,
            isShowingAd: _showingAd,
            onWatchAd: () => _watchNextAd(p),
          );
        }

        return _SuccessState(
          text: p.generatedText,
          patientName: pName,
          saved: _saved,
          onCopy: () => _copy(p.generatedText),
          onSave: () => _save(p),
          onEdit: () => p.setStep(7),
          onNew: () => _newEvolution(p),
          onTextChanged: (String v) => p.setGeneratedText(v),
        );
    }
  }
}

// ============================================================
// _AdGateState — tela de progresso de anúncios (mobile free)
// ============================================================

class _AdGateState extends StatelessWidget {
  const _AdGateState({
    required this.adsWatched,
    required this.requiredAds,
    required this.isShowingAd,
    required this.onWatchAd,
  });

  final int adsWatched;
  final int requiredAds;
  final bool isShowingAd;
  final VoidCallback onWatchAd;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final int remaining = requiredAds - adsWatched;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Ícone principal
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_circle_outline_rounded,
                color: scheme.primary,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),

            // Título
            Text(
              'Quase lá!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),

            // Descrição
            Text(
              'Assista $remaining '
              '${remaining == 1 ? 'anúncio' : 'anúncios'} '
              'de 30 segundos para liberar a sua evolução.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 28),

            // Indicador de progresso animado (bolinhas)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(requiredAds, (int i) {
                final bool done = i < adsWatched;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: done ? 36 : 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: done
                          ? scheme.primary
                          : scheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: done
                        ? const Center(
                            child: Icon(
                              Icons.check,
                              size: 10,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 28),

            // Botão principal: assistir anúncio
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isShowingAd ? null : onWatchAd,
                icon: isShowingAd
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(
                  isShowingAd
                      ? 'Anúncio em exibição...'
                      : 'Assistir anúncio ${adsWatched + 1} de $requiredAds',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Opção de assinar (remove os anúncios)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PlansScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.workspace_premium_rounded, size: 18),
              label: const Text('Assinar e usar sem anúncios'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// _LoadingState
// ============================================================

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
              'O sistema está processando os dados e formatando a evolução.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// _ErrorState
// ============================================================

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
                border: Border.all(
                  color: scheme.error.withValues(alpha: 0.3),
                ),
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

// ============================================================
// _IdleState
// ============================================================

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
              'Clique no botão abaixo para gerar a evolução de enfermagem.',
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

// ============================================================
// _SuccessState
// ============================================================

class _SuccessState extends StatefulWidget {
  const _SuccessState({
    required this.text,
    required this.patientName,
    required this.saved,
    required this.onCopy,
    required this.onSave,
    required this.onEdit,
    required this.onNew,
    required this.onTextChanged,
  });

  final String text;
  final String patientName;
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

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Exportar Documento',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf_rounded,
                      color: Colors.red, size: 32),
                  title: const Text('Salvar como PDF'),
                  subtitle:
                      const Text('Gera um documento pronto para impressão.'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      await ExportService.exportToPdf(
                        widget.text,
                        widget.patientName,
                      );
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text('Erro ao exportar PDF: $e'),
                          ),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.text_snippet_rounded,
                      color: Colors.blue, size: 32),
                  title: const Text('Compartilhar Texto'),
                  subtitle: const Text(
                    'Envia para outros apps (WhatsApp, Word, Email).',
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      await ExportService.exportToText(
                        widget.text,
                        widget.patientName,
                      );
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text('Erro ao compartilhar texto: $e'),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Banner de status (salvo ou recém-gerado)
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
                      : 'Evolução gerada com sucesso. Você pode exportar, copiar ou salvar abaixo.',
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

        // Card com o texto da evolução
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
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
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

        // Botões de ação
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ActionButton(
              label: 'Voltar',
              kind: ActionButtonKind.subtle,
              icon: Icons.arrow_back_rounded,
              onPressed: widget.onEdit,
            ),
            ActionButton(
              label: _editing ? 'Concluir edição' : 'Editar',
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
            ActionButton(
              label: 'Exportar',
              kind: ActionButtonKind.secondary,
              icon: Icons.download_rounded,
              onPressed: () => _showExportOptions(context),
            ),
            if (!widget.saved)
              ActionButton(
                label: 'Salvar Banco',
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