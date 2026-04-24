import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/activity_log.dart';
import '../models/saved_evolution.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/evolution_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/stat_card.dart';
import 'admin/admin_home_screen.dart';
import 'database_screen.dart';
import 'generator_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EvolutionProvider>().hydrate();
      if (context.read<AuthProvider>().isAdmin) {
        context.read<AdminProvider>().hydrate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AuthProvider auth = context.watch<AuthProvider>();
    final EvolutionProvider evo = context.watch<EvolutionProvider>();
    final List<SavedEvolution> all = evo.savedEvolutions;
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime weekStart = today.subtract(Duration(days: today.weekday - 1));
    final DateTime monthStart = DateTime(now.year, now.month, 1);

    final DateFormat parseDate = DateFormat('dd/MM/yyyy');
    int todayCount = 0, weekCount = 0, monthCount = 0;
    for (final SavedEvolution e in all) {
      try {
        final DateTime d = parseDate.parse(e.date);
        if (!d.isBefore(today)) todayCount++;
        if (!d.isBefore(weekStart)) weekCount++;
        if (!d.isBefore(monthStart)) monthCount++;
      } catch (_) {
        // Data malformada — ignora.
      }
    }

    return Scaffold(
      appBar: AppHeader(
        trailing: IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SettingsScreen(),
              ),
            );
          },
          icon: const Icon(Icons.settings_rounded, color: Colors.white),
          tooltip: 'Configurações',
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: AppTheme.contentMaxWidth(context)),
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.horizontalPadding(context),
              vertical: 28,
            ),
            children: <Widget>[
              _GreetingHero(
                displayName: auth.currentUser?.displayName ?? '',
                isAdmin: auth.isAdmin,
              ),
              if (auth.isAdmin) ...<Widget>[
                const SizedBox(height: 20),
                _AdminShortcut(),
              ],
              const SizedBox(height: 22),
              Text('Resumo do seu trabalho',
                  style: theme.textTheme.headlineMedium),
              const SizedBox(height: 10),
              _buildStatsGrid(context, todayCount, weekCount, monthCount,
                  all.length),
              const SizedBox(height: 28),
              Text('Ações rápidas', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 10),
              _QuickActions(),
              const SizedBox(height: 28),
              Row(
                children: <Widget>[
                  Text('Suas evoluções recentes',
                      style: theme.textTheme.headlineMedium),
                  const Spacer(),
                  if (all.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DatabaseScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Ver todas'),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              _buildRecentList(context, all.take(5).toList()),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    int today,
    int week,
    int month,
    int total,
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
          childAspectRatio: cols == 1 ? 2.6 : cols == 2 ? 1.9 : 1.25,
          children: <Widget>[
            StatCard(
              icon: Icons.today_rounded,
              label: 'Hoje',
              value: today.toString(),
              hint: 'Evoluções do dia',
              gradient: AppColors.brandGradient,
              accent: AppColors.indigo,
            ),
            StatCard(
              icon: Icons.calendar_view_week_rounded,
              label: 'Esta semana',
              value: week.toString(),
              accent: AppColors.teal,
            ),
            StatCard(
              icon: Icons.calendar_month_rounded,
              label: 'Neste mês',
              value: month.toString(),
              accent: AppColors.violet,
            ),
            StatCard(
              icon: Icons.folder_special_rounded,
              label: 'Arquivadas',
              value: total.toString(),
              accent: AppColors.amber,
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentList(BuildContext context, List<SavedEvolution> items) {
    final ThemeData theme = Theme.of(context);
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Center(
          child: Column(
            children: <Widget>[
              const Icon(Icons.auto_stories_rounded,
                  size: 40, color: AppColors.indigo),
              const SizedBox(height: 10),
              Text('Você ainda não salvou nenhuma evolução',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Clique em "Nova evolução" para começar.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < items.length; i++) ...<Widget>[
            _RecentRow(evo: items[i]),
            if (i < items.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: theme.dividerColor,
              ),
          ],
        ],
      ),
    );
  }
}

class _GreetingHero extends StatelessWidget {
  const _GreetingHero({required this.displayName, required this.isAdmin});
  final String displayName;
  final bool isAdmin;

  String get _period {
    final int h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat fmt = DateFormat('EEEE, dd/MM');
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
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
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  fmt.format(DateTime.now()).toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$_period, $displayName',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isAdmin
                      ? 'Você tem acesso total ao painel administrativo.'
                      : 'Pronto para a próxima evolução?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.monitor_heart_rounded,
                color: Colors.white, size: 34),
          ),
        ],
      ),
    );
  }
}

class _AdminShortcut extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(
            color: AppColors.violet.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: const Icon(Icons.shield_moon_rounded,
                color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('Você é administrador',
                    style: theme.textTheme.titleMedium),
                Text(
                  'Acesse o painel para gerenciar a equipe e auditoria.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AdminHomeScreen(),
              ),
            ),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text('Abrir painel'),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext c, BoxConstraints cts) {
        final int cols = cts.maxWidth >= 760
            ? 3
            : cts.maxWidth >= 520
                ? 2
                : 1;
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: cols == 1 ? 3.5 : 1.8,
          children: <Widget>[
            _ActionCard(
              icon: Icons.medical_information_rounded,
              title: 'Nova evolução',
              subtitle: 'Começar um novo registro clínico',
              gradient: const LinearGradient(
                colors: <Color>[AppColors.indigo, AppColors.violet],
              ),
              onTap: () {
                context.read<EvolutionProvider>().startNewEvolution();
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const GeneratorScreen(),
                ));
              },
            ),
            _ActionCard(
              icon: Icons.folder_open_rounded,
              title: 'Banco de evoluções',
              subtitle: 'Acessar, editar e consultar registros',
              gradient: const LinearGradient(
                colors: <Color>[AppColors.teal, AppColors.sky],
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const DatabaseScreen(),
                ),
              ),
            ),
            _ActionCard(
              icon: Icons.info_outline_rounded,
              title: 'Sobre o Sistema',
              subtitle: 'Versão e informações de uso',
              gradient: const LinearGradient(
                colors: <Color>[AppColors.amber, AppColors.pink],
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsScreen(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: gradient.colors.first.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 12),
                spreadRadius: -8,
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.evo});
  final SavedEvolution evo;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const DatabaseScreen(),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.indigoLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(Icons.description_rounded,
                  color: AppColors.indigo),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(evo.patientName, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    _preview(evo.text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text('${evo.date} · ${evo.time}',
                style: theme.textTheme.bodySmall),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  String _preview(String txt) {
    final String s = txt.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s.length > 90 ? '${s.substring(0, 90)}...' : s;
  }
}