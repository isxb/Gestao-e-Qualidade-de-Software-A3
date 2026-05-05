import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/activity_log.dart';
import '../models/evolution_form.dart';
import '../models/evolution_template.dart';
import '../models/user.dart';
import '../services/log_service.dart';
import '../services/storage_service.dart';

class TemplateProvider extends ChangeNotifier {
  TemplateProvider({
    StorageService? storage,
    LogService? logs,
  })  : _storage = storage ?? StorageService.instance,
        _logs = logs ?? LogService.instance;

  final StorageService _storage;
  final LogService _logs;
  final Uuid _uuid = const Uuid();

  List<EvolutionTemplate> _templates = <EvolutionTemplate>[];
  AppUser? _currentUser;
  bool _loading = false;
  String? _error;

  List<EvolutionTemplate> get templates =>
      List<EvolutionTemplate>.unmodifiable(_templates);
  bool get loading => _loading;
  String? get error => _error;
  bool get hasTemplates => _templates.isNotEmpty;

  void bindCurrentUser(AppUser? user) {
    _currentUser = user;
    if (user != null) {
      hydrate();
    } else {
      _templates = <EvolutionTemplate>[];
      notifyListeners();
    }
  }

  void hydrate() {
    final AppUser? u = _currentUser;
    if (u == null) return;
    _templates = _storage.loadTemplates(userId: u.id);
    notifyListeners();
  }

  Future<void> _log(
    ActivityType type,
    String description, {
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    final AppUser? u = _currentUser;
    if (u == null) return;
    await _logs.record(
      userId: u.id,
      userDisplayName: u.displayName,
      type: type,
      description: description,
      metadata: metadata,
    );
  }

  /// Cria um novo template a partir do formulário atual.
  Future<EvolutionTemplate> createFromForm({
    required String name,
    required String description,
    required EvolutionForm form,
  }) async {
    final AppUser? u = _currentUser;
    if (u == null) throw StateError('Nenhum usuário autenticado.');

    final EvolutionTemplate template = EvolutionTemplate.fromForm(
      id: _uuid.v4(),
      userId: u.id,
      name: name.trim(),
      description: description.trim(),
      form: form,
    );

    _templates = <EvolutionTemplate>[template, ..._templates];
    await _storage.upsertTemplate(template);
    await _log(
      ActivityType.templateSaved,
      'Template "${template.name}" criado.',
      metadata: <String, dynamic>{'templateId': template.id},
    );
    notifyListeners();
    return template;
  }

  /// Persiste um [EvolutionTemplate] já construído (para uso na tela de edição).
  Future<EvolutionTemplate> save(EvolutionTemplate template) async {
    final AppUser? u = _currentUser;
    if (u == null) throw StateError('Nenhum usuário autenticado.');

    final EvolutionTemplate t = EvolutionTemplate(
      id: template.id.isEmpty ? _uuid.v4() : template.id,
      userId: u.id,
      name: template.name,
      description: template.description,
      createdAt: template.createdAt,
      updatedAt: template.updatedAt,
      setor: template.setor,
      origem: template.origem,
      transporte: template.transporte,
      suporteTransporte: template.suporteTransporte,
      consciencia: template.consciencia,
      aspectosAdmissao: template.aspectosAdmissao,
      alergiasOp: template.alergiasOp,
      adesao: template.adesao,
      cirurgiaOp: template.cirurgiaOp,
      internacoesOp: template.internacoesOp,
      padResp: template.padResp,
      expTor: template.expTor,
      mv: template.mv,
      ritmo: template.ritmo,
      perf: template.perf,
      abdInsp: template.abdInsp,
      abdPalp: template.abdPalp,
      rha: template.rha,
      diurese: template.diurese,
      defNeuro: template.defNeuro,
      pupilas: template.pupilas,
      rass: template.rass,
      o2: template.o2,
      peleAspecto: template.peleAspecto,
      tipoAcesso: template.tipoAcesso,
      localAcesso: template.localAcesso,
      calibreCateter: template.calibreCateter,
      outrosDisp: template.outrosDisp,
      enfermeiroNome: template.enfermeiroNome,
      corenUF: template.corenUF,
      corenNumero: template.corenNumero,
      obsAdicionais: template.obsAdicionais,
    );

    final bool isNew = !_templates.any((EvolutionTemplate e) => e.id == t.id);
    if (isNew) {
      _templates = <EvolutionTemplate>[t, ..._templates];
    } else {
      _templates = _templates
          .map((EvolutionTemplate e) => e.id == t.id ? t : e)
          .toList();
    }
    await _storage.upsertTemplate(t);
    await _log(
      isNew ? ActivityType.templateSaved : ActivityType.templateUpdated,
      isNew
          ? 'Template "${t.name}" criado.'
          : 'Template "${t.name}" atualizado.',
      metadata: <String, dynamic>{'templateId': t.id},
    );
    notifyListeners();
    return t;
  }

  /// Cria um template em branco com os valores padrão para a conta.
  Future<EvolutionTemplate> createBlank({
    required String name,
    required String description,
  }) async {
    final AppUser? u = _currentUser;
    if (u == null) throw StateError('Nenhum usuário autenticado.');

    final DateTime now = DateTime.now();
    final EvolutionTemplate template = EvolutionTemplate(
      id: _uuid.v4(),
      userId: u.id,
      name: name.trim(),
      description: description.trim(),
      createdAt: now,
      updatedAt: now,
      enfermeiroNome: u.displayName,
      corenUF: u.corenUF ?? 'RJ',
      corenNumero: u.corenNumero ?? '',
    );

    _templates = <EvolutionTemplate>[template, ..._templates];
    await _storage.upsertTemplate(template);
    await _log(
      ActivityType.templateSaved,
      'Template "${template.name}" criado (em branco).',
      metadata: <String, dynamic>{'templateId': template.id},
    );
    notifyListeners();
    return template;
  }

  Future<void> update(EvolutionTemplate updated) async {
    final EvolutionTemplate t = updated.copyWith(updatedAt: DateTime.now());
    _templates = _templates
        .map((EvolutionTemplate e) => e.id == t.id ? t : e)
        .toList();
    await _storage.upsertTemplate(t);
    await _log(
      ActivityType.templateUpdated,
      'Template "${t.name}" atualizado.',
      metadata: <String, dynamic>{'templateId': t.id},
    );
    notifyListeners();
  }

  Future<void> delete(String templateId) async {
    final EvolutionTemplate? removed = _templates.cast<EvolutionTemplate?>()
        .firstWhere((EvolutionTemplate? t) => t?.id == templateId, orElse: () => null);
    _templates =
        _templates.where((EvolutionTemplate t) => t.id != templateId).toList();
    await _storage.deleteTemplate(templateId);
    await _log(
      ActivityType.templateDeleted,
      'Template "${removed?.name ?? templateId}" excluído.',
      metadata: <String, dynamic>{'templateId': templateId},
    );
    notifyListeners();
  }

  Future<EvolutionForm> applyTemplate({
    required String templateId,
    required EvolutionForm currentForm,
  }) async {
    final EvolutionTemplate? t = _templates.cast<EvolutionTemplate?>()
        .firstWhere((EvolutionTemplate? e) => e?.id == templateId, orElse: () => null);
    if (t == null) return currentForm;

    final EvolutionForm result = t.applyTo(currentForm);
    await _log(
      ActivityType.templateApplied,
      'Template "${t.name}" aplicado.',
      metadata: <String, dynamic>{'templateId': t.id},
    );
    return result;
  }
}
