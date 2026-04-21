import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/activity_log.dart';
import '../../models/user.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/stat_card.dart';
import 'admin_home_screen.dart';
import 'admin_logs_screen.dart';

/// Jornada completa de um usuário: perfil + estatísticas + timeline.
class AdminUserDetailScreen extends StatefulWidget {
  const AdminUserDetailScreen({super.key, required this.userId});
  final String userId;

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().hydrate();
    });
  }

  Future<void> _resetPassword(AppUser user) async {
    final AdminProvider admin = context.read<AdminProvider>();
    final AppUser? me = context.read<AuthProvider>().currentUser;
    if (me == null) return;
    try {
      final String temp = await admin.resetPassword(
        admin: me,
        targetUserId: user.id,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: const Text('Senha redefinida'),
          content: SelectableText(
            'A nova senha temporária é:\n\n$temp\n\n'
            'O usuário terá que trocá-la no próximo login.',
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(e.message),
        ),
      );
    }
  }

  Future<void> _unlock(AppUser user) async {
    final AdminProvider admin = context.read<AdminProvider>();
    final AppUser? me = context.read<AuthProvider>().currentUser;
    if (me == null) return;
    try {
      await admin.unlockUser(admin: me, targetUserId: user.id);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(e.message),
        ),
      );
    }
  }

  Future<void> _toggleActive(AppUser user) async {
    final AdminProvider admin = context.read<AdminProvider>();
    final AppUser? me = context.read<AuthProvider>().currentUser;
    if (me == null) return;
    try {
      await admin.updateUser(
        admin: me,
        targetUserId: user.id,
        active: !user.active,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(e.message),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AdminProvider admin = context.watch<AdminProvider>();
    final AppUser? user = admin.users
        .cast<AppUser?>()
        .firstWhere((AppUser? u) => u?.id == widget.userId, orElse: () => null);

    if (user == null) {
      return Scaffold(
        appBar: const AppHeader(),
        body: const Center(
          child: Text('Usuário não encontrado.'),
        ),
      );
    }

    final List<ActivityLog> logs = admin.logsForUser(user.id);
    final Map<LogCategory, int> counts =
        admin.categoryCountsForUser(user.id);
    final int loginsWeek =
        admin.loginsInLastDays(7, userId: user.id);

    return Scaffold(
      appBar: const AppHeader(),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.horizontalPadding(context),
          vertical: 24,
        ),
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 4),
              Text(
                'Jornada do usuário',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ProfileHero(
            user: user,
            onResetPassword: () => _resetPassword(user),
            onToggleActive: () => _toggleActive(user),
            onUnlock: () => _unlock(user),
          ),
          const SizedBox(height: 22),
          Text('Atividade consolidada',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          _buildStats(context, counts, loginsWeek, logs.length),
          const SizedBox(height: 24),
          Row(
            children: <Widget>[
              Text('Histórico completo',
                  style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) =>
                        AdminLogsScreen(initialUserId: user.id),
                  ));
                },
                icon: const Icon(Icons.filter_alt_rounded, size: 18),
                label: const Text('Abrir com filtros avançados'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (logs.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radius),
                border:
                    Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.history_rounded,
                        size: 40, color: AppColors.indigo),
                    const SizedBox(height: 10),
                    Text('Sem atividade registrada',
                        style:
                            Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Assim que ${user.displayName} utilizar o sistema, '
                      'os eventos aparecerão aqui.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            )
          else
            _Timeline(logs: logs),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStats(
    BuildContext context,
    Map<LogCategory, int> counts,
    int loginsWeek,
    int totalEvents,
  ) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final int cols = c.maxWidth >= 1000
            ? 4
            : c.maxWidth >= 620
                ? 2
                : 1;
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: cols == 1 ? 2.6 : cols == 2 ? 1.8 : 1.25,
          children: <Widget>[
            StatCard(
              icon: Icons.bolt_rounded,
              label: 'Eventos totais',
              value: totalEvents.toString(),
              hint: 'Tudo que o usuário fez no sistema',
              gradient: AppColors.brandGradient,
              accent: AppColors.indigo,
            ),
            StatCard(
              icon: Icons.login_rounded,
              label: 'Logins nos últimos 7 dias',
              value: loginsWeek.toString(),
              accent: AppColors.teal,
            ),
            StatCard(
              icon: Icons.auto_awesome_rounded,
              label: 'Evoluções geradas',
              value: (counts[LogCategory.evolution] ?? 0).toString(),
              accent: AppColors.amber,
            ),
            StatCard(
              icon: Icons.shield_rounded,
              label: 'Ações administrativas',
              value: (counts[LogCategory.admin] ?? 0).toString(),
              accent: AppColors.violet,
            ),
          ],
        );
      },
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.user,
    required this.onResetPassword,
    required this.onToggleActive,
    required this.onUnlock,
  });
  final AppUser user;
  final VoidCallback onResetPassword;
  final VoidCallback onToggleActive;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateFormat fmt = DateFormat('dd/MM/yyyy HH:mm');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        gradient: AppColors.brandGradient,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.indigo.withValues(alpha: 0.3),
            blurRadius: 28,
            offset: const Offset(0, 14),
            spreadRadius: -8,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          final bool wide = c.maxWidth >= 720;
          final Widget identity = Row(
            children: <Widget>[
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials(user.displayName),
                  style: const TextStyle(
                    color: AppColors.indigoDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      user.displayName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '@${user.username}  •  ${user.role.label}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    if (user.email.isNotEmpty)
                      Text(
                        user.email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );

          final List<Widget> meta = <Widget>[
            _InfoPill(
              icon: Icons.calendar_month_rounded,
              label: 'Criado em',
              value: fmt.format(user.createdAt),
            ),
            _InfoPill(
              icon: Icons.login_rounded,
              label: 'Último login',
              value: user.lastLoginAt == null
                  ? 'Nunca'
                  : fmt.format(user.lastLoginAt!),
            ),
            if (user.corenUF != null && user.corenNumero != null)
              _InfoPill(
                icon: Icons.verified_user_rounded,
                label: 'COREN',
                value: 'COREN/${user.corenUF}-${user.corenNumero}',
              ),
            if (user.failedLoginAttempts > 0)
              _InfoPill(
                icon: Icons.warning_rounded,
                label: 'Tentativas falhas',
                value: user.failedLoginAttempts.toString(),
              ),
            if (user.isLocked)
              _InfoPill(
                icon: Icons.lock_clock_rounded,
                label: 'Bloqueado até',
                value: fmt.format(user.lockedUntil!),
              ),
            if (!user.active)
              const _InfoPill(
                icon: Icons.block_rounded,
                label: 'Status',
                value: 'Conta desativada',
              ),
            if (user.mustChangePassword)
              const _InfoPill(
                icon: Icons.priority_high_rounded,
                label: 'Pendência',
                value: 'Deve trocar a senha',
              ),
          ];

          final Widget actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _HeroBtn(
                icon: Icons.lock_reset_rounded,
                label: 'Redefinir senha',
                onTap: onResetPassword,
              ),
              _HeroBtn(
                icon: user.active
                    ? Icons.toggle_off_rounded
                    : Icons.toggle_on_rounded,
                label: user.active ? 'Desativar conta' : 'Reativar conta',
                onTap: onToggleActive,
              ),
              if (user.isLocked)
                _HeroBtn(
                  icon: Icons.lock_open_rounded,
                  label: 'Desbloquear',
                  onTap: onUnlock,
                ),
            ],
          );

          if (wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(flex: 3, child: identity),
                    Expanded(flex: 2, child: actions),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(spacing: 8, runSpacing: 8, children: meta),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              identity,
              const SizedBox(height: 14),
              Wrap(spacing: 8, runSpacing: 8, children: meta),
              const SizedBox(height: 14),
              actions,
            ],
          );
        },
      ),
    );
  }

  String _initials(String name) {
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final String a = parts.first.characters.first;
    final String b = parts.length > 1 ? parts.last.characters.first : '';
    return (a + b).toUpperCase();
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBtn extends StatelessWidget {
  const _HeroBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.logs});
  final List<ActivityLog> logs;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateFormat day = DateFormat('dd/MM/yyyy');
    final DateFormat time = DateFormat('HH:mm:ss');

    final Map<String, List<ActivityLog>> byDay =
        <String, List<ActivityLog>>{};
    for (final ActivityLog l in logs) {
      final String k = DateFormat('yyyy-MM-dd').format(l.timestamp);
      byDay.putIfAbsent(k, () => <ActivityLog>[]).add(l);
    }
    final List<String> days = byDay.keys.toList()
      ..sort((String a, String b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final String k in days) ...<Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
            child: Text(
              day.format(DateTime.parse(k)),
              style: theme.textTheme.titleSmall?.copyWith(
                letterSpacing: 0.4,
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          for (final ActivityLog l in byDay[k]!)
            _TimelineItem(log: l, timeFmt: time),
        ],
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.log, required this.timeFmt});
  final ActivityLog log;
  final DateFormat timeFmt;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = categoryColor(log.type.category);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 68,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                timeFmt.format(log.timestamp),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.right,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: <Widget>[
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: theme.colorScheme.surface, width: 3),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 8,
                      spreadRadius: -1,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: theme.dividerColor,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: LogDetailTile(log: log),
            ),
          ),
        ],
      ),
    );
  }
}
