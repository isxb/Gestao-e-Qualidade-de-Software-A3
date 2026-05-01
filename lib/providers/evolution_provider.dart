import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/activity_log.dart';
import '../models/evolution_form.dart';
import '../models/infusion.dart';
import '../models/medication.dart';
import '../models/saved_evolution.dart';
import '../models/user.dart';
import '../services/evolution_generator.dart';
import '../services/log_service.dart';
import '../services/storage_service.dart';

enum GenerationStatus { idle, loading, success, error }

class EvolutionProvider extends ChangeNotifier {
  EvolutionProvider({
    EvolutionGenerator? generator,
    StorageService? storage,
    LogService? logs,
  })  : _generator = generator ?? const EvolutionGenerator(),
        _storage = storage ?? StorageService.instance,
        _logs = logs ?? LogService.instance;

  final EvolutionGenerator _generator;
  final StorageService _storage;
  final LogService _logs;
  final Uuid _uuid = const Uuid();

  EvolutionForm _form = EvolutionForm();
  List<Medication> _medications = <Medication>[];
  List<Infusion> _infusions = <Infusion>[];
  List<SavedEvolution> _saved = <SavedEvolution>[];

  int _currentStep = 0;
  String _generatedText = '';
  GenerationStatus _status = GenerationStatus.idle;
  String? _errorMessage;
  AppUser? _currentUser;

  // ---------- Controle de anúncios (mobile free) ----------
  /// Quantos anúncios foram assistidos até o fim para a evolução atual.
  /// O conteúdo é liberado somente após [requiredAdsCount] conclusões.
  int _adsWatched = 0;

  /// Número de anúncios obrigatórios por evolução gerada.
  static const int requiredAdsCount = 2;

  // ============================================================
  // Getters
  // ============================================================

  EvolutionForm get form => _form;
  List<Medication> get medications => List<Medication>.unmodifiable(_medications);
  List<Infusion> get infusions => List<Infusion>.unmodifiable(_infusions);
  List<SavedEvolution> get savedEvolutions =>
      List<SavedEvolution>.unmodifiable(_saved);
  int get currentStep => _currentStep;
  String get generatedText => _generatedText;
  GenerationStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == GenerationStatus.loading;

  /// Quantos anúncios já foram concluídos para a evolução atual.
  int get adsWatched => _adsWatched;

  /// True quando o usuário já assistiu todos os anúncios obrigatórios
  /// e o conteúdo da evolução pode ser exibido.
  bool get adsCompleted => _adsWatched >= requiredAdsCount;

  // ============================================================
  // Bind de usuário
  // ============================================================

  /// Ajusta o usuário ativo para que os eventos de evolução sejam
  /// atribuídos corretamente. Chamado pelo ProxyProvider ao logar/deslogar.
  void bindCurrentUser(AppUser? user) {
    _currentUser = user;
    if (user != null) {
      _form = _form.copyWith(
        enfermeiroNome: _form.enfermeiroNome.isEmpty ? user.displayName : _form.enfermeiroNome,
        corenUF: user.corenUF ?? _form.corenUF,
        corenNumero:
            (user.corenNumero != null && user.corenNumero!.isNotEmpty)
                ? user.corenNumero
                : _form.corenNumero,
      );
    }
  }

  void hydrate() {
    _saved = _storage.loadEvolutions();
    notifyListeners();
  }

  void refreshAPIStatus() {
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

  // ============================================================
  // Navegação
  // ============================================================

  void setStep(int step) {
    if (step < 0 || step > 8) return;
    _currentStep = step;
    notifyListeners();
  }

  void next() {
    if (_currentStep < 8) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previous() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  // ============================================================
  // Atualizações de formulário
  // ============================================================

  void updateForm(EvolutionForm Function(EvolutionForm) change) {
    _form = change(_form);
    notifyListeners();
  }

  void toggleChecklist({required String fieldName, required String value}) {
    switch (fieldName) {
      case 'aspectosAdmissao':
        _form = _form.copyWith(aspectosAdmissao: _toggle(_form.aspectosAdmissao, value));
        break;
      case 'peleAspecto':
        _form = _form.copyWith(peleAspecto: _toggle(_form.peleAspecto, value));
        break;
      case 'lesoes':
        _form = _form.copyWith(lesoes: _toggle(_form.lesoes, value));
        break;
      case 'outrosDisp':
        final List<String> list = _toggle(_form.outrosDisp, value);
        EvolutionForm next = _form.copyWith(outrosDisp: list);
        if (list.contains('sonda vesical de demora (SVD)')) {
          next = next.copyWith(
            diurese: 'diurese via sonda vesical de demora, aspecto citrino',
          );
        }
        if (list.contains('tubo orotraqueal (TOT)') ||
            list.contains('traqueostomia (TQT)')) {
          next = next.copyWith(
            padResp: 'em uso de ventilação mecânica invasiva',
            o2: 'em ventilação mecânica',
            glasgowVerbal: 0,
          );
        }
        _form = next;
        break;
      case 'examesRealizados':
        _form = _form.copyWith(
          examesRealizados: _toggle(_form.examesRealizados, value),
        );
        break;
      case 'coletas':
        _form = _form.copyWith(coletas: _toggle(_form.coletas, value));
        break;
    }
    notifyListeners();
  }

  void setSelect({required String fieldName, required String value}) {
    EvolutionForm next = _form;
    switch (fieldName) {
      case 'tipoAcesso':
        next = next.copyWith(tipoAcesso: value);
        if (value == 'Sem acesso venoso') {
          next = next.copyWith(
            localAcesso: '',
            calibreCateter: '',
            maddox: '0 (sem sinais flogísticos)',
          );
        }
        break;
      case 'o2':
        next = next.copyWith(o2: value);
        if (value == 'em ventilação mecânica') {
          next = next.copyWith(padResp: 'em uso de ventilação mecânica invasiva');
        }
        break;
      case 'padResp':
        next = next.copyWith(padResp: value);
        if (value == 'em uso de ventilação mecânica invasiva') {
          next = next.copyWith(o2: 'em ventilação mecânica');
        }
        break;
    }
    _form = next;
    notifyListeners();
  }

  // ============================================================
  // Medicações
  // ============================================================

  void addMedication(Medication med) {
    if (med.nome.trim().isEmpty) return;
    _medications = <Medication>[..._medications, med];
    notifyListeners();
  }

  void removeMedication(int index) {
    if (index < 0 || index >= _medications.length) return;
    _medications = List<Medication>.from(_medications)..removeAt(index);
    notifyListeners();
  }

  // ============================================================
  // Infusões
  // ============================================================

  void addInfusion(Infusion inf) {
    if (inf.nome.trim().isEmpty) return;
    _infusions = <Infusion>[..._infusions, inf];
    notifyListeners();
  }

  void removeInfusion(int index) {
    if (index < 0 || index >= _infusions.length) return;
    _infusions = List<Infusion>.from(_infusions)..removeAt(index);
    notifyListeners();
  }

  // ============================================================
  // Comorbidades
  // ============================================================

  void addComorbidity(String value) {
    final String v = value.trim();
    if (v.isEmpty) return;
    _form = _form.copyWith(comorbidades: <String>[..._form.comorbidades, v]);
    notifyListeners();
  }

  void removeComorbidity(int index) {
    if (index < 0 || index >= _form.comorbidades.length) return;
    final List<String> list = List<String>.from(_form.comorbidades)..removeAt(index);
    _form = _form.copyWith(comorbidades: list);
    notifyListeners();
  }

  // ============================================================
  // Geração
  // ============================================================

  Future<void> gerarEvolucao() async {
    _status = GenerationStatus.loading;
    _errorMessage = null;
    _generatedText = '';
    _currentStep = 8;
    // Reseta o contador de anúncios: cada nova evolução gerada exige
    // que o usuário mobile free assista os 2 anúncios novamente.
    _adsWatched = 0;
    notifyListeners();

    final Stopwatch sw = Stopwatch()..start();
    try {
      // Pequeno atraso artificial apenas para feedback visual na interface.
      await Future.delayed(const Duration(milliseconds: 600));

      final String text = _generator.generate(
        form: _form,
        medications: _medications,
        infusions: _infusions,
      );

      sw.stop();
      _generatedText = text;
      _status = GenerationStatus.success;
      await _log(
        ActivityType.evolutionGenerated,
        'Evolução gerada automaticamente (${text.length} caracteres).',
        metadata: <String, dynamic>{
          'chars': text.length,
          'durationMs': sw.elapsedMilliseconds,
          'patientName': _form.pacienteNome,
        },
      );
    } catch (e) {
      sw.stop();
      _errorMessage = 'Erro inesperado: ${e.toString()}';
      _status = GenerationStatus.error;
      await _log(
        ActivityType.evolutionGenerationFailed,
        _errorMessage!,
      );
    }
    notifyListeners();
  }

  // ============================================================
  // Controle de anúncios
  // ============================================================

  /// Registra a conclusão de um anúncio recompensado.
  ///
  /// Deve ser chamado pelo `AdService` dentro do callback
  /// `onUserEarnedReward`, garantindo que o usuário realmente assistiu.
  /// Notifica os listeners para que o `StepOutput` atualize a UI
  /// (progressão do indicador e, ao atingir [requiredAdsCount], liberação
  /// do conteúdo da evolução).
  void markAdWatched() {
    if (_adsWatched < requiredAdsCount) {
      _adsWatched++;
      notifyListeners();
    }
  }

  // ============================================================
  // Texto gerado
  // ============================================================

  void setGeneratedText(String text) {
    _generatedText = text;
    notifyListeners();
  }

  // ============================================================
  // Banco de dados (evoluções salvas)
  // ============================================================

  Future<SavedEvolution> saveCurrentEvolution() async {
    final DateFormat dateFmt = DateFormat('dd/MM/yyyy');
    final DateFormat timeFmt = DateFormat('HH:mm');
    final DateTime now = DateTime.now();
    final SavedEvolution evo = SavedEvolution(
      id: _uuid.v4(),
      date: dateFmt.format(now),
      time: timeFmt.format(now),
      patientName: _form.pacienteNome.trim().isEmpty
          ? 'Paciente não identificado'
          : _form.pacienteNome.trim(),
      text: _generatedText,
    );
    _saved = <SavedEvolution>[evo, ..._saved];
    await _storage.saveEvolutions(_saved);
    await _log(
      ActivityType.evolutionSaved,
      'Evolução salva para "${evo.patientName}".',
      metadata: <String, dynamic>{'evolutionId': evo.id},
    );
    notifyListeners();
    return evo;
  }

  Future<void> updateSavedEvolution(String id, String newText) async {
    _saved = _saved
        .map((SavedEvolution e) => e.id == id ? e.copyWith(text: newText) : e)
        .toList();
    await _storage.saveEvolutions(_saved);
    await _log(
      ActivityType.evolutionEdited,
      'Evolução editada.',
      metadata: <String, dynamic>{'evolutionId': id},
    );
    notifyListeners();
  }

  Future<void> deleteSavedEvolution(String id) async {
    final SavedEvolution? removed = _saved.cast<SavedEvolution?>().firstWhere(
          (SavedEvolution? e) => e?.id == id,
          orElse: () => null,
        );
    _saved = _saved.where((SavedEvolution e) => e.id != id).toList();
    await _storage.saveEvolutions(_saved);
    await _log(
      ActivityType.evolutionDeleted,
      'Evolução excluída: "${removed?.patientName ?? id}".',
      metadata: <String, dynamic>{'evolutionId': id},
    );
    notifyListeners();
  }

  Future<void> trackEvolutionCopied({String? evolutionId}) async {
    await _log(
      ActivityType.evolutionCopied,
      'Texto da evolução copiado para a área de transferência.',
      metadata: <String, dynamic>{
        if (evolutionId != null) 'evolutionId': evolutionId,
      },
    );
  }

  // ============================================================
  // Reset
  // ============================================================

  void startNewEvolution() {
    _form = EvolutionForm();
    if (_currentUser != null) {
      _form = _form.copyWith(
        enfermeiroNome: _currentUser!.displayName,
        corenUF: _currentUser!.corenUF ?? _form.corenUF,
        corenNumero: _currentUser!.corenNumero ?? _form.corenNumero,
      );
    }
    _medications = <Medication>[];
    _infusions = <Infusion>[];
    _generatedText = '';
    _status = GenerationStatus.idle;
    _errorMessage = null;
    _currentStep = 0;
    _adsWatched = 0;
    _log(ActivityType.evolutionStarted, 'Nova evolução iniciada.');
    notifyListeners();
  }

  // ============================================================
  // Helpers internos
  // ============================================================

  List<String> _toggle(List<String> list, String value) {
    if (list.contains(value)) {
      return list.where((String v) => v != value).toList();
    }
    return <String>[...list, value];
  }
}