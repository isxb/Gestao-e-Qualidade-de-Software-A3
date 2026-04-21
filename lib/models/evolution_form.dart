import 'package:intl/intl.dart';

/// Encapsula todos os campos da evolução de enfermagem.
/// Estruturado como modelo imutável com [copyWith] para facilitar
/// o rebuild seletivo do Provider e testes unitários.
class EvolutionForm {
  EvolutionForm({
    this.pacienteNome = '',
    this.pacienteIdade = '',
    this.setor = 'unidade de terapia intensiva',
    this.origem = 'unidade de emergência',
    String? dataAdmissao,
    String? horaAdmissao,
    this.queixaPrincipal = '',
    this.transporte = 'maca com monitorização cardíaca contínua',
    this.suporteTransporte = 'oxigenoterapia suplementar via cateter nasal',
    this.consciencia = 'consciente e orientado em tempo e espaço',
    List<String>? aspectosAdmissao,
    List<String>? comorbidades,
    this.alergiasOp = 'nega',
    this.alergiasTexto = '',
    this.adesao = 'com boa adesão à terapêutica',
    this.cirurgiaOp = 'nega cirurgias anteriores',
    this.cirurgiaTexto = '',
    this.internacoesOp = 'nega internações recentes',
    this.internacoesTexto = '',
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
    this.pa = '',
    this.fc = '',
    this.fr = '',
    this.temp = '',
    this.hgt = '',
    this.sato2 = '',
    this.o2 = 'em ar ambiente',
    this.eva = 0,
    this.locDor = '',
    this.glasgowOcular = 4,
    this.glasgowVerbal = 5,
    this.glasgowMotor = 6,
    this.glasgowPupilar = 0,
    List<String>? peleAspecto,
    List<String>? lesoes,
    this.b1 = 4,
    this.b2 = 3,
    this.b3 = 2,
    this.b4 = 3,
    this.b5 = 3,
    this.b6 = 2,
    this.tipoAcesso = 'Acesso intravenoso periférico',
    this.localAcesso = '',
    this.calibreCateter = 'nº 20',
    this.maddox = '0 (sem sinais flogísticos)',
    List<String>? outrosDisp,
    List<String>? examesRealizados,
    this.achadosExames = '',
    List<String>? coletas,
    this.resLab =
        'resultados pendentes, aguardando processamento pelo laboratório',
    this.obsLab = '',
    this.enfermeiroNome = '',
    this.corenUF = 'RJ',
    this.corenNumero = '',
    this.obsAdicionais = '',
  })  : dataAdmissao = dataAdmissao ?? _hoje(),
        horaAdmissao = horaAdmissao ?? _agora(),
        aspectosAdmissao = aspectosAdmissao ?? <String>['íntegra'],
        comorbidades = comorbidades ?? <String>[],
        peleAspecto = peleAspecto ?? <String>['íntegra'],
        lesoes = lesoes ?? <String>[],
        outrosDisp = outrosDisp ?? <String>[],
        examesRealizados = examesRealizados ?? <String>[],
        coletas = coletas ?? <String>[];

  static String _hoje() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  static String _agora() => DateFormat('HH:mm').format(DateTime.now());

  // Admissão
  final String pacienteNome;
  final String pacienteIdade;
  final String setor;
  final String origem;
  final String dataAdmissao;
  final String horaAdmissao;
  final String queixaPrincipal;
  final String transporte;
  final String suporteTransporte;
  final String consciencia;
  final List<String> aspectosAdmissao;

  // HPP
  final List<String> comorbidades;
  final String alergiasOp;
  final String alergiasTexto;
  final String adesao;
  final String cirurgiaOp;
  final String cirurgiaTexto;
  final String internacoesOp;
  final String internacoesTexto;

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

  // Sinais vitais
  final String pa;
  final String fc;
  final String fr;
  final String temp;
  final String hgt;
  final String sato2;
  final String o2;
  final int eva;
  final String locDor;
  final int glasgowOcular;
  final int glasgowVerbal;
  final int glasgowMotor;
  final int glasgowPupilar;

  // Integridade cutânea
  final List<String> peleAspecto;
  final List<String> lesoes;
  final int b1;
  final int b2;
  final int b3;
  final int b4;
  final int b5;
  final int b6;

  // Dispositivos
  final String tipoAcesso;
  final String localAcesso;
  final String calibreCateter;
  final String maddox;
  final List<String> outrosDisp;

  // Exames
  final List<String> examesRealizados;
  final String achadosExames;
  final List<String> coletas;
  final String resLab;
  final String obsLab;

  // Assinatura / Observações
  final String enfermeiroNome;
  final String corenUF;
  final String corenNumero;
  final String obsAdicionais;

  // Derivados
  int get bradenTotal => b1 + b2 + b3 + b4 + b5 + b6;

  String get bradenRisco {
    final int t = bradenTotal;
    if (t <= 9) return 'Risco muito alto';
    if (t <= 12) return 'Risco alto';
    if (t <= 14) return 'Risco moderado';
    if (t <= 18) return 'Baixo risco';
    return 'Sem risco significativo';
  }

  int get glasgowTotal =>
      glasgowOcular + glasgowVerbal + glasgowMotor - glasgowPupilar;

  EvolutionForm copyWith({
    String? pacienteNome,
    String? pacienteIdade,
    String? setor,
    String? origem,
    String? dataAdmissao,
    String? horaAdmissao,
    String? queixaPrincipal,
    String? transporte,
    String? suporteTransporte,
    String? consciencia,
    List<String>? aspectosAdmissao,
    List<String>? comorbidades,
    String? alergiasOp,
    String? alergiasTexto,
    String? adesao,
    String? cirurgiaOp,
    String? cirurgiaTexto,
    String? internacoesOp,
    String? internacoesTexto,
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
    String? pa,
    String? fc,
    String? fr,
    String? temp,
    String? hgt,
    String? sato2,
    String? o2,
    int? eva,
    String? locDor,
    int? glasgowOcular,
    int? glasgowVerbal,
    int? glasgowMotor,
    int? glasgowPupilar,
    List<String>? peleAspecto,
    List<String>? lesoes,
    int? b1,
    int? b2,
    int? b3,
    int? b4,
    int? b5,
    int? b6,
    String? tipoAcesso,
    String? localAcesso,
    String? calibreCateter,
    String? maddox,
    List<String>? outrosDisp,
    List<String>? examesRealizados,
    String? achadosExames,
    List<String>? coletas,
    String? resLab,
    String? obsLab,
    String? enfermeiroNome,
    String? corenUF,
    String? corenNumero,
    String? obsAdicionais,
  }) {
    return EvolutionForm(
      pacienteNome: pacienteNome ?? this.pacienteNome,
      pacienteIdade: pacienteIdade ?? this.pacienteIdade,
      setor: setor ?? this.setor,
      origem: origem ?? this.origem,
      dataAdmissao: dataAdmissao ?? this.dataAdmissao,
      horaAdmissao: horaAdmissao ?? this.horaAdmissao,
      queixaPrincipal: queixaPrincipal ?? this.queixaPrincipal,
      transporte: transporte ?? this.transporte,
      suporteTransporte: suporteTransporte ?? this.suporteTransporte,
      consciencia: consciencia ?? this.consciencia,
      aspectosAdmissao: aspectosAdmissao ?? this.aspectosAdmissao,
      comorbidades: comorbidades ?? this.comorbidades,
      alergiasOp: alergiasOp ?? this.alergiasOp,
      alergiasTexto: alergiasTexto ?? this.alergiasTexto,
      adesao: adesao ?? this.adesao,
      cirurgiaOp: cirurgiaOp ?? this.cirurgiaOp,
      cirurgiaTexto: cirurgiaTexto ?? this.cirurgiaTexto,
      internacoesOp: internacoesOp ?? this.internacoesOp,
      internacoesTexto: internacoesTexto ?? this.internacoesTexto,
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
      pa: pa ?? this.pa,
      fc: fc ?? this.fc,
      fr: fr ?? this.fr,
      temp: temp ?? this.temp,
      hgt: hgt ?? this.hgt,
      sato2: sato2 ?? this.sato2,
      o2: o2 ?? this.o2,
      eva: eva ?? this.eva,
      locDor: locDor ?? this.locDor,
      glasgowOcular: glasgowOcular ?? this.glasgowOcular,
      glasgowVerbal: glasgowVerbal ?? this.glasgowVerbal,
      glasgowMotor: glasgowMotor ?? this.glasgowMotor,
      glasgowPupilar: glasgowPupilar ?? this.glasgowPupilar,
      peleAspecto: peleAspecto ?? this.peleAspecto,
      lesoes: lesoes ?? this.lesoes,
      b1: b1 ?? this.b1,
      b2: b2 ?? this.b2,
      b3: b3 ?? this.b3,
      b4: b4 ?? this.b4,
      b5: b5 ?? this.b5,
      b6: b6 ?? this.b6,
      tipoAcesso: tipoAcesso ?? this.tipoAcesso,
      localAcesso: localAcesso ?? this.localAcesso,
      calibreCateter: calibreCateter ?? this.calibreCateter,
      maddox: maddox ?? this.maddox,
      outrosDisp: outrosDisp ?? this.outrosDisp,
      examesRealizados: examesRealizados ?? this.examesRealizados,
      achadosExames: achadosExames ?? this.achadosExames,
      coletas: coletas ?? this.coletas,
      resLab: resLab ?? this.resLab,
      obsLab: obsLab ?? this.obsLab,
      enfermeiroNome: enfermeiroNome ?? this.enfermeiroNome,
      corenUF: corenUF ?? this.corenUF,
      corenNumero: corenNumero ?? this.corenNumero,
      obsAdicionais: obsAdicionais ?? this.obsAdicionais,
    );
  }
}
