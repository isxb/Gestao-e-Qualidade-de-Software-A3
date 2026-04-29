import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/crypto_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_check.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/google_sign_in_button.dart';

/// Página pública de cadastro de usuário comum.
/// Reaproveita a estética da tela de login (gradient suave + blobs +
/// card central). Usuários criados aqui são sempre [UserRole.standard].
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _userCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();

  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  String _password = '';

  @override
  void initState() {
    super.initState();
    _passCtrl.addListener(() {
      if (_password != _passCtrl.text) {
        setState(() => _password = _passCtrl.text);
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final AuthProvider auth = context.read<AuthProvider>();
    final bool ok = await auth.register(
      username: _userCtrl.text.trim(),
      displayName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!ok) {
      HapticFeedback.mediumImpact();
    }
    // Em sucesso, o AuthGate redireciona automaticamente para a Home.
  }

  Future<void> _handleGoogle() async {
    if (_submitting) return;
    if (!PlatformCheck.supportsGoogleSignIn) {
      _showGoogleUnsupported();
      return;
    }
    setState(() => _submitting = true);
    final AuthProvider auth = context.read<AuthProvider>();
    final bool ok = await auth.loginWithGoogle();
    if (!mounted) return;
    setState(() => _submitting = false);
    // Em sucesso, o AuthGate redireciona automaticamente para a Home.
    if (!ok && auth.lastError != null) {
      HapticFeedback.mediumImpact();
    }
  }

  void _showGoogleUnsupported() {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Login com Google'),
        content: const Text(
          'Login com Google não está disponível nesta plataforma. '
          'Crie sua conta com e-mail e senha para continuar.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Size size = MediaQuery.sizeOf(context);
    final bool isWide = size.width >= AppTheme.tabletBreakpoint;

    final Widget hero = _RegisterHero(isDark: isDark);
    final Widget card = _RegisterCard(
      formKey: _formKey,
      nameCtrl: _nameCtrl,
      emailCtrl: _emailCtrl,
      userCtrl: _userCtrl,
      passCtrl: _passCtrl,
      confirmCtrl: _confirmCtrl,
      obscure: _obscure,
      obscureConfirm: _obscureConfirm,
      toggleObscure: () => setState(() => _obscure = !_obscure),
      toggleObscureConfirm: () =>
          setState(() => _obscureConfirm = !_obscureConfirm),
      onSubmit: _submit,
      onGoogle: _handleGoogle,
      submitting: _submitting,
      password: _password,
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFF0B1422),
                    Color(0xFF152133),
                    Color(0xFF1D2C42),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFFF6F9FC),
                    Color(0xFFEDF3F8),
                    Color(0xFFD4F0EC),
                  ],
                ),
        ),
        child: Stack(
          children: <Widget>[
            const _DecorBlobs(),
            SafeArea(
              child: Stack(
                children: <Widget>[
                  Positioned(
                    top: 8,
                    left: 8,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: isDark ? Colors.white : AppColors.lightText,
                      ),
                      tooltip: 'Voltar para o login',
                    ),
                  ),
                  isWide
                      ? Row(
                          children: <Widget>[
                            Expanded(child: hero),
                            Expanded(
                              child: Center(
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 480),
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
                          padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                          child: Column(
                            children: <Widget>[
                              _RegisterHero(isDark: isDark, compact: true),
                              const SizedBox(height: 24),
                              card,
                            ],
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterHero extends StatelessWidget {
  const _RegisterHero({required this.isDark, this.compact = false});
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color fg = isDark ? Colors.white : AppColors.lightText;
    if (compact) {
      return Column(
        children: <Widget>[
          AppLogoLockup(
            logoSize: 52,
            subtitle: 'Crie sua conta',
            color: fg,
          ),
          const SizedBox(height: 14),
          Text(
            'Leva menos de um minuto.',
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
            subtitle: 'Plataforma clínica inteligente',
            color: fg,
          ),
          const SizedBox(height: 36),
          Text(
            'Crie sua conta\ne acelere seus plantões.',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: fg,
                  height: 1.1,
                ),
          ),
          const SizedBox(height: 20),
          Text(
            'Você está a poucos campos de gerar evoluções de enfermagem '
            'estruturadas em segundos. Os dados ficam salvos com '
            'segurança no seu dispositivo.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: fg.withValues(alpha: 0.78),
                  height: 1.55,
                ),
          ),
        ],
      ),
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
              color: AppColors.indigo.withValues(alpha: 0.18),
              size: 300,
            ),
          ),
          Positioned(
            bottom: -140,
            left: -60,
            child: _Blob(
              color: AppColors.teal.withValues(alpha: 0.18),
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

class _RegisterCard extends StatelessWidget {
  const _RegisterCard({
    required this.formKey,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.userCtrl,
    required this.passCtrl,
    required this.confirmCtrl,
    required this.obscure,
    required this.obscureConfirm,
    required this.toggleObscure,
    required this.toggleObscureConfirm,
    required this.onSubmit,
    required this.onGoogle,
    required this.submitting,
    required this.password,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController userCtrl;
  final TextEditingController passCtrl;
  final TextEditingController confirmCtrl;
  final bool obscure;
  final bool obscureConfirm;
  final VoidCallback toggleObscure;
  final VoidCallback toggleObscureConfirm;
  final VoidCallback onSubmit;
  final VoidCallback onGoogle;
  final bool submitting;
  final String password;

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
                    Icons.person_add_alt_1_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text('Criar conta', style: theme.textTheme.headlineSmall),
                      Text(
                        'Preencha seus dados para começar.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: nameCtrl,
              enabled: !submitting,
              autofillHints: const <String>[AutofillHints.name],
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome completo',
                hintText: 'Maria Silva',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (String? v) {
                if (v == null || v.trim().length < 2) {
                  return 'Informe seu nome completo.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: emailCtrl,
              enabled: !submitting,
              autofillHints: const <String>[AutofillHints.email],
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                hintText: 'voce@email.com',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: (String? v) {
                final String t = (v ?? '').trim();
                if (t.isEmpty) return 'Informe seu e-mail.';
                final RegExp re =
                    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                if (!re.hasMatch(t)) return 'E-mail inválido.';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: userCtrl,
              enabled: !submitting,
              autofillHints: const <String>[AutofillHints.newUsername],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Usuário',
                hintText: 'maria.silva',
                helperText: 'Apenas minúsculas, números, "_" e "."',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (String? v) {
                final String t = (v ?? '').trim();
                if (t.isEmpty) return 'Informe um nome de usuário.';
                if (!RegExp(r'^[a-z0-9_.-]{3,32}$').hasMatch(t)) {
                  return 'Use 3–32 caracteres em minúsculas, números, "_" ou ".".';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: passCtrl,
              enabled: !submitting,
              obscureText: obscure,
              autofillHints: const <String>[AutofillHints.newPassword],
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Senha',
                helperText: 'Mínimo 8 caracteres com letras e números.',
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
                final String t = v ?? '';
                if (t.isEmpty) return 'Crie uma senha.';
                if (t.length < 8) return 'Pelo menos 8 caracteres.';
                if (CryptoService.passwordStrength(t) < 2) {
                  return 'Combine letras, números e/ou símbolos.';
                }
                return null;
              },
            ),
            if (password.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              _PasswordStrength(password: password),
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: confirmCtrl,
              enabled: !submitting,
              obscureText: obscureConfirm,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                labelText: 'Confirmar senha',
                prefixIcon: const Icon(Icons.lock_reset_rounded),
                suffixIcon: IconButton(
                  onPressed: toggleObscureConfirm,
                  icon: Icon(obscureConfirm
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded),
                  tooltip: obscureConfirm ? 'Mostrar senha' : 'Ocultar senha',
                ),
              ),
              validator: (String? v) {
                if (v == null || v.isEmpty) return 'Confirme sua senha.';
                if (v != passCtrl.text) return 'As senhas não conferem.';
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
                label: submitting ? 'Criando conta...' : 'Criar conta',
                icon: Icons.person_add_alt_1_rounded,
              ),
            ),
            const SizedBox(height: 18),
            const _OrDivider(),
            const SizedBox(height: 18),
            GoogleSignInButton(onPressed: submitting ? null : onGoogle),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Já tem uma conta?',
                  style: theme.textTheme.bodySmall,
                ),
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Entrar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    final int score = CryptoService.passwordStrength(password);
    final String label = CryptoService.passwordStrengthLabel(score);
    final List<Color> colors = <Color>[
      AppColors.danger,
      AppColors.warning,
      AppColors.amber,
      AppColors.success,
      AppColors.success,
    ];
    final Color color = colors[score.clamp(0, 4)];
    return Row(
      children: <Widget>[
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ((score + 1) / 5).clamp(0.05, 1),
              minHeight: 6,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Expanded(child: Divider(color: theme.dividerColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'ou',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(child: Divider(color: theme.dividerColor)),
      ],
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
                color: AppColors.indigo.withValues(alpha: 0.32),
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
