import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/evolution_template.dart';
import '../../providers/template_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import 'template_edit_screen.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        showHomeButton: true,
        onHomeTap: () =>
            Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEdit(context, null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo template'),
        backgroundColor: AppColors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: AppTheme.contentMaxWidth(context)),
          child: Consumer<TemplateProvider>(
            builder: (BuildContext context, TemplateProvider prov, _) {
              if (prov.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (prov.templates.isEmpty) {
                return _EmptyState(onCreate: () => _openEdit(context, null));
              }
              return ListView.separated(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.horizontalPadding(context),
                  vertical: 24,
                ).copyWith(top: 20),
                itemCount: prov.templates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (BuildContext ctx, int i) {
                  return _TemplateCard(
                    template: prov.templates[i],
                    onEdit: () => _openEdit(context, prov.templates[i]),
                    onDelete: () =>
                        _confirmDelete(context, prov, prov.templates[i]),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _openEdit(BuildContext context, EvolutionTemplate? template) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TemplateEditScreen(template: template),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TemplateProvider prov,
    EvolutionTemplate template,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Excluir template'),
        content: Text(
          'Deseja excluir o template "${template.name}"? Esta ação não pode ser desfeita.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await prov.delete(template.id);
    }
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.onEdit,
    required this.onDelete,
  });

  final EvolutionTemplate template;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark
              ? theme.colorScheme.outline.withValues(alpha: 0.2)
              : AppColors.indigoLight,
        ),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.indigoLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bookmark_rounded,
                  color: AppColors.indigo,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      template.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (template.description.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        template.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${template.setor}  ·  ${template.tipoAcesso}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.indigo.withValues(alpha: 0.75),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                onSelected: (String v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.edit_rounded, size: 18),
                        SizedBox(width: 10),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.delete_rounded,
                            size: 18, color: AppColors.danger),
                        SizedBox(width: 10),
                        Text(
                          'Excluir',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.indigoLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_border_rounded,
                size: 36,
                color: AppColors.indigo,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Nenhum template criado',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Crie templates para pré-configurar seus campos mais usados e acelerar o preenchimento das evoluções.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Criar primeiro template'),
            ),
          ],
        ),
      ),
    );
  }
}
