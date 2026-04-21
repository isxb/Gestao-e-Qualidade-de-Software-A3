import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/auth/change_password_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_logo.dart';

/// Header global com gradiente assinado. Exibe o logotipo com wordmark,
/// um botão opcional de Início, um slot livre (trailing) e o menu de
/// usuário à direita, sensível ao papel (admin tem atalho para o painel).
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.showHomeButton = false,
    this.onHomeTap,
    this.trailing,
    this.compact = false,
  });

  final bool showHomeButton;
  final VoidCallback? onHomeTap;
  final Widget? trailing;
  final bool compact;

  @override
  Size get preferredSize => Size.fromHeight(compact ? 64 : 76);

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final AppUser? user = auth.currentUser;

    return Container(
      height: preferredSize.height,
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 4),
            blurRadius: 20,
            spreadRadius: -4,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: <Widget>[
            const AppLogoLockup(
              logoSize: 40,
              color: Colors.white,
              compact: true,
            ),
            const Spacer(),
            if (trailing != null) ...<Widget>[
              trailing!,
              const SizedBox(width: 8),
            ],
            if (showHomeButton)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _HeaderButton(
                  onTap: onHomeTap,
                  icon: Icons.home_rounded,
                  label: 'Início',
                ),
              ),
            if (user != null) _UserMenu(user: user),
          ],
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.onTap,
    required this.icon,
    required this.label,
  });
  final VoidCallback? onTap;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserMenu extends StatelessWidget {
  const _UserMenu({required this.user});
  final AppUser user;

  String get _initials {
    final List<String> parts = user.displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final String a = parts.first.characters.first;
    final String b =
        parts.length > 1 ? parts.last.characters.first : '';
    return (a + b).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppTheme.isMobile(context);
    return PopupMenuButton<String>(
      tooltip: 'Menu do usuário',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      onSelected: (String value) async {
        switch (value) {
          case 'profile':
            await Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const ChangePasswordScreen(),
            ));
            break;
          case 'admin':
            await Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const AdminHomeScreen(),
            ));
            break;
          case 'logout':
            await context.read<AuthProvider>().logout();
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            constraints: const BoxConstraints(minWidth: 240),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  user.displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '@${user.username} · ${user.role.label}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: <Widget>[
              Icon(Icons.password_rounded, size: 20),
              SizedBox(width: 12),
              Text('Alterar minha senha'),
            ],
          ),
        ),
        if (user.isAdmin)
          const PopupMenuItem<String>(
            value: 'admin',
            child: Row(
              children: <Widget>[
                Icon(Icons.shield_rounded,
                    size: 20, color: AppColors.indigo),
                SizedBox(width: 12),
                Text('Painel administrativo'),
              ],
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: <Widget>[
              Icon(Icons.logout_rounded, size: 20, color: AppColors.danger),
              SizedBox(width: 12),
              Text('Sair'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 4 : 6,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.9),
                    Colors.white.withValues(alpha: 0.75),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _initials,
                style: const TextStyle(
                  color: AppColors.indigoDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            if (!isMobile) ...<Widget>[
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      user.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      user.role.label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ] else
              const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
