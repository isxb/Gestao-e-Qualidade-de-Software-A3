import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/crypto_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';

/// Tela de troca de senha. Usada tanto no primeiro acesso (forçada)
/// quanto em "Alterar minha senha" a partir do menu do usuário.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({
    super.key,
    this.forced = false,
    this.title,
  });

  final bool forced;
  final String? title;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _old = TextEditingController();
  final TextEditingController _new = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _showOld = false;
  bool _showNew = false;
  bool _submitting = false;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final AuthProvider auth = context.read<AuthProvider>();
    final bool ok = await auth.changeOwnPassword(
      oldPassword: _old.text,
      newPassword: _new.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha atualizada com sucesso.')),
      );
      if (!widget.forced) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final AuthProvider auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: widget.forced
          ? null
          : AppBar(
              title: Text(widget.title ?? 'Alterar minha senha'),
            ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.subtleDarkGradient
              : AppColors.subtleLightGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                    boxShadow: AppColors.softShadow(),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (widget.forced)
                          Column(
                            children: <Widget>[
                              const AppLogo(size: 56, glow: true),
                              const SizedBox(height: 16),
                              Text(
                                'Defina a sua nova senha',
                                style: theme.textTheme.headlineSmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Por segurança, atualize a senha temporária '
                                'antes de continuar.',
                                style: theme.textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 22),
                            ],
                          )
                        else
                          Row(
                            children: <Widget>[
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: AppColors.brandGradient,
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusSm),
                                ),
                                child: const Icon(Icons.key_rounded,
                                    color: Colors.white),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text('Trocar senha',
                                        style: theme.textTheme.headlineSmall),
                                    Text(
                                      'Defina uma senha forte e pessoal.',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _old,
                          obscureText: !_showOld,
                          enabled: !_submitting,
                          decoration: InputDecoration(
                            labelText: widget.forced
                                ? 'Senha temporária atual'
                                : 'Senha atual',
                            prefixIcon:
                                const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _showOld = !_showOld),
                              icon: Icon(_showOld
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded),
                            ),
                          ),
                          validator: (String? v) =>
                              (v == null || v.isEmpty) ? 'Obrigatório.' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _new,
                          obscureText: !_showNew,
                          enabled: !_submitting,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Nova senha',
                            prefixIcon: const Icon(Icons.lock_reset_rounded),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _showNew = !_showNew),
                              icon: Icon(_showNew
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded),
                            ),
                          ),
                          validator: (String? v) {
                            if (v == null || v.length < 8) {
                              return 'Mínimo de 8 caracteres.';
                            }
                            if (CryptoService.passwordStrength(v) < 2) {
                              return 'Inclua letras, números ou símbolos.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        _StrengthMeter(password: _new.text),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirm,
                          obscureText: !_showNew,
                          enabled: !_submitting,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: const InputDecoration(
                            labelText: 'Confirmar nova senha',
                            prefixIcon: Icon(Icons.verified_user_rounded),
                          ),
                          validator: (String? v) {
                            if (v != _new.text) {
                              return 'As senhas não coincidem.';
                            }
                            return null;
                          },
                        ),
                        if (auth.lastError != null) ...<Widget>[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.dangerLight,
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusSm),
                              border: Border.all(
                                  color: AppColors.danger
                                      .withValues(alpha: 0.35)),
                            ),
                            child: Row(
                              children: <Widget>[
                                const Icon(Icons.error_outline_rounded,
                                    size: 20, color: AppColors.dangerDark),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    auth.lastError!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.dangerDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: _submitting ? null : _submit,
                            icon: _submitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.check_rounded),
                            label: Text(_submitting
                                ? 'Salvando...'
                                : 'Atualizar senha'),
                          ),
                        ),
                        if (widget.forced) ...<Widget>[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _submitting
                                ? null
                                : () async {
                                    await context.read<AuthProvider>().logout();
                                  },
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: const Text('Sair'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    final int score =
        password.isEmpty ? 0 : CryptoService.passwordStrength(password);
    final String label = CryptoService.passwordStrengthLabel(score);
    final List<Color> segmentColors = <Color>[
      AppColors.danger,
      AppColors.warning,
      AppColors.info,
      AppColors.success,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            for (int i = 0; i < 4; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 3 ? 4 : 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 6,
                    decoration: BoxDecoration(
                      color: score > i
                          ? segmentColors[i]
                          : Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          password.isEmpty ? 'Use ao menos 8 caracteres.' : 'Força: $label',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
