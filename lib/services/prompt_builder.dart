import '../models/evolution_form.dart';
import '../models/infusion.dart';
import '../models/medication.dart';

/// Constrói o prompt textual enviado ao Gemini a partir dos dados
/// preenchidos na evolução. Mantém o mesmo contrato/modelo da versão web
/// para garantir consistência clínica do texto gerado.
class PromptBuilder {
  const PromptBuilder();

  String build({
    required EvolutionForm form,
    required List<Medication> medications,
    required List<Infusion> infusions,
  }) {
    final List<String> parts = form.dataAdmissao.split('-');
    final String dataFormatada = parts.length == 3
        ? '${parts[2]}/${parts[1]}/${parts[0]}'
        : form.dataAdmissao;

    String joinOrFallback(List<String> xs, String fallback) =>
        xs.isEmpty ? fallback : xs.join(', ');

    final String alergias = form.alergiasOp == 'refere'
        ? 'relata alergia a ${form.alergiasTexto}'
        : 'nega alergias conhecidas';

    final String medsDomiciliares = medications.isEmpty
        ? 'nega uso de medicamentos domiciliares'
        : medications.map((Medication m) => m.display).join(', ');

    final String cirurgias = form.cirurgiaOp == 'refere'
        ? form.cirurgiaTexto
        : 'nega cirurgias anteriores';

    final String internacoes =
        form.internacoesOp.contains('recente por')
            ? form.internacoesTexto
            : 'nega internações recentes';

    final String infusoesStr = infusions.isEmpty
        ? 'sem infusões em curso'
        : infusions
            .map((Infusion i) =>
                i.detalhe.isEmpty ? i.nome : '${i.nome} para ${i.detalhe}')
            .join('; ');

    return '''
Você é um enfermeiro experiente. Gere uma evolução de enfermagem de admissão em português brasileiro, seguindo exatamente o formato do modelo abaixo.

MODELO DE FORMATO:
---
Admitido na unidade em [DATA], às [HORA], o Sr. [INICIAIS], de [IDADE] anos, apresentando [QUEIXA]. O paciente deu entrada no setor proveniente da [ORIGEM], transportado em [TRANSPORTE] com [SUPORTE]. No momento da admissão, apresenta-se [CONSCIÊNCIA], porém [ASPECTOS].

**#HPP:** O histórico patológico pregresso revela [COMORBIDADES]. O paciente [ALERGIAS]. [MEDICAÇÕES]. [CIRURGIA]. [INTERNAÇÕES].

**#HDA:** Ao exame físico, o paciente apresenta-se [RESPIRATÓRIO]. A avaliação cardiovascular demonstra [CARDIOVASCULAR]. O abdome apresenta-se [ABDOME]. O sistema geniturinário encontra-se com [DIURESE]. Na avaliação neurológica, [NEUROLÓGICO]. A escala de RASS pontua [RASS].

**#Sinais Vitais:** PA [PA] mmHg, FC [FC] bpm, FR [FR] irpm, Tax [TEMP] °C, HGT [HGT]mg/dL e SatO2 [SAT]% [SUPORTE O2]. Na escala analógica de dor, o paciente refere nível [EVA]/10 [LOCAL DOR] e a pontuação na escala de coma de Glasgow é [GLASGOW].

**#Integridade cutânea:** A pele apresenta-se [PELE]. [LESÕES]. A aplicação da escala de Braden resulta em [BRADEN] pontos, o que caracteriza o paciente como [RISCO BRADEN] para o desenvolvimento de lesões por pressão, sendo instituídas as medidas preventivas protocolares.

**#Dispositivos:** [ACESSO VENOSO]. A avaliação pela escala de Maddox pontua [MADDOX]. [OUTROS DISPOSITIVOS]. [INFUSÕES].

**#Exames:** [EXAMES REALIZADOS]. [COLETAS LABORATORIAIS]. [STATUS].

[OBSERVAÇÕES SE HOUVER]

[NOME] – Enfermeiro – [CONSELHO]
---

USE OS DADOS ABAIXO para preencher a evolução no mesmo estilo do modelo (texto corrido, formal, clínico, sem bullet points):

DADOS DO PACIENTE:
- Iniciais: ${form.pacienteNome.isEmpty ? 'Paciente' : form.pacienteNome}
- Idade: ${form.pacienteIdade.isEmpty ? '?' : form.pacienteIdade} anos
- Data admissão: $dataFormatada às ${form.horaAdmissao.isEmpty ? '?' : form.horaAdmissao}
- Setor: ${form.setor}
- Origem: ${form.origem}
- Queixa: ${form.queixaPrincipal}
- Transporte: ${form.transporte} com ${form.suporteTransporte}
- Estado admissão: ${form.consciencia}
- Aspectos na admissão: ${joinOrFallback(form.aspectosAdmissao, 'sem particularidades')}

HPP:
- Comorbidades: ${joinOrFallback(form.comorbidades, 'não relatadas')}
- Alergias: $alergias
- Medicações domiciliares: $medsDomiciliares
- Adesão: ${form.adesao}
- Cirurgias: $cirurgias
- Internações recentes: $internacoes

EXAME FÍSICO:
- Respiratório: ${form.padResp}, expansibilidade ${form.expTor}, ${form.mv}
- Cardiovascular: ${form.ritmo}, ${form.perf}
- Abdome: ${form.abdInsp}, ${form.abdPalp}, ruídos ${form.rha}
- Diurese: ${form.diurese}
- Neurológico: ${form.defNeuro}, pupilas ${form.pupilas}
- RASS: ${form.rass}

SINAIS VITAIS:
- PA: ${form.pa.isEmpty ? '---' : form.pa} mmHg
- FC: ${form.fc.isEmpty ? '---' : form.fc} bpm
- FR: ${form.fr.isEmpty ? '---' : form.fr} irpm
- Temperatura: ${form.temp.isEmpty ? '---' : form.temp} °C
- HGT: ${form.hgt.isEmpty ? '---' : form.hgt} mg/dL
- SatO2: ${form.sato2.isEmpty ? '---' : form.sato2}% ${form.o2}
- EVA: ${form.eva}/10${form.locDor.isEmpty ? '' : ' em ${form.locDor}'}
- Glasgow: ${form.glasgowTotal} (Ocular: ${form.glasgowOcular}, Verbal: ${form.glasgowVerbal}, Motor: ${form.glasgowMotor}, Pupilar: -${form.glasgowPupilar})

INTEGRIDADE CUTÂNEA:
- Pele: ${joinOrFallback(form.peleAspecto, 'não avaliado')}
- Lesões: ${joinOrFallback(form.lesoes, 'não identificadas')}
- Braden: ${form.bradenTotal} pontos (${form.bradenRisco})

DISPOSITIVOS:
- Acesso: ${form.tipoAcesso} ${form.localAcesso}, calibre ${form.calibreCateter}
- Maddox: ${form.maddox}
- Outros: ${joinOrFallback(form.outrosDisp, 'sem outros dispositivos')}
- Infusões: $infusoesStr

EXAMES:
- Realizados: ${joinOrFallback(form.examesRealizados, 'sem exames listados')}
- Achados: ${form.achadosExames.isEmpty ? 'não descritos' : form.achadosExames}
- Coletas: ${joinOrFallback(form.coletas, 'sem coletas listadas')}
- Status: ${form.resLab}
- Obs laboratorial: ${form.obsLab}

OBSERVAÇÕES ADICIONAIS: ${form.obsAdicionais.isEmpty ? 'nenhuma' : form.obsAdicionais}

ASSINATURA: ${form.enfermeiroNome.isEmpty ? 'Enfermeiro' : form.enfermeiroNome} – Enfermeiro – COREN/${form.corenUF} ${form.corenNumero.isEmpty ? '000.000' : form.corenNumero}

IMPORTANTE: Gere APENAS o texto da evolução, sem comentários, sem markdown extra. Use **#SEÇÃO:** para os marcadores. O texto deve ser fluente e profissional.
''';
  }
}
