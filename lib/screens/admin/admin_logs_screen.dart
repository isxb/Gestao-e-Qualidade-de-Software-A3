import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/activity_log.dart';
import '../../models/user.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin_guard.dart';
import '../../widgets/app_header.dart';
import 'admin_home_screen.dart';

/// Visualizador de logs com filtros combinados.
class AdminLogsScreen extends StatefulWidget {
  const AdminLogsScreen({
    super.key,
    this.initialUserId,
    this.category,
  });

  final String? initialUserId;
  final LogCategory? category;

  @override
  State<AdminLogsScreen> createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends State<AdminLogsScreen> {
  String? _userId;
  final Set<LogCategory> _categories = <LogCategory>{};
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _userId = widget.initialUserId;
    if (widget.category != null) _categories.add(widget.category!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().hydrate();
    });
  }

  Future<void> _pickRange() async {
    final DateTimeRange? r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: (_from != null && _to != null)
          ? DateTimeRange(start: _from!, end: _to!)
          : null,
    );
    if (r == null) return;
    setState(() {
      _from = DateTime(r.start.year, r.start.month, r.start.day);
      _to = DateTime(r.end.year, r.end.month, r.end.day, 23, 59, 59);
    });
  }

  Future<void> _confirmClear() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Limpar todos os logs?'),
        content: const Text(
          'Esta ação apagará o histórico completo de auditoria. '
          'Não é possível desfazer.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Limpar tudo'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<AdminProvider>().clearAllLogs();
  }

  @override
  Widget build(BuildContext context) {
    // Guard de segurança: somente administradores acessam esta tela.
    if (!context.watch<AuthProvider>().isAdmin) {
      return const AdminAccessDenied();
    }
    final AdminProvider admin = context.watch<AdminProvider>();
    final ThemeData theme = Theme.of(context);
    final List<ActivityLog> logs = admin.queryLogs(
      userId: _userId,
      categories: _categories.isEmpty ? null : _categories,
      from: _from,
      to: _to,
    );

    return Scaffold(
      appBar: const AppHeader(),
      body: Padding(
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
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Logs & auditoria',
                          style: theme.textTheme.headlineMedium),
                      Text(
                        '${logs.length} eventos correspondem aos filtros.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _confirmClear,
                  icon: const Icon(Icons.delete_sweep_rounded,
                      color: AppColors.danger),
                  label: const Text(
                    'Limpar tudo',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _LogsFilterBar(
              users: admin.users,
              selectedUser: _userId,
              onSelectUser: (String? id) => setState(() => _userId = id),
              categories: _categories,
              onToggleCategory: (LogCategory c) => setState(() {
                if (_categories.contains(c)) {
                  _categories.remove(c);
                } else {
                  _categories.add(c);
                }
              }),
              from: _from,
              to: _to,
              onPickRange: _pickRange,
              onClearRange: () => setState(() {
                _from = null;
                _to = null;
              }),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: logs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(Icons.event_busy_rounded,
                              size: 48, color: AppColors.indigo),
                          const SizedBox(height: 10),
                          Text('Nenhum evento encontrado',
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            'Ajuste os filtros ou aguarde nova atividade.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: logs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (BuildContext c, int i) =>
                          LogDetailTile(log: logs[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogsFilterBar extends StatelessWidget {
  const _LogsFilterBar({
    required this.users,
    required this.selectedUser,
    required this.onSelectUser,
    required this.categories,
    required this.onToggleCategory,
    required this.from,
    required this.to,
    required this.onPickRange,
    required this.onClearRange,
  });

  final List<AppUser> users;
  final String? selectedUser;
  final ValueChanged<String?> onSelectUser;
  final Set<LogCategory> categories;
  final ValueChanged<LogCategory> onToggleCategory;
  final DateTime? from;
  final DateTime? to;
  final VoidCallback onPickRange;
  final VoidCallback onClearRange;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateFormat fmt = DateFormat('dd/MM/yyyy');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: selectedUser,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Usuário',
                    prefixIcon: Icon(Icons.person_search_rounded),
                    isDense: true,
                  ),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todos os usuários'),
                    ),
                    ...users.map(
                      (AppUser u) => DropdownMenuItem<String?>(
                        value: u.id,
                        child: Text('${u.displayName}  ·  @${u.username}'),
                      ),
                    ),
                  ],
                  onChanged: onSelectUser,
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: onPickRange,
                icon: const Icon(Icons.date_range_rounded),
                label: Text(
                  from == null
                      ? 'Período'
                      : '${fmt.format(from!)} – ${fmt.format(to!)}',
                ),
              ),
              if (from != null)
                IconButton(
                  onPressed: onClearRange,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: 'Limpar período',
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final LogCategory c in LogCategory.values)
                FilterChip(
                  selected: categories.contains(c),
                  onSelected: (_) => onToggleCategory(c),
                  label: Text(categoryLabel(c)),
                  avatar: Icon(
                    _iconFor(c),
                    color: categoryColor(c),
                    size: 16,
                  ),
                  selectedColor: categoryColor(c).withValues(alpha: 0.16),
                  side: BorderSide(
                      color: categories.contains(c)
                          ? categoryColor(c).withValues(alpha: 0.4)
                          : theme.dividerColor),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconFor(LogCategory c) {
    switch (c) {
      case LogCategory.auth:
        return Icons.lock_rounded;
      case LogCategory.admin:
        return Icons.admin_panel_settings_rounded;
      case LogCategory.evolution:
        return Icons.auto_awesome_rounded;
      case LogCategory.settings:
        return Icons.tune_rounded;
      case LogCategory.navigation:
        return Icons.map_rounded;
      case LogCategory.system:
        return Icons.memory_rounded;
    }
  }
}

/// Item de log detalhado com chip de categoria, ícone, ação e descrição.
class LogDetailTile extends StatelessWidget {
  const LogDetailTile({super.key, required this.log, this.compact = false});
  final ActivityLog log;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = categoryColor(log.type.category);
    final DateFormat fmt = DateFormat('dd/MM/yyyy HH:mm:ss');
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: 14, vertical: compact ? 10 : 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppTheme.radiusXs),
            ),
            child: Icon(log.type.icon, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        log.type.label,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        categoryLabel(log.type.category),
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 10.5,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  log.description,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '${log.userDisplayName}  •  ${fmt.format(log.timestamp)}',
                  style: theme.textTheme.bodySmall,
                ),
                if (!compact && log.metadata.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: log.metadata.entries
                          .map((MapEntry<String, dynamic> e) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius:
                                      BorderRadius.circular(999),
                                  border:
                                      Border.all(color: theme.dividerColor),
                                ),
                                child: Text(
                                  '${e.key}: ${e.value}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
