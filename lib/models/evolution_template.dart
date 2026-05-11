import 'evolution_form.dart';

/// Template de evolução pertencente a uma conta de profissional.
/// Armazena os campos do formulário que não são específicos do paciente,
/// permitindo que o profissional pré-configure seu fluxo de trabalho típico.
class EvolutionTemplate {
  EvolutionTemplate({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
    // Admissão
    this.setor = 'unidade de terapia intensiva',
    this.origem = 'unidade de emergência',
    this.transporte = 'maca com monitorização cardíaca contínua',
    this.suporteTransporte = 'oxigenoterapia suplementar via cateter nasal',
    this.consciencia = 'consciente e orientado em tempo e espaço',
    List<String>? aspectosAdmissao,
    // HPP
    this.alergiasOp = 'nega',
    this.adesao = 'com boa adesão à terapêutica',
    this.cirurgiaOp = 'nega cirurgias anteriores',
    this.internacoesOp = 'nega internações recentes',
    // Exame físico
    this.padResp = 'eupneico',
    this.expTor = 'preservada',
    this.mv =
        'presentes e distribuídos em ambos os hemitórax, sem ruídos adventícios',
    this.ritmo = 'regular em dois tempos com bulhas normofonéticas',
    this.perf =
        'perfusão periférica preservada com TEC inferior a 2 segundos',
    this.abdInsp = 'plano',
    this.abdPalp = 'flácido e indolor à palpação superficial e profunda',
    this.rha = 'presentes em todos os quadrantes',
    this.diurese = 'diurese espontânea de aspecto citrino',
    this.defNeuro = 'sem déficits motores ou sensitivos focais',
    this.pupilas = 'isocóricas e fotorreagentes',
    this.rass = '0 (alerta e calmo)',
    this.o2 = 'em ar ambiente',
    // Pele
    List<String>? peleAspecto,
    // Dispositivos
    this.tipoAcesso = 'Acesso intravenoso periférico',
    this.localAcesso = '',
    this.calibreCateter = 'nº 20',
    List<String>? outrosDisp,
    // Assinatura
    this.enfermeiroNome = '',
    this.corenUF = 'RJ',
    this.corenNumero = '',
    // Observações adicionais padrão
    this.obsAdicionais = '',
  })  : aspectosAdmissao = aspectosAdmissao ?? <String>['íntegra'],
        peleAspecto = peleAspecto ?? <String>['íntegra'],
        outrosDisp = outrosDisp ?? <String>[];

  final String id;
  final String userId;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Admissão
  final String setor;
  final String origem;
  final String transporte;
  final String suporteTransporte;
  final String consciencia;
  final List<String> aspectosAdmissao;

  // HPP
  final String alergiasOp;
  final String adesao;
  final String cirurgiaOp;
  final String internacoesOp;

  // Exame físico
  final String padResp;
  final String expTor;
  final String mv;
  final String ritmo;
  final String perf;
  final String abdInsp;
  final String abdPalp;
  final String rha;
  final String diurese;
  final String defNeuro;
  final String pupilas;
  final String rass;
  final String o2;

  // Pele
  final List<String> peleAspecto;

  // Dispositivos
  final String tipoAcesso;
  final String localAcesso;
  final String calibreCateter;
  final List<String> outrosDisp;

  // Assinatura
  final String enfermeiroNome;
  final String corenUF;
  final String corenNumero;

  // Observações adicionais padrão
  final String obsAdicionais;

  /// Aplica este template sobre um [EvolutionForm] existente, preservando
  /// os campos específicos do paciente (nome, idade, data, sinais vitais).
  EvolutionForm applyTo(EvolutionForm form) {
    return form.copyWith(
      setor: setor,
      origem: origem,
      transporte: transporte,
      suporteTransporte: suporteTransporte,
      consciencia: consciencia,
      aspectosAdmissao: List<String>.from(aspectosAdmissao),
      alergiasOp: alergiasOp,
      adesao: adesao,
      cirurgiaOp: cirurgiaOp,
      internacoesOp: internacoesOp,
      padResp: padResp,
      expTor: expTor,
      mv: mv,
      ritmo: ritmo,
      perf: perf,
      abdInsp: abdInsp,
      abdPalp: abdPalp,
      rha: rha,
      diurese: diurese,
      defNeuro: defNeuro,
      pupilas: pupilas,
      rass: rass,
      o2: o2,
      peleAspecto: List<String>.from(peleAspecto),
      tipoAcesso: tipoAcesso,
      localAcesso: localAcesso,
      calibreCateter: calibreCateter,
      outrosDisp: List<String>.from(outrosDisp),
      enfermeiroNome: enfermeiroNome.isNotEmpty ? enfermeiroNome : form.enfermeiroNome,
      corenUF: corenUF,
      corenNumero: corenNumero.isNotEmpty ? corenNumero : form.corenNumero,
      obsAdicionais: obsAdicionais,
    );
  }

  /// Cria um template a partir do estado atual do formulário.
  static EvolutionTemplate fromForm({
    required String id,
    required String userId,
    required String name,
    required String description,
    required EvolutionForm form,
  }) {
    final DateTime now = DateTime.now();
    return EvolutionTemplate(
      id: id,
      userId: userId,
      name: name,
      description: description,
      createdAt: now,
      updatedAt: now,
      setor: form.setor,
      origem: form.origem,
      transporte: form.transporte,
      suporteTransporte: form.suporteTransporte,
      consciencia: form.consciencia,
      aspectosAdmissao: List<String>.from(form.aspectosAdmissao),
      alergiasOp: form.alergiasOp,
      adesao: form.adesao,
      cirurgiaOp: form.cirurgiaOp,
      internacoesOp: form.internacoesOp,
      padResp: form.padResp,
      expTor: form.expTor,
      mv: form.mv,
      ritmo: form.ritmo,
      perf: form.perf,
      abdInsp: form.abdInsp,
      abdPalp: form.abdPalp,
      rha: form.rha,
      diurese: form.diurese,
      defNeuro: form.defNeuro,
      pupilas: form.pupilas,
      rass: form.rass,
      o2: form.o2,
      peleAspecto: List<String>.from(form.peleAspecto),
      tipoAcesso: form.tipoAcesso,
      localAcesso: form.localAcesso,
      calibreCateter: form.calibreCateter,
      outrosDisp: List<String>.from(form.outrosDisp),
      enfermeiroNome: form.enfermeiroNome,
      corenUF: form.corenUF,
      corenNumero: form.corenNumero,
      obsAdicionais: form.obsAdicionais,
    );
  }

  EvolutionTemplate copyWith({
    String? name,
    String? description,
    DateTime? updatedAt,
    String? setor,
    String? origem,
    String? transporte,
    String? suporteTransporte,
    String? consciencia,
    List<String>? aspectosAdmissao,
    String? alergiasOp,
    String? adesao,
    String? cirurgiaOp,
    String? internacoesOp,
    String? padResp,
    String? expTor,
    String? mv,
    String? ritmo,
    String? perf,
    String? abdInsp,
    String? abdPalp,
    String? rha,
    String? diurese,
    String? defNeuro,
    String? pupilas,
    String? rass,
    String? o2,
    List<String>? peleAspecto,
    String? tipoAcesso,
    String? localAcesso,
    String? calibreCateter,
    List<String>? outrosDisp,
    String? enfermeiroNome,
    String? corenUF,
    String? corenNumero,
    String? obsAdicionais,
  }) {
    return EvolutionTemplate(
      id: id,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      setor: setor ?? this.setor,
      origem: origem ?? this.origem,
      transporte: transporte ?? this.transporte,
      suporteTransporte: suporteTransporte ?? this.suporteTransporte,
      consciencia: consciencia ?? this.consciencia,
      aspectosAdmissao: aspectosAdmissao ?? this.aspectosAdmissao,
      alergiasOp: alergiasOp ?? this.alergiasOp,
      adesao: adesao ?? this.adesao,
      cirurgiaOp: cirurgiaOp ?? this.cirurgiaOp,
      internacoesOp: internacoesOp ?? this.internacoesOp,
      padResp: padResp ?? this.padResp,
      expTor: expTor ?? this.expTor,
      mv: mv ?? this.mv,
      ritmo: ritmo ?? this.ritmo,
      perf: perf ?? this.perf,
      abdInsp: abdInsp ?? this.abdInsp,
      abdPalp: abdPalp ?? this.abdPalp,
      rha: rha ?? this.rha,
      diurese: diurese ?? this.diurese,
      defNeuro: defNeuro ?? this.defNeuro,
      pupilas: pupilas ?? this.pupilas,
      rass: rass ?? this.rass,
      o2: o2 ?? this.o2,
      peleAspecto: peleAspecto ?? this.peleAspecto,
      tipoAcesso: tipoAcesso ?? this.tipoAcesso,
      localAcesso: localAcesso ?? this.localAcesso,
      calibreCateter: calibreCateter ?? this.calibreCateter,
      outrosDisp: outrosDisp ?? this.outrosDisp,
      enfermeiroNome: enfermeiroNome ?? this.enfermeiroNome,
      corenUF: corenUF ?? this.corenUF,
      corenNumero: corenNumero ?? this.corenNumero,
      obsAdicionais: obsAdicionais ?? this.obsAdicionais,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'userId': userId,
        'name': name,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'setor': setor,
        'origem': origem,
        'transporte': transporte,
        'suporteTransporte': suporteTransporte,
        'consciencia': consciencia,
        'aspectosAdmissao': aspectosAdmissao,
        'alergiasOp': alergiasOp,
        'adesao': adesao,
        'cirurgiaOp': cirurgiaOp,
        'internacoesOp': internacoesOp,
        'padResp': padResp,
        'expTor': expTor,
        'mv': mv,
        'ritmo': ritmo,
        'perf': perf,
        'abdInsp': abdInsp,
        'abdPalp': abdPalp,
        'rha': rha,
        'diurese': diurese,
        'defNeuro': defNeuro,
        'pupilas': pupilas,
        'rass': rass,
        'o2': o2,
        'peleAspecto': peleAspecto,
        'tipoAcesso': tipoAcesso,
        'localAcesso': localAcesso,
        'calibreCateter': calibreCateter,
        'outrosDisp': outrosDisp,
        'enfermeiroNome': enfermeiroNome,
        'corenUF': corenUF,
        'corenNumero': corenNumero,
        'obsAdicionais': obsAdicionais,
      };

  static EvolutionTemplate fromJson(Map<String, dynamic> j) {
    List<String> list(String key) {
      final dynamic v = j[key];
      if (v is List) return v.cast<String>();
      return <String>[];
    }

    return EvolutionTemplate(
      id: j['id'] as String,
      userId: j['userId'] as String,
      name: j['name'] as String,
      description: (j['description'] as String?) ?? '',
      createdAt: DateTime.parse(j['createdAt'] as String),
      updatedAt: DateTime.parse(j['updatedAt'] as String),
      setor: (j['setor'] as String?) ?? 'unidade de terapia intensiva',
      origem: (j['origem'] as String?) ?? 'unidade de emergência',
      transporte: (j['transporte'] as String?) ?? 'maca com monitorização cardíaca contínua',
      suporteTransporte: (j['suporteTransporte'] as String?) ?? 'oxigenoterapia suplementar via cateter nasal',
      consciencia: (j['consciencia'] as String?) ?? 'consciente e orientado em tempo e espaço',
      aspectosAdmissao: list('aspectosAdmissao'),
      alergiasOp: (j['alergiasOp'] as String?) ?? 'nega',
      adesao: (j['adesao'] as String?) ?? 'com boa adesão à terapêutica',
      cirurgiaOp: (j['cirurgiaOp'] as String?) ?? 'nega cirurgias anteriores',
      internacoesOp: (j['internacoesOp'] as String?) ?? 'nega internações recentes',
      padResp: (j['padResp'] as String?) ?? 'eupneico',
      expTor: (j['expTor'] as String?) ?? 'preservada',
      mv: (j['mv'] as String?) ?? 'presentes e distribuídos em ambos os hemitórax, sem ruídos adventícios',
      ritmo: (j['ritmo'] as String?) ?? 'regular em dois tempos com bulhas normofonéticas',
      perf: (j['perf'] as String?) ?? 'perfusão periférica preservada com TEC inferior a 2 segundos',
      abdInsp: (j['abdInsp'] as String?) ?? 'plano',
      abdPalp: (j['abdPalp'] as String?) ?? 'flácido e indolor à palpação superficial e profunda',
      rha: (j['rha'] as String?) ?? 'presentes em todos os quadrantes',
      diurese: (j['diurese'] as String?) ?? 'diurese espontânea de aspecto citrino',
      defNeuro: (j['defNeuro'] as String?) ?? 'sem déficits motores ou sensitivos focais',
      pupilas: (j['pupilas'] as String?) ?? 'isocóricas e fotorreagentes',
      rass: (j['rass'] as String?) ?? '0 (alerta e calmo)',
      o2: (j['o2'] as String?) ?? 'em ar ambiente',
      peleAspecto: list('peleAspecto'),
      tipoAcesso: (j['tipoAcesso'] as String?) ?? 'Acesso intravenoso periférico',
      localAcesso: (j['localAcesso'] as String?) ?? '',
      calibreCateter: (j['calibreCateter'] as String?) ?? 'nº 20',
      outrosDisp: list('outrosDisp'),
      enfermeiroNome: (j['enfermeiroNome'] as String?) ?? '',
      corenUF: (j['corenUF'] as String?) ?? 'RJ',
      corenNumero: (j['corenNumero'] as String?) ?? '',
      obsAdicionais: (j['obsAdicionais'] as String?) ?? '',
    );
  }
}
