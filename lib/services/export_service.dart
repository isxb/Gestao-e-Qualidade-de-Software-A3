import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  const ExportService._();

  static Future<void> exportToPdf(String text, String patientName) async {
    final pw.Document pdf = pw.Document();

    // 1. Correção do erro da "Caixinha com X":
    final String safeText = text
        .replaceAll('–', '-') 
        .replaceAll('—', '-') 
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'");

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        build: (pw.Context context) {
          return <pw.Widget>[
            // ==========================================
            // CABEÇALHO PROFISSIONAL (Estilo Prontuário)
            // ==========================================
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 10),
              // CORREÇÃO APLICADA AQUI: A borda deve ficar dentro do BoxDecoration
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey400, width: 1),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: <pw.Widget>[
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: <pw.Widget>[
                      pw.Text(
                        'EVOLUÇÃO DE ENFERMAGEM',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey800,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Paciente: $patientName',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Documento Clínico',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 18),

            // ==========================================
            // CORPO DO TEXTO (Com suporte a negrito)
            // ==========================================
            _buildRichText(safeText),
          ];
        },
        
        // ==========================================
        // RODAPÉ FIXO COM PAGINAÇÃO
        // ==========================================
        footer: (pw.Context context) {
          return pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: <pw.Widget>[
              pw.Divider(color: PdfColors.grey300, thickness: 0.5),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: <pw.Widget>[
                  pw.Text(
                    'Sistema EvoluaPRO',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey500,
                    ),
                  ),
                  pw.Text(
                    'Página ${context.pageNumber} de ${context.pagesCount}',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey500,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    final String safeFileName = patientName.isEmpty 
        ? 'Paciente' 
        : patientName.replaceAll(' ', '_');
        
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Evolucao_$safeFileName.pdf',
    );
  }

  static pw.Widget _buildRichText(String text) {
    final List<pw.TextSpan> spans = <pw.TextSpan>[];
    final RegExp exp = RegExp(r'\*\*(.*?)\*\*');
    int start = 0;

    const double fontSize = 10.5;
    const double lineSpacing = 1.3;

    for (final RegExpMatch match in exp.allMatches(text)) {
      if (match.start > start) {
        spans.add(pw.TextSpan(
          text: text.substring(start, match.start),
          style: const pw.TextStyle(
            fontSize: fontSize,
            lineSpacing: lineSpacing,
          ),
        ));
      }
      spans.add(pw.TextSpan(
        text: match.group(1),
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: pw.FontWeight.bold,
          lineSpacing: lineSpacing,
        ),
      ));
      start = match.end;
    }

    if (start < text.length) {
      spans.add(pw.TextSpan(
        text: text.substring(start),
        style: const pw.TextStyle(
          fontSize: fontSize,
          lineSpacing: lineSpacing,
        ),
      ));
    }

    return pw.RichText(
      text: pw.TextSpan(children: spans),
      textAlign: pw.TextAlign.justify, 
    );
  }

  static Future<void> exportToText(String text, String patientName) async {
    final String cleanText = text.replaceAll('**', '');
    
    // Ignorando o warning do share_plus, pois este método é universal
    // e funciona em 100% das versões do pacote instaladas no Flutter.
    // ignore: deprecated_member_use
    await Share.share(
      cleanText,
      subject: 'Evolução de Enfermagem - $patientName',
    );
  }
}