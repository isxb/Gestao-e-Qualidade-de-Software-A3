import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';

/// Tela de entrada do sistema. Design moderno com gradiente suave,
/// cartão elevado centralizado no desktop e hero full-screen no mobile.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _userCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final AuthProvider auth = context.read<AuthProvider>();
    final bool ok = await auth.login(
      username: _userCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!ok) {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Size size = MediaQuery.sizeOf(context);
    final bool isWide = size.width >= AppTheme.tabletBreakpoint;

    final Widget hero = _LoginHero(isDark: isDark);
    final Widget card = _LoginCard(
      formKey: _formKey,
      userCtrl: _userCtrl,
      passCtrl: _passCtrl,
      obscure: _obscure,
      toggleObscure: () => setState(() => _obscure = !_obscure),
      onSubmit: _submit,
      submitting: _submitting,
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFF0B0F1A),
                    Color(0xFF1C2338),
                    Color(0xFF241A3D),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFFEEF2FF),
                    Color(0xFFF5F3FF),
                    Color(0xFFFDF2F8),
                  ],
                ),
        ),
        child: Stack(
          children: <Widget>[
            const _DecorBlobs(),
            SafeArea(
              child: isWide
                  ? Row(
                      children: <Widget>[
                        Expanded(child: hero),
                        Expanded(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 460),
                              child: Padding(
                                padding: const EdgeInsets.all(28),
                                child: card,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: <Widget>[
                          const SizedBox(height: 12),
                          _LoginHero(isDark: isDark, compact: true),
                          const SizedBox(height: 24),
                          card,
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero({required this.isDark, this.compact = false});
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const Color onDark = Colors.white;
    final Color fg = isDark ? onDark : AppColors.lightText;
    if (compact) {
      return Column(
        children: <Widget>[
          AppLogoLockup(
            logoSize: 52,
            subtitle: 'Evoluções clínicas de enfermagem',
            color: fg,
          ),
          const SizedBox(height: 14),
          Text(
            'Entre para continuar o atendimento.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: fg.withValues(alpha: 0.75),
                ),
          ),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(56, 48, 48, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          AppLogoLockup(
            logoSize: 72,
            subtitle: 'Plataforma clínica de enfermagem',
            color: fg,
          ),
          const SizedBox(height: 36),
          Text(
            'Evoluções de enfermagem,\nmais rápidas e precisas.',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: fg,
                  height: 1.1,
                ),
          ),
          const SizedBox(height: 20),
          Text(
            'Geração por template personalizado, histórico auditável e '
            'fluxos pensados para o plantão. Acesse com a sua '
            'conta para continuar.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: fg.withValues(alpha: 0.78),
                  height: 1.55,
                ),
          ),
          const SizedBox(height: 32),
          const _FeatureBullets(),
        ],
      ),
    );
  }
}

class _FeatureBullets extends StatelessWidget {
  const _FeatureBullets();
  @override
  Widget build(BuildContext context) {
    final List<(IconData, String)> items = <(IconData, String)>[
      (Icons.shield_moon_rounded, 'Login seguro com bloqueio automático'),
      (Icons.timeline_rounded, 'Auditoria completa por profissional'),
      (Icons.bolt_rounded, 'Geração em poucos segundos'),
    ];
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fg = isDark ? Colors.white : AppColors.lightText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final (IconData i, String t) in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(i, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  t,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: fg.withValues(alpha: 0.85),
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DecorBlobs extends StatelessWidget {
  const _DecorBlobs();
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -120,
            right: -80,
            child: _Blob(
              color: AppColors.pink.withValues(alpha: 0.25),
              size: 300,
            ),
          ),
          Positioned(
            bottom: -140,
            left: -60,
            child: _Blob(
              color: AppColors.indigo.withValues(alpha: 0.25),
              size: 340,
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.userCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.toggleObscure,
    required this.onSubmit,
    required this.submitting,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController userCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final VoidCallback toggleObscure;
  final VoidCallback onSubmit;
  final bool submitting;

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: AppColors.elevatedShadow(opacity: isDark ? 0.3 : 0.12),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(
                    Icons.lock_open_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Entrar',
                        style: theme.textTheme.headlineSmall,
                      ),
                      Text(
                        'Acesse o painel com suas credenciais.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: userCtrl,
              enabled: !submitting,
              autofillHints: const <String>[AutofillHints.username],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Usuário',
                hintText: 'seu.usuario',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (String? v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Informe o usuário.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: passCtrl,
              enabled: !submitting,
              obscureText: obscure,
              autofillHints: const <String>[AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                labelText: 'Senha',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: toggleObscure,
                  icon: Icon(obscure
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded),
                  tooltip: obscure ? 'Mostrar senha' : 'Ocultar senha',
                ),
              ),
              validator: (String? v) {
                if (v == null || v.isEmpty) return 'Informe a senha.';
                return null;
              },
            ),
            if (auth.lastError != null) ...<Widget>[
              const SizedBox(height: 14),
              _ErrorBanner(message: auth.lastError!),
            ],
            const SizedBox(height: 18),
            SizedBox(
              height: 50,
              child: _GradientButton(
                loading: submitting,
                onPressed: submitting ? null : onSubmit,
                label: submitting ? 'Entrando...' : 'Entrar no sistema',
                icon: Icons.login_rounded,
              ),
            ),
            const SizedBox(height: 14),
            const _FirstAccessHint(),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.error_outline_rounded,
              size: 20, color: AppColors.dangerDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.dangerDark,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FirstAccessHint extends StatelessWidget {
  const _FirstAccessHint();
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.indigoLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppColors.indigo.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.info_outline_rounded,
              size: 20, color: AppColors.indigo),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                children: <InlineSpan>[
                  const TextSpan(
                    text: 'Primeiro acesso? ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: 'admin',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(text: '  /  '),
                  TextSpan(
                    text: 'admin123',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(
                    text: ' — troque a senha no primeiro login.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.onPressed,
    required this.icon,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null;
    return Opacity(
      opacity: disabled ? 0.78 : 1,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.indigo.withValues(alpha: 0.35),
                blurRadius: 22,
                offset: const Offset(0, 10),
                spreadRadius: -6,
              ),
            ],
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: Colors.white, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
