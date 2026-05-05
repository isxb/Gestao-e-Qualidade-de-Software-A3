import 'package:flutter/material.dart';

/// Tipos de eventos rastreados pelo sistema.
/// Ampliar conforme novas ações forem adicionadas.
enum ActivityType {
  // auth
  loginSuccess,
  loginFailed,
  logout,
  sessionExpired,
  passwordChanged,
  passwordResetByAdmin,
  accountLocked,
  accountUnlocked,
  mustChangePasswordPrompted,

  // admin — usuários
  userCreated,
  userUpdated,
  userDeleted,
  userRoleChanged,
  userActivated,
  userDeactivated,

  // admin — sistema
  logsCleared,
  dataExported,
  dataImported,

  // evoluções
  evolutionStarted,
  evolutionGenerated,
  evolutionGenerationFailed,
  evolutionSaved,
  evolutionEdited,
  evolutionDeleted,
  evolutionCopied,

  // templates
  templateSaved,
  templateUpdated,
  templateDeleted,
  templateApplied,

  // navegação / genérico
  screenViewed,
  custom,
}

/// Categoria visual usada para colorir ícones e linhas da timeline.
enum LogCategory { auth, admin, evolution, settings, navigation, system }

extension ActivityTypeX on ActivityType {
  LogCategory get category {
    switch (this) {
      case ActivityType.loginSuccess:
      case ActivityType.loginFailed:
      case ActivityType.logout:
      case ActivityType.sessionExpired:
      case ActivityType.passwordChanged:
      case ActivityType.passwordResetByAdmin:
      case ActivityType.accountLocked:
      case ActivityType.accountUnlocked:
      case ActivityType.mustChangePasswordPrompted:
        return LogCategory.auth;
      case ActivityType.userCreated:
      case ActivityType.userUpdated:
      case ActivityType.userDeleted:
      case ActivityType.userRoleChanged:
      case ActivityType.userActivated:
      case ActivityType.userDeactivated:
        return LogCategory.admin;
      case ActivityType.logsCleared:
      case ActivityType.dataExported:
      case ActivityType.dataImported:
        return LogCategory.system;
      case ActivityType.evolutionStarted:
      case ActivityType.evolutionGenerated:
      case ActivityType.evolutionGenerationFailed:
      case ActivityType.evolutionSaved:
      case ActivityType.evolutionEdited:
      case ActivityType.evolutionDeleted:
      case ActivityType.evolutionCopied:
        return LogCategory.evolution;
      case ActivityType.templateSaved:
      case ActivityType.templateUpdated:
      case ActivityType.templateDeleted:
      case ActivityType.templateApplied:
        return LogCategory.settings;
      case ActivityType.screenViewed:
      case ActivityType.custom:
        return LogCategory.navigation;
    }
  }

  IconData get icon {
    switch (this) {
      case ActivityType.loginSuccess:
        return Icons.login_rounded;
      case ActivityType.loginFailed:
        return Icons.report_gmailerrorred_rounded;
      case ActivityType.logout:
        return Icons.logout_rounded;
      case ActivityType.sessionExpired:
        return Icons.timer_off_rounded;
      case ActivityType.passwordChanged:
      case ActivityType.passwordResetByAdmin:
        return Icons.lock_reset_rounded;
      case ActivityType.accountLocked:
        return Icons.lock_rounded;
      case ActivityType.accountUnlocked:
        return Icons.lock_open_rounded;
      case ActivityType.mustChangePasswordPrompted:
        return Icons.shield_outlined;
      case ActivityType.userCreated:
        return Icons.person_add_rounded;
      case ActivityType.userUpdated:
        return Icons.manage_accounts_rounded;
      case ActivityType.userDeleted:
        return Icons.person_remove_rounded;
      case ActivityType.userRoleChanged:
        return Icons.swap_horiz_rounded;
      case ActivityType.userActivated:
        return Icons.toggle_on_rounded;
      case ActivityType.userDeactivated:
        return Icons.toggle_off_rounded;
      case ActivityType.logsCleared:
        return Icons.cleaning_services_rounded;
      case ActivityType.dataExported:
        return Icons.file_download_rounded;
      case ActivityType.dataImported:
        return Icons.file_upload_rounded;
      case ActivityType.evolutionStarted:
        return Icons.play_circle_rounded;
      case ActivityType.evolutionGenerated:
        return Icons.auto_awesome_rounded;
      case ActivityType.evolutionGenerationFailed:
        return Icons.error_outline_rounded;
      case ActivityType.evolutionSaved:
        return Icons.save_rounded;
      case ActivityType.evolutionEdited:
        return Icons.edit_rounded;
      case ActivityType.evolutionDeleted:
        return Icons.delete_rounded;
      case ActivityType.evolutionCopied:
        return Icons.copy_rounded;
      case ActivityType.templateSaved:
        return Icons.bookmark_add_rounded;
      case ActivityType.templateUpdated:
        return Icons.bookmark_rounded;
      case ActivityType.templateDeleted:
        return Icons.bookmark_remove_rounded;
      case ActivityType.templateApplied:
        return Icons.auto_fix_high_rounded;
      case ActivityType.screenViewed:
        return Icons.visibility_rounded;
      case ActivityType.custom:
        return Icons.circle_outlined;
    }
  }

  /// Texto humano em pt-BR usado como ação em listagens.
  String get label {
    switch (this) {
      case ActivityType.loginSuccess:
        return 'Login realizado';
      case ActivityType.loginFailed:
        return 'Tentativa de login falhou';
      case ActivityType.logout:
        return 'Logout';
      case ActivityType.sessionExpired:
        return 'Sessão expirada';
      case ActivityType.passwordChanged:
        return 'Senha alterada';
      case ActivityType.passwordResetByAdmin:
        return 'Senha redefinida pelo admin';
      case ActivityType.accountLocked:
        return 'Conta bloqueada';
      case ActivityType.accountUnlocked:
        return 'Conta desbloqueada';
      case ActivityType.mustChangePasswordPrompted:
        return 'Senha temporária entregue';
      case ActivityType.userCreated:
        return 'Usuário criado';
      case ActivityType.userUpdated:
        return 'Usuário atualizado';
      case ActivityType.userDeleted:
        return 'Usuário excluído';
      case ActivityType.userRoleChanged:
        return 'Cargo alterado';
      case ActivityType.userActivated:
        return 'Usuário ativado';
      case ActivityType.userDeactivated:
        return 'Usuário desativado';
      case ActivityType.logsCleared:
        return 'Logs limpos';
      case ActivityType.dataExported:
        return 'Dados exportados';
      case ActivityType.dataImported:
        return 'Dados importados';
      case ActivityType.evolutionStarted:
        return 'Nova evolução iniciada';
      case ActivityType.evolutionGenerated:
  return 'Evolução gerada';
      case ActivityType.evolutionGenerationFailed:
        return 'Falha na geração';
      case ActivityType.evolutionSaved:
        return 'Evolução salva';
      case ActivityType.evolutionEdited:
        return 'Evolução editada';
      case ActivityType.evolutionDeleted:
        return 'Evolução excluída';
      case ActivityType.evolutionCopied:
        return 'Evolução copiada';
      case ActivityType.templateSaved:
        return 'Template criado';
      case ActivityType.templateUpdated:
        return 'Template atualizado';
      case ActivityType.templateDeleted:
        return 'Template excluído';
      case ActivityType.templateApplied:
        return 'Template aplicado';
      case ActivityType.screenViewed:
        return 'Tela acessada';
      case ActivityType.custom:
        return 'Evento';
    }
  }

  static ActivityType fromString(String raw) {
    return ActivityType.values.firstWhere(
      (ActivityType t) => t.name == raw,
      orElse: () => ActivityType.custom,
    );
  }
}

/// Um evento persistido.
class ActivityLog {
  ActivityLog({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    required this.type,
    required this.description,
    required this.timestamp,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String userId;

  /// Snapshot do nome no momento do evento (sobrevive a renomes / exclusões).
  final String userDisplayName;
  final ActivityType type;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'userId': userId,
        'userDisplayName': userDisplayName,
        'type': type.name,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };

  static ActivityLog fromJson(Map<String, dynamic> j) => ActivityLog(
        id: j['id'] as String,
        userId: j['userId'] as String,
        userDisplayName: j['userDisplayName'] as String,
        type: ActivityTypeX.fromString(j['type'] as String),
        description: j['description'] as String,
        timestamp: DateTime.parse(j['timestamp'] as String),
        metadata: (j['metadata'] as Map<dynamic, dynamic>?)
                ?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      );
}
