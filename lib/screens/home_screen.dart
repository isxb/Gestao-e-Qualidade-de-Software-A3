import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/saved_evolution.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/evolution_provider.dart';
import '../providers/subscription_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/ad_banner.dart';
import '../widgets/app_header.dart';
import 'admin/admin_home_screen.dart';
import 'database_screen.dart';
import 'generator_screen.dart';
import 'settings_screen.dart';
import 'subscription/manage_subscription_screen.dart';
import 'subscription/plans_screen.dart';
import 'view_saved_screen.dart';

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
    final SubscriptionProvider sub = context.watch<SubscriptionProvider>();
    final List<SavedEvolution> all = evo.savedEvolutions;
    final List<SavedEvolution> recent = all.take(5).toList();

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
                const SizedBox(height: 18),
                _AdminShortcut(),
              ],
              const SizedBox(height: 18),
              _SubscriptionBadge(),
              const SizedBox(height: 18),
              _PrimaryCTA(),
              const SizedBox(height: 14),
              _SecondaryActions(),
              const SizedBox(height: 28),
              Row(
                children: <Widget>[
                  Text(
                    'Evoluções recentes',
                    style: theme.textTheme.headlineMedium,
                  ),
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
              _RecentList(items: recent),
              if (sub.shouldShowAds) ...<Widget>[
                const SizedBox(height: 18),
                const AdBanner(),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

/// Faixa enxuta indicando o plano atual e — se gratuito — convidando o
/// usuário a fazer upgrade. Em premium vira link para "Minha assinatura".
class _SubscriptionBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SubscriptionProvider sub = context.watch<SubscriptionProvider>();
    final bool premium = sub.isPremium;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => premium
                ? const ManageSubscriptionScreen()
                : const PlansScreen(),
          ),
        ),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: premium
                ? AppColors.tealLight.withValues(alpha: 0.55)
                : AppColors.amberLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(
              color: (premium ? AppColors.teal : AppColors.amber)
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                premium
                    ? Icons.workspace_premium_rounded
                    : Icons.local_offer_rounded,
                size: 20,
                color: premium ? AppColors.teal : AppColors.warningDark,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  premium
                      ? 'Premium ativo — gerencie sua assinatura.'
                      : 'Você está no plano gratuito. Conheça o Premium e remova anúncios.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Saudação compacta — informa horário, dia e nome.
/// Sem "subtítulo motivacional" para manter o tom sóbrio do sistema.
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
            color: AppColors.indigo.withValues(alpha: 0.22),
            blurRadius: 26,
            offset: const Offset(0, 12),
            spreadRadius: -10,
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
                    color: Colors.white.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w700,
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
                  'Registre uma nova evolução ou acesse o histórico do plantão.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.medical_services_rounded,
                color: Colors.white, size: 30),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.indigo.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: const Icon(Icons.shield_rounded,
                color: AppColors.indigo, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('Painel administrativo',
                    style: theme.textTheme.titleSmall),
                Text(
                  'Gerencie equipe, auditoria e segurança.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AdminHomeScreen(),
              ),
            ),
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('Abrir'),
          ),
        ],
      ),
    );
  }
}

/// Ação principal do app: começar uma nova evolução. Cartão amplo, com
/// chamada explícita e descrição do fluxo de 9 passos.
class _PrimaryCTA extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: () {
          context.read<EvolutionProvider>().startNewEvolution();
          Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const GeneratorScreen(),
          ));
        },
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(
              color: AppColors.indigo.withValues(alpha: 0.35),
              width: 1.4,
            ),
            boxShadow: AppColors.softShadow(opacity: 0.05),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.note_add_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Iniciar nova evolução',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Preencha os dados clínicos em 9 passos e gere o documento pronto para imprimir, copiar ou exportar.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.indigo.withValues(alpha: 0.85),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Atalhos secundários — banco de evoluções e sobre o app.
class _SecondaryActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext c, BoxConstraints cts) {
        final bool twoCols = cts.maxWidth >= 520;
        final List<Widget> tiles = <Widget>[
          _SecondaryTile(
            icon: Icons.folder_open_rounded,
            title: 'Banco de evoluções',
            subtitle: 'Reabra, edite, copie ou exporte qualquer registro.',
            accent: AppColors.teal,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DatabaseScreen(),
              ),
            ),
          ),
          _SecondaryTile(
            icon: Icons.info_outline_rounded,
            title: 'Sobre o sistema',
            subtitle: 'Versão, privacidade e como o app armazena seus dados.',
            accent: AppColors.amber,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SettingsScreen(),
              ),
            ),
          ),
        ];
        if (twoCols) {
          return Row(
            children: <Widget>[
              Expanded(child: tiles[0]),
              const SizedBox(width: 12),
              Expanded(child: tiles[1]),
            ],
          );
        }
        return Column(
          children: <Widget>[
            tiles[0],
            const SizedBox(height: 12),
            tiles[1],
          ],
        );
      },
    );
  }
}

class _SecondaryTile extends StatelessWidget {
  const _SecondaryTile({
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      accent,
                      Color.lerp(accent, Colors.black, 0.15) ?? accent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: accent.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                      spreadRadius: -4,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList({required this.items});
  final List<SavedEvolution> items;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.auto_stories_rounded,
                  color: AppColors.teal, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              'Nenhuma evolução salva ainda',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'As evoluções que você gerar e salvar aparecem aqui para reabrir, copiar ou exportar.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
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

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.evo});
  final SavedEvolution evo;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ViewSavedScreen(evolution: evo),
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

/// Aviso discreto sobre privacidade — útil de fato para a enfermagem,
/// que costuma trabalhar com dados sensíveis de pacientes.
class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.tealLight.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.lock_outline_rounded,
              size: 20, color: AppColors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Dados armazenados apenas neste dispositivo. Nada é enviado para servidores externos.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
