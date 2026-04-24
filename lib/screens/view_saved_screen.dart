import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/saved_evolution.dart';
import '../providers/evolution_provider.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import '../utils/markdown_bold.dart';
import '../widgets/action_button.dart';
import '../widgets/app_header.dart';

class ViewSavedScreen extends StatefulWidget {
  const ViewSavedScreen({super.key, required this.evolution});

  final SavedEvolution evolution;

  @override
  State<ViewSavedScreen> createState() => _ViewSavedScreenState();
}

class _ViewSavedScreenState extends State<ViewSavedScreen> {
  late SavedEvolution _current;
  late TextEditingController _editCtrl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _current = widget.evolution;
    _editCtrl = TextEditingController(text: _current.text);
  }

  @override
  void dispose() {
    _editCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final EvolutionProvider p = context.read<EvolutionProvider>();
    await p.updateSavedEvolution(_current.id, _editCtrl.text);
    if (!mounted) return;
    setState(() {
      _current = _current.copyWith(text: _editCtrl.text);
      _editing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alterações salvas.')),
    );
  }

  Future<void> _delete() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Excluir evolução?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    if (!mounted) return;
    await context.read<EvolutionProvider>().deleteSavedEvolution(_current.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _copy() async {
    final String text = _editing ? _editCtrl.text : _current.text;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Texto copiado para a área de transferência.'),
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 32),
                  title: const Text('Salvar como PDF'),
                  subtitle: const Text('Gera um documento pronto para impressão.'),
                  onTap: () {
                    Navigator.pop(ctx);
                    ExportService.exportToPdf(_current.text, _current.patientName);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.text_snippet_rounded, color: Colors.blue, size: 32),
                  title: const Text('Compartilhar Texto'),
                  subtitle: const Text('Envia para outros apps (WhatsApp, Word, Email).'),
                  onTap: () {
                    Navigator.pop(ctx);
                    ExportService.exportToText(_current.text, _current.patientName);
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
    return Scaffold(
      appBar: AppHeader(
        showHomeButton: true,
        onHomeTap: () =>
            Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppTheme.contentMaxWidth(context),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.horizontalPadding(context),
              vertical: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: 'Voltar',
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _current.patientName,
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_current.date} às ${_current.time}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _Toolbar(
                  editing: _editing,
                  onToggleEdit: () {
                    setState(() {
                      _editing = !_editing;
                      if (!_editing) _editCtrl.text = _current.text;
                    });
                  },
                  onSave: _save,
                  onCopy: _copy,
                  onExport: () => _showExportOptions(context),
                  onDelete: _delete,
                ),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _editing
                        ? TextField(
                            controller: _editCtrl,
                            maxLines: null,
                            minLines: 14,
                            decoration: const InputDecoration(
                              hintText: 'Texto da evolução',
                            ),
                            style:
                                Theme.of(context).textTheme.bodyLarge,
                          )
                        : BoldMarkdown(_current.text),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.editing,
    required this.onToggleEdit,
    required this.onSave,
    required this.onCopy,
    required this.onExport,
    required this.onDelete,
  });

  final bool editing;
  final VoidCallback onToggleEdit;
  final VoidCallback onSave;
  final VoidCallback onCopy;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        if (editing)
          ActionButton(
            label: 'Salvar',
            kind: ActionButtonKind.success,
            icon: Icons.check_rounded,
            onPressed: onSave,
          )
        else
          ActionButton(
            label: 'Editar',
            kind: ActionButtonKind.secondary,
            icon: Icons.edit_rounded,
            onPressed: onToggleEdit,
          ),
        ActionButton(
          label: 'Copiar',
          kind: ActionButtonKind.primary,
          icon: Icons.copy_rounded,
          onPressed: onCopy,
        ),
        ActionButton(
          label: 'Exportar',
          kind: ActionButtonKind.secondary,
          icon: Icons.download_rounded,
          onPressed: onExport,
        ),
        ActionButton(
          label: 'Excluir',
          kind: ActionButtonKind.danger,
          icon: Icons.delete_rounded,
          onPressed: onDelete,
        ),
      ],
    );
  }
}