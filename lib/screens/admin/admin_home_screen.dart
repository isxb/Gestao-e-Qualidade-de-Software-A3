import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/activity_log.dart';
import '../../models/user.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/stat_card.dart';
import 'admin_logs_screen.dart';
import 'admin_user_detail_screen.dart';
import 'admin_users_screen.dart';

/// Painel administrativo — centro de controle do sistema.
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().hydrate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AdminProvider admin = context.watch<AdminProvider>();
    final AuthProvider auth = context.watch<AuthProvider>();
    final ThemeData theme = Theme.of(context);
    final List<ActivityLog> recent = admin.queryLogs(limit: 8);
    final int loginsWeek = admin.loginsInLastDays(7);
    final int totalLogs = admin.allLogs().length;

    return Scaffold(
      appBar: const AppHeader(),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.horizontalPadding(context),
          vertical: 28,
        ),
        children: <Widget>[
          _buildHeader(theme, auth),
          const SizedBox(height: 24),
          _buildStatsGrid(context, admin, loginsWeek, totalLogs),
          const SizedBox(height: 28),
          _buildQuickAccess(context),
          const SizedBox(height: 28),
          Row(
            children: <Widget>[
              Text('Atividade recente',
                  style: theme.textTheme.headlineMedium),
              const Spacer(),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AdminLogsScreen(),
                  ),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Ver todos os logs'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            _buildEmptyState(
              theme,
              icon: Icons.history_toggle_off_rounded,
              title: 'Nenhum evento registrado ainda',
              hint:
                  'Os eventos aparecem aqui assim que os usuários começam a utilizar o sistema.',
            )
          else
            ...recent.map((ActivityLog l) => _LogListTile(log: l)),
          const SizedBox(height: 28),
          Row(
            children: <Widget>[
              Text('Equipe',
                  style: theme.textTheme.headlineMedium),
              const Spacer(),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AdminUsersScreen(),
                  ),
                ),
                icon: const Icon(Icons.people_alt_rounded, size: 18),
                label: const Text('Gerenciar usuários'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildUsersPreview(context, admin),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.indigo.withValues(alpha: 0.3),
            blurRadius: 28,
            offset: const Offset(0, 14),
            spreadRadius: -8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: const Icon(Icons.shield_moon_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Painel de controle',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Olá, ${auth.currentUser?.displayName ?? 'Admin'}',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Monitore o uso, gerencie a equipe e garanta a segurança.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    AdminProvider admin,
    int loginsWeek,
    int totalLogs,
  ) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final int cols = c.maxWidth >= 1100
            ? 4
            : c.maxWidth >= 760
                ? 4
                : c.maxWidth >= 520
                    ? 2
                    : 1;
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: cols == 1 ? 2.7 : cols == 2 ? 1.9 : 1.3,
          children: <Widget>[
            StatCard(
              icon: Icons.people_alt_rounded,
              label: 'Usuários cadastrados',
              value: admin.totalUsers.toString(),
              hint: '${admin.activeUsers} ativos',
              gradient: AppColors.brandGradient,
              accent: AppColors.indigo,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AdminUsersScreen(),
                ),
              ),
            ),
            StatCard(
              icon: Icons.admin_panel_settings_rounded,
              label: 'Administradores',
              value: admin.totalAdmins.toString(),
              hint: 'Com acesso total ao sistema',
              accent: AppColors.violet,
            ),
            StatCard(
              icon: Icons.login_rounded,
              label: 'Logins em 7 dias',
              value: loginsWeek.toString(),
              hint: 'Toda a equipe',
              accent: AppColors.teal,
            ),
            StatCard(
              icon: Icons.dataset_linked_rounded,
              label: 'Eventos no diário',
              value: totalLogs.toString(),
              hint: 'Auditoria completa',
              accent: AppColors.amber,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AdminLogsScreen(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickAccess(BuildContext context) {
    final List<_QuickItem> items = <_QuickItem>[
      _QuickItem(
        icon: Icons.people_alt_rounded,
        title: 'Gerenciar usuários',
        subtitle: 'Criar, editar, reset de senha',
        accent: AppColors.indigo,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const AdminUsersScreen(),
          ),
        ),
      ),
      _QuickItem(
        icon: Icons.fact_check_rounded,
        title: 'Logs & auditoria',
        subtitle: 'Filtrar por usuário, tipo e data',
        accent: AppColors.teal,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const AdminLogsScreen(),
          ),
        ),
      ),
      _QuickItem(
        icon: Icons.person_search_rounded,
        title: 'Jornada do usuário',
        subtitle: 'Timeline completa individual',
        accent: AppColors.pink,
        onTap: () {
          final AdminProvider admin = context.read<AdminProvider>();
          if (admin.users.isEmpty) return;
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AdminUsersScreen(),
            ),
          );
        },
      ),
      _QuickItem(
        icon: Icons.health_and_safety_rounded,
        title: 'Saúde do sistema',
        subtitle: 'Sessão, dados e sistema',
        accent: AppColors.sky,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AdminLogsScreen(category: LogCategory.system),
            ),
          );
        },
      ),
    ];
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final int cols = c.maxWidth >= 1000
            ? 4
            : c.maxWidth >= 640
                ? 2
                : 1;
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: cols == 1 ? 3.2 : 1.9,
          children: items
              .map((_QuickItem i) => _QuickActionCard(item: i))
              .toList(),
        );
      },
    );
  }

  Widget _buildUsersPreview(BuildContext context, AdminProvider admin) {
    final List<AppUser> preview = admin.users.take(5).toList();
    if (preview.isEmpty) {
      return _buildEmptyState(
        Theme.of(context),
        icon: Icons.people_outline_rounded,
        title: 'Sem usuários cadastrados',
        hint: 'Crie o primeiro usuário para a equipe.',
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < preview.length; i++) ...<Widget>[
            _UserListTile(
              user: preview[i],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      AdminUserDetailScreen(userId: preview[i].id),
                ),
              ),
            ),
            if (i < preview.length - 1)
              Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context).dividerColor),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 36, color: theme.colorScheme.primary),
          const SizedBox(height: 10),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _QuickItem {
  _QuickItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.item});
  final _QuickItem item;
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(item.icon, color: item.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(item.title,
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(item.subtitle,
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded,
                  color: theme.colorScheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserListTile extends StatelessWidget {
  const _UserListTile({required this.user, required this.onTap});
  final AppUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color badgeColor =
        user.isAdmin ? AppColors.violet : AppColors.teal;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: user.isAdmin
                    ? AppColors.brandGradient
                    : LinearGradient(
                        colors: <Color>[
                          AppColors.teal.withValues(alpha: 0.75),
                          AppColors.sky.withValues(alpha: 0.9),
                        ],
                      ),
              ),
              alignment: Alignment.center,
              child: Text(
                _initials(user.displayName),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(user.displayName,
                      style: theme.textTheme.titleSmall),
                  Text(
                    '@${user.username}${user.email.isNotEmpty ? ' · ${user.email}' : ''}',
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                user.role.shortLabel,
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          ],
        ),
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

class _LogListTile extends StatelessWidget {
  const _LogListTile({required this.log});
  final ActivityLog log;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = categoryColor(log.type.category);
    final DateFormat fmt = DateFormat('dd/MM HH:mm');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
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
                    Expanded(
                      child: Text(
                        log.type.label,
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      fmt.format(log.timestamp),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${log.userDisplayName} — ${log.description}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color categoryColor(LogCategory c) {
  switch (c) {
    case LogCategory.auth:
      return AppColors.indigo;
    case LogCategory.admin:
      return AppColors.violet;
    case LogCategory.evolution:
      return AppColors.teal;
    case LogCategory.settings:
      return AppColors.amber;
    case LogCategory.navigation:
      return AppColors.sky;
    case LogCategory.system:
      return AppColors.rose;
  }
}

String categoryLabel(LogCategory c) {
  switch (c) {
    case LogCategory.auth:
      return 'Autenticação';
    case LogCategory.admin:
      return 'Administração';
    case LogCategory.evolution:
      return 'Evolução';
    case LogCategory.settings:
      return 'Configurações';
    case LogCategory.navigation:
      return 'Navegação';
    case LogCategory.system:
      return 'Sistema';
  }
}
