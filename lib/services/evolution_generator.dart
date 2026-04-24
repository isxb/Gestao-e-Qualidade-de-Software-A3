import '../models/evolution_form.dart';
import '../models/infusion.dart';
import '../models/medication.dart';

/// Serviço responsável por gerar o texto da evolução de forma síncrona
/// e determinística, substituindo a IA por um template baseado no
/// padrão institucional do hospital.
class EvolutionGenerator {
  const EvolutionGenerator();

  String generate({
    required EvolutionForm form,
    required List<Medication> medications,
    required List<Infusion> infusions,
  }) {
    // Tratamento de datas
    final List<String> parts = form.dataAdmissao.split('-');
    final String dataFormatada = parts.length == 3
        ? '${parts[2]}/${parts[1]}/${parts[0]}'
        : form.dataAdmissao;

    // Helpers
    String joinOrFallback(List<String> xs, String fallback) =>
        xs.isEmpty ? fallback : xs.join(', ');

    // Lógicas de seção
    final String alergias = form.alergiasOp == 'refere'
        ? 'relata alergia a ${form.alergiasTexto}'
        : 'nega alergias medicamentosas ou alimentares conhecidas até o momento';

    final String medsDomiciliares = medications.isEmpty
        ? 'Nega uso de medicamentos domiciliares'
        : 'Faz uso contínuo de ${medications.map((Medication m) => m.display).join(', ')}';

    final String cirurgias = form.cirurgiaOp == 'refere'
        ? 'Registra histórico cirúrgico de ${form.cirurgiaTexto}'
        : 'Nega cirurgias anteriores';

    final String internacoes = form.internacoesOp.contains('recente por')
        ? 'refere internação recente por ${form.internacoesTexto}'
        : 'nega internações recentes por causas cardiovasculares ou outras patologias agudas';

    final String infusoesStr = infusions.isEmpty
        ? 'sem infusões em curso.'
        : 'O paciente encontra-se com infusão de ${infusions.map((Infusion i) => i.detalhe.isEmpty ? i.nome : '${i.nome} para ${i.detalhe}').join(', ')} em bomba de infusão contínua.';

    final String locDorStr = form.locDor.isNotEmpty ? ' em ${form.locDor}' : '';
    final String acessoLocal = form.localAcesso.isNotEmpty ? ' em ${form.localAcesso}' : '';
    final String acessoCalibre = form.calibreCateter.isNotEmpty ? ', com cateter ${form.calibreCateter}' : '';

    // Construção do Texto (String Buffer)
    final StringBuffer sb = StringBuffer();

    // ADMISSÃO
    sb.writeln('Admitido(a) na ${form.setor} em $dataFormatada, às ${form.horaAdmissao}, o(a) paciente ${form.pacienteNome.isEmpty ? 'não identificado' : form.pacienteNome}, de ${form.pacienteIdade.isEmpty ? '?' : form.pacienteIdade} anos, apresentando quadro de ${form.queixaPrincipal.isEmpty ? 'sem queixas relatadas' : form.queixaPrincipal}.');
    sb.writeln('O paciente deu entrada no setor proveniente da ${form.origem}, transportado em ${form.transporte} com suporte de ${form.suporteTransporte}.');
    sb.writeln('No momento da admissão, apresenta-se ${form.consciencia}, porém ${joinOrFallback(form.aspectosAdmissao, 'sem particularidades')}.');
    sb.writeln('');

    // HPP
    sb.writeln('**#HPP:** O histórico patológico pregresso revela ${joinOrFallback(form.comorbidades, 'ausência de comorbidades relatadas')}. O paciente $alergias. $medsDomiciliares, ${form.adesao}. $cirurgias e $internacoes.');
    sb.writeln('');

    // HDA
    sb.writeln('**#HDA:** Ao exame físico, o paciente apresenta-se ${form.padResp} com expansibilidade torácica ${form.expTor} e murmúrios vesiculares ${form.mv}. A avaliação cardiovascular demonstra ritmo cardíaco ${form.ritmo}, ${form.perf}. O abdome apresenta-se ${form.abdInsp}, ${form.abdPalp}, com ruídos hidroaéreos ${form.rha}. O sistema geniturinário encontra-se com ${form.diurese}. Na avaliação neurológica, ${form.defNeuro}, com pupilas ${form.pupilas}. A escala de RASS pontua ${form.rass}.');
    sb.writeln('');

    // SINAIS VITAIS
    sb.writeln('**#Sinais Vitais:** PA ${form.pa.isEmpty ? '?' : form.pa} mmHg, FC ${form.fc.isEmpty ? '?' : form.fc} bpm, FR ${form.fr.isEmpty ? '?' : form.fr} irpm, Tax ${form.temp.isEmpty ? '?' : form.temp} °C, HGT ${form.hgt.isEmpty ? '?' : form.hgt}mg/dL e SatO2 ${form.sato2.isEmpty ? '?' : form.sato2}% ${form.o2}. Na escala analógica de dor, o paciente refere nível ${form.eva}/10$locDorStr e a pontuação na escala de coma de glasgow é ${form.glasgowTotal}.');
    sb.writeln('');

    // PELE
    sb.writeln('**#Integridade cutânea:** A pele apresenta-se ${joinOrFallback(form.peleAspecto, 'íntegra')}. ${form.lesoes.isEmpty ? 'Não foram evidenciadas lesões por pressão' : 'Apresenta: ' + form.lesoes.join(', ')}. A aplicação da escala de Braden resulta em ${form.bradenTotal} pontos, o que caracteriza o paciente com ${form.bradenRisco.toLowerCase()} para o desenvolvimento de lesões por pressão, sendo instituídas as medidas preventivas protocolares da instituição.');
    sb.writeln('');

    // DISPOSITIVOS
    sb.writeln('**#Dispositivos:** ${form.tipoAcesso}$acessoLocal$acessoCalibre. A avaliação pela escala de Maddox pontua ${form.maddox}. ${joinOrFallback(form.outrosDisp, 'Sem outros dispositivos invasivos')}. $infusoesStr');
    sb.writeln('');

    // EXAMES
    sb.write('**#Exames:** ');
    if (form.examesRealizados.isNotEmpty) {
      sb.write('Foram conferidos e anexados ao prontuário os exames: ${form.examesRealizados.join(', ')}. ');
    }
    if (form.achadosExames.isNotEmpty) {
      sb.write('${form.achadosExames}. ');
    }
    if (form.coletas.isNotEmpty) {
      sb.write('Foram coletadas amostras sanguíneas para exames laboratoriais admissionais, incluindo: ${form.coletas.join(', ')}. ');
    }
    sb.write('Status laboratorial: ${form.resLab}. ');
    if (form.obsLab.isNotEmpty) {
      sb.write('${form.obsLab}.');
    }
    sb.writeln('\n');

    // OBSERVAÇÕES E ASSINATURA
    if (form.obsAdicionais.isNotEmpty) {
      sb.writeln('**#Observações:** ${form.obsAdicionais}');
      sb.writeln('');
    }

    sb.writeln('${form.enfermeiroNome.isEmpty ? 'Enfermeiro(a)' : form.enfermeiroNome} – Enfermeiro – COREN/${form.corenUF} ${form.corenNumero.isEmpty ? '000.000' : form.corenNumero}');

    return sb.toString();
  }
}