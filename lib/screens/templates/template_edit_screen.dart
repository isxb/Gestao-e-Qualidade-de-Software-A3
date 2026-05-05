import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/evolution_template.dart';
import '../../providers/template_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/pill_buttons.dart';
import '../../widgets/responsive_grid.dart';
import '../../widgets/section_card.dart';

class TemplateEditScreen extends StatefulWidget {
  const TemplateEditScreen({super.key, this.template});

  /// Null para criação, preenchido para edição.
  final EvolutionTemplate? template;

  @override
  State<TemplateEditScreen> createState() => _TemplateEditScreenState();
}

class _TemplateEditScreenState extends State<TemplateEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late String _name;
  late String _description;
  late String _setor;
  late String _origem;
  late String _transporte;
  late String _suporteTransporte;
  late String _consciencia;
  late List<String> _aspectosAdmissao;
  late String _alergiasOp;
  late String _adesao;
  late String _cirurgiaOp;
  late String _internacoesOp;
  late String _padResp;
  late String _expTor;
  late String _mv;
  late String _ritmo;
  late String _perf;
  late String _abdInsp;
  late String _abdPalp;
  late String _rha;
  late String _diurese;
  late String _defNeuro;
  late String _pupilas;
  late String _rass;
  late String _o2;
  late List<String> _peleAspecto;
  late String _tipoAcesso;
  late String _localAcesso;
  late String _calibreCateter;
  late List<String> _outrosDisp;
  late String _enfermeiroNome;
  late String _corenUF;
  late String _corenNumero;
  late String _obsAdicionais;

  static const List<String> _ufList = <String>[
    'AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS',
    'MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC',
    'SP','SE','TO',
  ];

  @override
  void initState() {
    super.initState();
    final EvolutionTemplate? t = widget.template;
    _name = t?.name ?? '';
    _description = t?.description ?? '';
    _setor = t?.setor ?? 'unidade de terapia intensiva';
    _origem = t?.origem ?? 'unidade de emergência';
    _transporte = t?.transporte ?? 'maca com monitorização cardíaca contínua';
    _suporteTransporte = t?.suporteTransporte ?? 'oxigenoterapia suplementar via cateter nasal';
    _consciencia = t?.consciencia ?? 'consciente e orientado em tempo e espaço';
    _aspectosAdmissao = t?.aspectosAdmissao.toList() ?? <String>['íntegra'];
    _alergiasOp = t?.alergiasOp ?? 'nega';
    _adesao = t?.adesao ?? 'com boa adesão à terapêutica';
    _cirurgiaOp = t?.cirurgiaOp ?? 'nega cirurgias anteriores';
    _internacoesOp = t?.internacoesOp ?? 'nega internações recentes';
    _padResp = t?.padResp ?? 'eupneico';
    _expTor = t?.expTor ?? 'preservada';
    _mv = t?.mv ?? 'presentes e distribuídos em ambos os hemitórax, sem ruídos adventícios';
    _ritmo = t?.ritmo ?? 'regular em dois tempos com bulhas normofonéticas';
    _perf = t?.perf ?? 'perfusão periférica preservada com TEC inferior a 2 segundos';
    _abdInsp = t?.abdInsp ?? 'plano';
    _abdPalp = t?.abdPalp ?? 'flácido e indolor à palpação superficial e profunda';
    _rha = t?.rha ?? 'presentes em todos os quadrantes';
    _diurese = t?.diurese ?? 'diurese espontânea de aspecto citrino';
    _defNeuro = t?.defNeuro ?? 'sem déficits motores ou sensitivos focais';
    _pupilas = t?.pupilas ?? 'isocóricas e fotorreagentes';
    _rass = t?.rass ?? '0 (alerta e calmo)';
    _o2 = t?.o2 ?? 'em ar ambiente';
    _peleAspecto = t?.peleAspecto.toList() ?? <String>['íntegra'];
    _tipoAcesso = t?.tipoAcesso ?? 'Acesso intravenoso periférico';
    _localAcesso = t?.localAcesso ?? '';
    _calibreCateter = t?.calibreCateter ?? 'nº 20';
    _outrosDisp = t?.outrosDisp.toList() ?? <String>[];
    _enfermeiroNome = t?.enfermeiroNome ?? '';
    _corenUF = t?.corenUF ?? 'RJ';
    _corenNumero = t?.corenNumero ?? '';
    _obsAdicionais = t?.obsAdicionais ?? '';
  }

  void _toggleList(List<String> list, String value) {
    setState(() {
      if (list.contains(value)) {
        list.remove(value);
      } else {
        list.add(value);
      }
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState!.save();
    if (_name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um nome para o template.')),
      );
      return;
    }
    setState(() => _saving = true);

    final TemplateProvider prov = context.read<TemplateProvider>();
    final DateTime now = DateTime.now();

    final EvolutionTemplate data = EvolutionTemplate(
      id: widget.template?.id ?? '',
      userId: widget.template?.userId ?? '',
      name: _name.trim(),
      description: _description.trim(),
      createdAt: widget.template?.createdAt ?? now,
      updatedAt: now,
      setor: _setor,
      origem: _origem,
      transporte: _transporte,
      suporteTransporte: _suporteTransporte,
      consciencia: _consciencia,
      aspectosAdmissao: List<String>.from(_aspectosAdmissao),
      alergiasOp: _alergiasOp,
      adesao: _adesao,
      cirurgiaOp: _cirurgiaOp,
      internacoesOp: _internacoesOp,
      padResp: _padResp,
      expTor: _expTor,
      mv: _mv,
      ritmo: _ritmo,
      perf: _perf,
      abdInsp: _abdInsp,
      abdPalp: _abdPalp,
      rha: _rha,
      diurese: _diurese,
      defNeuro: _defNeuro,
      pupilas: _pupilas,
      rass: _rass,
      o2: _o2,
      peleAspecto: List<String>.from(_peleAspecto),
      tipoAcesso: _tipoAcesso,
      localAcesso: _localAcesso,
      calibreCateter: _calibreCateter,
      outrosDisp: List<String>.from(_outrosDisp),
      enfermeiroNome: _enfermeiroNome,
      corenUF: _corenUF,
      corenNumero: _corenNumero,
      obsAdicionais: _obsAdicionais,
    );

    try {
      await prov.save(data);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _pillSelect({
    required List<Map<String, String>> options,
    required String selected,
    required void Function(String) onSelect,
  }) {
    return PillGroup(
      children: options
          .map((Map<String, String> o) => Pill(
                label: o['l']!,
                selected: selected == o['v'],
                onTap: () => setState(() => onSelect(o['v']!)),
              ))
          .toList(),
    );
  }

  Widget _pillToggle({
    required List<Map<String, String>> options,
    required List<String> selected,
    required void Function(String) onToggle,
  }) {
    return PillGroup(
      children: options
          .map((Map<String, String> o) => Pill(
                label: o['l']!,
                selected: selected.contains(o['v']),
                onTap: () => onToggle(o['v']!),
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isNew = widget.template == null;

    return Scaffold(
      appBar: AppHeader(showHomeButton: false),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: AppTheme.contentMaxWidth(context)),
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.horizontalPadding(context),
                vertical: 24,
              ),
              children: <Widget>[
                Text(
                  isNew ? 'Novo Template' : 'Editar Template',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),

                // ---- Identificação ----
                SectionCard(
                  title: 'Identificação',
                  subtitle: 'Nome e descrição do template',
                  icon: Icons.bookmark_rounded,
                  children: <Widget>[
                    LabeledField(
                      label: 'Nome *',
                      child: TextFormField(
                        initialValue: _name,
                        decoration: const InputDecoration(
                          hintText: 'Ex: UTI — Plantão Noturno',
                          border: OutlineInputBorder(),
                        ),
                        validator: (String? v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Informe um nome'
                                : null,
                        onChanged: (String v) => _name = v,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LabeledField(
                      label: 'Descrição (opcional)',
                      child: AppTextField(
                        initialValue: _description,
                        hint: 'Breve descrição do uso deste template',
                        maxLines: 2,
                        onChanged: (String v) => _description = v,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ---- Admissão ----
                SectionCard(
                  title: 'Admissão',
                  subtitle: 'Valores padrão de setor, origem e transporte',
                  icon: Icons.local_hospital_rounded,
                  children: <Widget>[
                    ResponsiveGrid(
                      children: <Widget>[
                        LabeledField(
                          label: 'Setor padrão',
                          child: AppTextField(
                            initialValue: _setor,
                            hint: 'Ex: UTI adulto',
                            onChanged: (String v) => setState(() => _setor = v),
                          ),
                        ),
                        LabeledField(
                          label: 'Origem padrão',
                          child: AppTextField(
                            initialValue: _origem,
                            hint: 'Ex: pronto-socorro',
                            onChanged: (String v) => setState(() => _origem = v),
                          ),
                        ),
                        LabeledField(
                          label: 'Transporte',
                          child: AppTextField(
                            initialValue: _transporte,
                            onChanged: (String v) =>
                                setState(() => _transporte = v),
                          ),
                        ),
                        LabeledField(
                          label: 'Suporte no transporte',
                          child: AppTextField(
                            initialValue: _suporteTransporte,
                            onChanged: (String v) =>
                                setState(() => _suporteTransporte = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LabeledField(
                      label: 'Consciência padrão',
                      child: _pillSelect(
                        options: const <Map<String, String>>[
                          <String, String>{'v': 'consciente e orientado em tempo e espaço', 'l': 'Consciente e orientado'},
                          <String, String>{'v': 'consciente, porém desorientado', 'l': 'Desorientado'},
                          <String, String>{'v': 'com rebaixamento do nível de consciência', 'l': 'Rebaixado'},
                          <String, String>{'v': 'inconsciente', 'l': 'Inconsciente'},
                        ],
                        selected: _consciencia,
                        onSelect: (String v) => _consciencia = v,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LabeledField(
                      label: 'Aspectos de admissão (padrão)',
                      child: _pillToggle(
                        options: const <Map<String, String>>[
                          <String, String>{'v': 'calmo', 'l': 'Calmo'},
                          <String, String>{'v': 'agitado', 'l': 'Agitado'},
                          <String, String>{'v': 'ansioso', 'l': 'Ansioso'},
                          <String, String>{'v': 'com dor', 'l': 'Com dor'},
                          <String, String>{'v': 'hipocorado', 'l': 'Hipocorado'},
                          <String, String>{'v': 'cianótico', 'l': 'Cianótico'},
                          <String, String>{'v': 'ictérico', 'l': 'Ictérico'},
                          <String, String>{'v': 'sudoreico', 'l': 'Sudoreico'},
                        ],
                        selected: _aspectosAdmissao,
                        onToggle: (String v) =>
                            _toggleList(_aspectosAdmissao, v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ---- Exame físico ----
                SectionCard(
                  title: 'Exame Físico',
                  subtitle: 'Achados padrão do exame físico',
                  icon: Icons.monitor_heart_rounded,
                  children: <Widget>[
                    LabeledField(
                      label: 'Padrão respiratório',
                      child: _pillSelect(
                        options: const <Map<String, String>>[
                          <String, String>{'v': 'eupneico', 'l': 'Eupneico'},
                          <String, String>{'v': 'taquipneico', 'l': 'Taquipneico'},
                          <String, String>{'v': 'bradipneico', 'l': 'Bradipneico'},
                          <String, String>{'v': 'em uso de ventilação mecânica invasiva', 'l': 'VM invasiva'},
                          <String, String>{'v': 'em uso de ventilação não invasiva (VNI)', 'l': 'VNI'},
                          <String, String>{'v': 'em uso de oxigenoterapia de alto fluxo', 'l': 'Alto fluxo'},
                        ],
                        selected: _padResp,
                        onSelect: (String v) => _padResp = v,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LabeledField(
                      label: 'Suporte de O₂',
                      child: _pillSelect(
                        options: const <Map<String, String>>[
                          <String, String>{'v': 'em ar ambiente', 'l': 'Ar ambiente'},
                          <String, String>{'v': 'oxigenoterapia via cateter nasal', 'l': 'Cateter nasal'},
                          <String, String>{'v': 'oxigenoterapia via máscara de Venturi', 'l': 'Venturi'},
                          <String, String>{'v': 'oxigenoterapia via máscara com reservatório', 'l': 'Reservatório'},
                          <String, String>{'v': 'em ventilação mecânica', 'l': 'VM'},
                          <String, String>{'v': 'em ventilação não invasiva (VNI)', 'l': 'VNI'},
                          <String, String>{'v': 'oxigenoterapia de alto fluxo (Airvo/Optiflow)', 'l': 'Alto fluxo'},
                        ],
                        selected: _o2,
                        onSelect: (String v) => _o2 = v,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ResponsiveGrid(
                      children: <Widget>[
                        LabeledField(
                          label: 'Expansão torácica',
                          child: AppTextField(
                            initialValue: _expTor,
                            onChanged: (String v) =>
                                setState(() => _expTor = v),
                          ),
                        ),
                        LabeledField(
                          label: 'Murmúrio vesicular',
                          child: AppTextField(
                            initialValue: _mv,
                            onChanged: (String v) => setState(() => _mv = v),
                          ),
                        ),
                        LabeledField(
                          label: 'Ritmo cardíaco',
                          child: AppTextField(
                            initialValue: _ritmo,
                            onChanged: (String v) =>
                                setState(() => _ritmo = v),
                          ),
                        ),
                        LabeledField(
                          label: 'Perfusão periférica',
                          child: AppTextField(
                            initialValue: _perf,
                            onChanged: (String v) => setState(() => _perf = v),
                          ),
                        ),
                        LabeledField(
                          label: 'Abdome à inspeção',
                          child: AppTextField(
                            initialValue: _abdInsp,
                            onChanged: (String v) =>
                                setState(() => _abdInsp = v),
                          ),
                        ),
                        LabeledField(
                          label: 'Abdome à palpação',
                          child: AppTextField(
                            initialValue: _abdPalp,
                            onChanged: (String v) =>
                                setState(() => _abdPalp = v),
                          ),
                        ),
                        LabeledField(
                          label: 'RHA',
                          child: AppTextField(
                            initialValue: _rha,
                            onChanged: (String v) => setState(() => _rha = v),
                          ),
                        ),
                        LabeledField(
                          label: 'Diurese',
                          child: AppTextField(
                            initialValue: _diurese,
                            onChanged: (String v) =>
                                setState(() => _diurese = v),
                          ),
                        ),
                        LabeledField(
                          label: 'Déficit neurológico',
                          child: AppTextField(
                            initialValue: _defNeuro,
                            onChanged: (String v) =>
                                setState(() => _defNeuro = v),
                          ),
                        ),
                        LabeledField(
                          label: 'Pupilas',
                          child: AppTextField(
                            initialValue: _pupilas,
                            onChanged: (String v) =>
                                setState(() => _pupilas = v),
                          ),
                        ),
                        LabeledField(
                          label: 'RASS',
                          child: AppTextField(
                            initialValue: _rass,
                            onChanged: (String v) =>
                                setState(() => _rass = v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ---- Pele ----
                SectionCard(
                  title: 'Integridade Cutânea',
                  subtitle: 'Aspecto padrão da pele',
                  icon: Icons.healing_rounded,
                  children: <Widget>[
                    LabeledField(
                      label: 'Aspecto da pele (padrão)',
                      child: _pillToggle(
                        options: const <Map<String, String>>[
                          <String, String>{'v': 'íntegra', 'l': 'Íntegra'},
                          <String, String>{'v': 'hidratada', 'l': 'Hidratada'},
                          <String, String>{'v': 'ressecada', 'l': 'Ressecada'},
                          <String, String>{'v': 'edemaciada', 'l': 'Edemaciada'},
                          <String, String>{'v': 'com eritema', 'l': 'Com eritema'},
                          <String, String>{'v': 'ictérica', 'l': 'Ictérica'},
                          <String, String>{'v': 'hipocorada', 'l': 'Hipocorada'},
                        ],
                        selected: _peleAspecto,
                        onToggle: (String v) => _toggleList(_peleAspecto, v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ---- Dispositivos ----
                SectionCard(
                  title: 'Dispositivos',
                  subtitle: 'Acessos e dispositivos habituais',
                  icon: Icons.cable_rounded,
                  children: <Widget>[
                    LabeledField(
                      label: 'Tipo de acesso venoso',
                      child: _pillSelect(
                        options: const <Map<String, String>>[
                          <String, String>{'v': 'Acesso intravenoso periférico', 'l': 'Periférico'},
                          <String, String>{'v': 'Acesso venoso central', 'l': 'Central'},
                          <String, String>{'v': 'Acesso venoso central de inserção periférica (PICC)', 'l': 'PICC'},
                          <String, String>{'v': 'Sem acesso venoso', 'l': 'Sem acesso'},
                        ],
                        selected: _tipoAcesso,
                        onSelect: (String v) {
                          _tipoAcesso = v;
                          if (v == 'Sem acesso venoso') {
                            _localAcesso = '';
                            _calibreCateter = '';
                          }
                        },
                      ),
                    ),
                    if (_tipoAcesso != 'Sem acesso venoso') ...<Widget>[
                      const SizedBox(height: 12),
                      ResponsiveGrid(
                        children: <Widget>[
                          LabeledField(
                            label: 'Local de inserção padrão',
                            child: AppTextField(
                              initialValue: _localAcesso,
                              hint: 'Ex: membro superior direito',
                              onChanged: (String v) =>
                                  setState(() => _localAcesso = v),
                            ),
                          ),
                          LabeledField(
                            label: 'Calibre do cateter',
                            child: AppTextField(
                              initialValue: _calibreCateter,
                              hint: 'Ex: nº 20',
                              onChanged: (String v) =>
                                  setState(() => _calibreCateter = v),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    LabeledField(
                      label: 'Outros dispositivos (padrão)',
                      child: _pillToggle(
                        options: const <Map<String, String>>[
                          <String, String>{'v': 'sonda nasogástrica (SNG)', 'l': 'SNG'},
                          <String, String>{'v': 'sonda nasoenteral (SNE)', 'l': 'SNE'},
                          <String, String>{'v': 'sonda vesical de demora (SVD)', 'l': 'SVD'},
                          <String, String>{'v': 'tubo orotraqueal (TOT)', 'l': 'TOT'},
                          <String, String>{'v': 'traqueostomia (TQT)', 'l': 'TQT'},
                          <String, String>{'v': 'dreno torácico', 'l': 'Dreno torácico'},
                          <String, String>{'v': 'dreno abdominal', 'l': 'Dreno abdominal'},
                          <String, String>{'v': 'monitor cardíaco contínuo', 'l': 'Monitor'},
                          <String, String>{'v': 'oxímetro contínuo', 'l': 'Oxímetro'},
                        ],
                        selected: _outrosDisp,
                        onToggle: (String v) => _toggleList(_outrosDisp, v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ---- Assinatura ----
                SectionCard(
                  title: 'Assinatura Padrão',
                  subtitle: 'Dados do enfermeiro responsável',
                  icon: Icons.badge_rounded,
                  children: <Widget>[
                    ResponsiveGrid(
                      children: <Widget>[
                        LabeledField(
                          label: 'Nome do enfermeiro',
                          child: AppTextField(
                            initialValue: _enfermeiroNome,
                            hint: 'Nome completo',
                            onChanged: (String v) =>
                                setState(() => _enfermeiroNome = v),
                          ),
                        ),
                        LabeledField(
                          label: 'COREN — UF',
                          child: DropdownButtonFormField<String>(
                            value: _corenUF,
                            items: _ufList
                                .map((String uf) => DropdownMenuItem<String>(
                                      value: uf,
                                      child: Text(uf),
                                    ))
                                .toList(),
                            onChanged: (String? v) {
                              if (v != null) setState(() => _corenUF = v);
                            },
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        LabeledField(
                          label: 'Número do COREN',
                          child: AppTextField(
                            initialValue: _corenNumero,
                            hint: 'Ex: 123456',
                            onChanged: (String v) =>
                                setState(() => _corenNumero = v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ---- Observações ----
                SectionCard(
                  title: 'Observações Adicionais Padrão',
                  subtitle: 'Notas que aparecem em todas as evoluções deste template',
                  icon: Icons.note_rounded,
                  children: <Widget>[
                    AppTextField(
                      initialValue: _obsAdicionais,
                      hint: 'Ex: paciente em isolamento de contato',
                      maxLines: 3,
                      onChanged: (String v) =>
                          setState(() => _obsAdicionais = v),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(isNew ? 'Criar template' : 'Salvar alterações'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
