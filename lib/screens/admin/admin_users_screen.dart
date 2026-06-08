import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin_guard.dart';
import '../../widgets/app_header.dart';
import 'admin_user_detail_screen.dart';

/// Lista completa de usuários com CRUD admin.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _query = '';
  UserRole? _roleFilter;
  bool? _activeFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().hydrate();
    });
  }

  List<AppUser> _applyFilters(List<AppUser> list) {
    String q = _query.trim().toLowerCase();
    Iterable<AppUser> it = list;
    if (q.isNotEmpty) {
      it = it.where((AppUser u) =>
          u.displayName.toLowerCase().contains(q) ||
          u.username.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q));
    }
    if (_roleFilter != null) {
      it = it.where((AppUser u) => u.role == _roleFilter);
    }
    if (_activeFilter != null) {
      it = it.where((AppUser u) => u.active == _activeFilter);
    }
    return it.toList();
  }

  Future<void> _openCreate() async {
    final _UserFormResult? result = await showDialog<_UserFormResult>(
      context: context,
      builder: (_) => const _UserFormDialog(),
    );
    if (!mounted || result == null) return;
    final AdminProvider admin = context.read<AdminProvider>();
    final AuthProvider auth = context.read<AuthProvider>();
    try {
      final CreatedUser created = await admin.createUser(
        admin: auth.currentUser!,
        username: result.username,
        displayName: result.displayName,
        email: result.email,
        role: result.role,
        corenUF: result.corenUF,
        corenNumero: result.corenNumero,
        password: result.password,
      );
      if (!mounted) return;
      await _showTempPasswordDialog(created);
    } on AuthException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    }
  }

  Future<void> _openEdit(AppUser user) async {
    final _UserFormResult? result = await showDialog<_UserFormResult>(
      context: context,
      builder: (_) => _UserFormDialog(initial: user),
    );
    if (!mounted || result == null) return;
    final AdminProvider admin = context.read<AdminProvider>();
    final AuthProvider auth = context.read<AuthProvider>();
    try {
      await admin.updateUser(
        admin: auth.currentUser!,
        targetUserId: user.id,
        displayName: result.displayName,
        email: result.email,
        role: result.role,
        active: result.active,
        corenUF: result.corenUF,
        corenNumero: result.corenNumero,
      );
      if (user.id == auth.currentUser?.id) {
        auth.refreshCurrentUser();
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    }
  }

  Future<void> _confirmDelete(AppUser user) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Excluir usuário'),
        content: Text(
          'Tem certeza que deseja excluir ${user.displayName} (@${user.username})? '
          'Esta ação não pode ser desfeita.',
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
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final AdminProvider admin = context.read<AdminProvider>();
    final AuthProvider auth = context.read<AuthProvider>();
    try {
      await admin.deleteUser(
        admin: auth.currentUser!,
        targetUserId: user.id,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    }
  }

  Future<void> _resetPassword(AppUser user) async {
    final AdminProvider admin = context.read<AdminProvider>();
    final AuthProvider auth = context.read<AuthProvider>();
    try {
      final String temp = await admin.resetPassword(
        admin: auth.currentUser!,
        targetUserId: user.id,
      );
      if (!mounted) return;
      await _showTempPasswordDialog(
        CreatedUser(user, temp),
        title: 'Senha redefinida',
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    }
  }

  Future<void> _unlock(AppUser user) async {
    final AdminProvider admin = context.read<AdminProvider>();
    final AuthProvider auth = context.read<AuthProvider>();
    try {
      await admin.unlockUser(
        admin: auth.currentUser!,
        targetUserId: user.id,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.danger,
        content: Text(message),
      ),
    );
  }

  Future<void> _showTempPasswordDialog(
    CreatedUser created, {
    String title = 'Usuário criado',
  }) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Compartilhe a senha temporária com ${created.user.displayName}. '
              'Ele(a) será obrigado(a) a trocar no primeiro login.',
            ),
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.indigoLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(
                    color: AppColors.indigo.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: SelectableText(
                      created.temporaryPassword,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                        color: AppColors.indigoDark,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                          text: created.temporaryPassword));
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                            content: Text('Senha copiada para a área de transferência.')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded),
                    tooltip: 'Copiar',
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Guard de segurança: somente administradores acessam esta tela.
    if (!context.watch<AuthProvider>().isAdmin) {
      return const AdminAccessDenied();
    }
    final AdminProvider admin = context.watch<AdminProvider>();
    final List<AppUser> users = _applyFilters(admin.users);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: const AppHeader(showHomeButton: false),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Novo usuário'),
      ),
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
                      Text('Usuários do sistema',
                          style: theme.textTheme.headlineMedium),
                      Text(
                        '${admin.totalUsers} cadastrados • ${admin.activeUsers} ativos • ${admin.totalAdmins} admin',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _FilterBar(
              query: _query,
              onQueryChanged: (String v) => setState(() => _query = v),
              role: _roleFilter,
              onRole: (UserRole? r) => setState(() => _roleFilter = r),
              active: _activeFilter,
              onActive: (bool? v) => setState(() => _activeFilter = v),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: users.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhum usuário corresponde aos filtros.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (BuildContext c, int i) => _UserRow(
                        user: users[i],
                        onEdit: () => _openEdit(users[i]),
                        onResetPassword: () => _resetPassword(users[i]),
                        onDelete: () => _confirmDelete(users[i]),
                        onUnlock: () => _unlock(users[i]),
                        onOpen: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                AdminUserDetailScreen(userId: users[i].id),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.query,
    required this.onQueryChanged,
    required this.role,
    required this.onRole,
    required this.active,
    required this.onActive,
  });
  final String query;
  final ValueChanged<String> onQueryChanged;
  final UserRole? role;
  final ValueChanged<UserRole?> onRole;
  final bool? active;
  final ValueChanged<bool?> onActive;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final bool wide = c.maxWidth >= 720;
        final Widget search = TextField(
          onChanged: onQueryChanged,
          decoration: const InputDecoration(
            hintText: 'Buscar por nome, usuário ou e-mail',
            prefixIcon: Icon(Icons.search_rounded),
            isDense: true,
          ),
        );
        final Widget chips = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ChoiceChip(
              label: const Text('Todos os cargos'),
              selected: role == null,
              onSelected: (_) => onRole(null),
            ),
            ChoiceChip(
              label: const Text('Administradores'),
              selected: role == UserRole.admin,
              onSelected: (_) => onRole(UserRole.admin),
            ),
            ChoiceChip(
              label: const Text('Padrão'),
              selected: role == UserRole.standard,
              onSelected: (_) => onRole(UserRole.standard),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Ativos'),
              selected: active == true,
              onSelected: (_) => onActive(active == true ? null : true),
            ),
            ChoiceChip(
              label: const Text('Inativos'),
              selected: active == false,
              onSelected: (_) => onActive(active == false ? null : false),
            ),
          ],
        );
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(child: search),
              const SizedBox(width: 16),
              chips,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            search,
            const SizedBox(height: 10),
            chips,
          ],
        );
      },
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.onEdit,
    required this.onResetPassword,
    required this.onDelete,
    required this.onUnlock,
    required this.onOpen,
  });
  final AppUser user;
  final VoidCallback onEdit;
  final VoidCallback onResetPassword;
  final VoidCallback onDelete;
  final VoidCallback onUnlock;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color roleColor =
        user.isAdmin ? AppColors.violet : AppColors.teal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        user.displayName,
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        user.role.shortLabel,
                        style: TextStyle(
                          color: roleColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    if (!user.active) ...<Widget>[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.dangerLight,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'INATIVO',
                          style: TextStyle(
                            color: AppColors.dangerDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 10.5,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                    if (user.isLocked) ...<Widget>[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.amberLight,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'BLOQUEADO',
                          style: TextStyle(
                            color: AppColors.warningDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 10.5,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '@${user.username}'
                  '${user.email.isNotEmpty ? ' · ${user.email}' : ''}',
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.lastLoginAt != null)
                  Text(
                    'Último login: ${_fmtDate(user.lastLoginAt!)}',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz_rounded),
            onSelected: (String v) {
              switch (v) {
                case 'open':
                  onOpen();
                  break;
                case 'edit':
                  onEdit();
                  break;
                case 'reset':
                  onResetPassword();
                  break;
                case 'unlock':
                  onUnlock();
                  break;
                case 'delete':
                  onDelete();
                  break;
              }
            },
            itemBuilder: (BuildContext ctx) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'open',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.timeline_rounded),
                  title: Text('Ver jornada'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'edit',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.edit_rounded),
                  title: Text('Editar'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'reset',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.lock_reset_rounded),
                  title: Text('Redefinir senha'),
                ),
              ),
              if (user.isLocked)
                const PopupMenuItem<String>(
                  value: 'unlock',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.lock_open_rounded),
                    title: Text('Desbloquear conta'),
                  ),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'delete',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_outline_rounded,
                      color: AppColors.danger),
                  title: Text('Excluir',
                      style: TextStyle(color: AppColors.danger)),
                ),
              ),
            ],
          ),
        ],
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

  String _fmtDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }
}

// ============================================================
// Form dialog (criar / editar usuário)
// ============================================================

class _UserFormResult {
  _UserFormResult({
    required this.username,
    required this.displayName,
    required this.email,
    required this.role,
    required this.active,
    required this.corenUF,
    required this.corenNumero,
    this.password,
  });
  final String username;
  final String displayName;
  final String email;
  final UserRole role;
  final bool active;
  final String? corenUF;
  final String? corenNumero;
  final String? password;
}

class _UserFormDialog extends StatefulWidget {
  const _UserFormDialog({this.initial});
  final AppUser? initial;
  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _username;
  late final TextEditingController _displayName;
  late final TextEditingController _email;
  late final TextEditingController _corenUF;
  late final TextEditingController _corenNumero;
  final TextEditingController _password = TextEditingController();
  UserRole _role = UserRole.standard;
  bool _active = true;
  bool _customPassword = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final AppUser? u = widget.initial;
    _username = TextEditingController(text: u?.username ?? '');
    _displayName = TextEditingController(text: u?.displayName ?? '');
    _email = TextEditingController(text: u?.email ?? '');
    _corenUF = TextEditingController(text: u?.corenUF ?? '');
    _corenNumero = TextEditingController(text: u?.corenNumero ?? '');
    _role = u?.role ?? UserRole.standard;
    _active = u?.active ?? true;
  }

  @override
  void dispose() {
    _username.dispose();
    _displayName.dispose();
    _email.dispose();
    _corenUF.dispose();
    _corenNumero.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_UserFormResult(
      username: _username.text.trim(),
      displayName: _displayName.text.trim(),
      email: _email.text.trim(),
      role: _role,
      active: _active,
      corenUF: _corenUF.text.trim().isEmpty ? null : _corenUF.text.trim(),
      corenNumero:
          _corenNumero.text.trim().isEmpty ? null : _corenNumero.text.trim(),
      password: _customPassword && _password.text.isNotEmpty
          ? _password.text
          : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Icon(
                          _isEdit
                              ? Icons.manage_accounts_rounded
                              : Icons.person_add_alt_1_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isEdit ? 'Editar usuário' : 'Novo usuário',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _displayName,
                    decoration: const InputDecoration(
                      labelText: 'Nome completo',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (String? v) =>
                        (v == null || v.trim().length < 3)
                            ? 'Informe o nome (mínimo 3 caracteres).'
                            : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _username,
                    enabled: !_isEdit,
                    decoration: const InputDecoration(
                      labelText: 'Usuário (login)',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                      helperText:
                          'Minúsculas, números, ponto, traço e _ (3–32).',
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (String? v) {
                      if (_isEdit) return null;
                      final String s = (v ?? '').trim();
                      if (s.length < 3) {
                        return 'Mínimo de 3 caracteres.';
                      }
                      if (!RegExp(r'^[a-z0-9_.\-]{3,32}$').hasMatch(s)) {
                        return 'Caracteres inválidos.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: 'E-mail (opcional)',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (String? v) {
                      final String s = (v ?? '').trim();
                      if (s.isEmpty) return null;
                      if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(s)) {
                        return 'E-mail inválido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextFormField(
                          controller: _corenUF,
                          maxLength: 2,
                          decoration: const InputDecoration(
                            labelText: 'COREN UF',
                            counterText: '',
                            prefixIcon: Icon(Icons.flag_outlined),
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _corenNumero,
                          decoration: const InputDecoration(
                            labelText: 'Nº COREN',
                            prefixIcon:
                                Icon(Icons.confirmation_number_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Cargo',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  SegmentedButton<UserRole>(
                    segments: const <ButtonSegment<UserRole>>[
                      ButtonSegment<UserRole>(
                        value: UserRole.standard,
                        icon: Icon(Icons.person_rounded),
                        label: Text('Padrão'),
                      ),
                      ButtonSegment<UserRole>(
                        value: UserRole.admin,
                        icon: Icon(Icons.shield_rounded),
                        label: Text('Admin'),
                      ),
                    ],
                    selected: <UserRole>{_role},
                    onSelectionChanged: (Set<UserRole> s) =>
                        setState(() => _role = s.first),
                  ),
                  if (_isEdit) ...<Widget>[
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Conta ativa'),
                      subtitle: const Text(
                          'Se desativada, o usuário não consegue fazer login.'),
                      value: _active,
                      onChanged: (bool v) => setState(() => _active = v),
                    ),
                  ],
                  if (!_isEdit) ...<Widget>[
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Definir senha inicial'),
                      subtitle: const Text(
                          'Se desligado, gera senha temporária forte automaticamente.'),
                      value: _customPassword,
                      onChanged: (bool v) =>
                          setState(() => _customPassword = v),
                    ),
                    if (_customPassword)
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Senha inicial',
                          prefixIcon: Icon(Icons.password_rounded),
                        ),
                        validator: (String? v) {
                          if (!_customPassword) return null;
                          if ((v ?? '').length < 8) {
                            return 'Mínimo de 8 caracteres.';
                          }
                          return null;
                        },
                      ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _submit,
                        icon: Icon(_isEdit
                            ? Icons.save_rounded
                            : Icons.check_rounded),
                        label: Text(_isEdit ? 'Salvar' : 'Criar usuário'),
                      ),
                    ],
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
