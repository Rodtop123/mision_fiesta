import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../models/evento_model.dart';

class PdfGenerator {
  
  static Future<void> generarYMostrarPDF(Evento evento) async {
    final pdf = pw.Document();
    
    // 1. CARGAR RECURSOS
    final fontRegular = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();
    
    final imageBytes = await rootBundle.load('assets/fondo_pdf.png');
    final image = pw.MemoryImage(imageBytes.buffer.asUint8List());

    // --- PALETA DE COLORES ---
    const PdfColor textoBlanco = PdfColors.white;
    const PdfColor textoGris = PdfColors.grey300;
    const PdfColor colorTitulo = PdfColors.cyanAccent;
    // 👇 AQUÍ ESTABA EL ERROR: Ahora unificamos todo a "colorAcento"
    const PdfColor colorAcento = PdfColors.amberAccent; 
    const PdfColor colorBorde = PdfColors.grey500;

    // Cálculos
    final double saldoPendiente = evento.precioTotal - evento.anticipo;

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          buildBackground: (pw.Context context) {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Image(image, fit: pw.BoxFit.cover),
            );
          },
        ),
        
        build: (pw.Context context) {
          return [
            // Espacio superior
            pw.SizedBox(height: 50), 

            // --- 1. DATOS GENERALES ---
            _buildSectionTitle("DATOS DE LA MISIÓN", fontBold, colorTitulo),
            pw.Table(
              border: pw.TableBorder.all(color: colorBorde, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5),
                1: const pw.FlexColumnWidth(3),
              },
              children: [
                _buildTableRow("Cliente", evento.cliente, fontBold, fontRegular, textoGris, textoBlanco),
                _buildTableRow("Teléfono", evento.telefono, fontBold, fontRegular, textoGris, textoBlanco),
                _buildTableRow("Fecha", DateFormat('EEEE d ' 'de' ' MMMM, yyyy', 'es').format(evento.fecha).toUpperCase(), fontBold, fontRegular, textoGris, textoBlanco),
                _buildTableRow("Cumpleañero", evento.cumpleanero, fontBold, fontRegular, textoGris, textoBlanco),
              ]
            ),
            
            pw.SizedBox(height: 10),

            // --- 2. DETALLES ---
            _buildSectionTitle("ESPECIFICACIONES", fontBold, colorTitulo),
            pw.Table(
              border: pw.TableBorder.all(color: colorBorde, width: 0.5),
              children: [
                _buildTableRow("Paquete", evento.paquete.toUpperCase(), fontBold, fontRegular, textoGris, textoBlanco),
                _buildTableRow("Tripulación", "${evento.invitados} Personas", fontBold, fontRegular, textoGris, textoBlanco),
              ]
            ),

            pw.SizedBox(height: 10),

            // --- 3. FINANZAS ---
            _buildSectionTitle("DESGLOSE FINANCIERO", fontBold, colorAcento),
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: colorAcento, width: 1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5))
              ),
              child: pw.Table(
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("COSTO TOTAL", style: pw.TextStyle(font: fontBold, color: textoBlanco, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("\$ ${NumberFormat("#,##0.00").format(evento.precioTotal)}", style: pw.TextStyle(font: fontBold, color: textoBlanco, fontSize: 10), textAlign: pw.TextAlign.right)),
                    ]
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Anticipo (-)", style: pw.TextStyle(font: fontRegular, color: textoGris, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("\$ ${NumberFormat("#,##0.00").format(evento.anticipo)}", style: pw.TextStyle(font: fontRegular, color: PdfColors.redAccent, fontSize: 10), textAlign: pw.TextAlign.right)),
                    ]
                  ),
                  // Saldo Pendiente
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: colorAcento),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("SALDO PENDIENTE", style: pw.TextStyle(font: fontBold, color: PdfColors.white, fontSize: 12))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("\$ ${NumberFormat("#,##0.00").format(saldoPendiente)}", style: pw.TextStyle(font: fontBold, color: PdfColors.white, fontSize: 12), textAlign: pw.TextAlign.right)),
                    ]
                  ),
                ]
              )
            ),
            
            pw.SizedBox(height: 10),

            // --- 4. LOGÍSTICA ---
            _buildSectionTitle("LOGÍSTICA", fontBold, colorTitulo),
            pw.Table(
              border: pw.TableBorder.all(color: colorBorde, width: 0.5),
              children: [
                _buildTableRow("Aguas", evento.saborAguas, fontBold, fontRegular, textoGris, textoBlanco),
                _buildTableRow("Refrescos", evento.refrescos, fontBold, fontRegular, textoGris, textoBlanco),
                _buildTableRow("Botana", evento.botana, fontBold, fontRegular, textoGris, textoBlanco),
                _buildTableRow("Pastel", evento.pastel, fontBold, fontRegular, textoGris, textoBlanco),
                _buildTableRow("Piñata", evento.pinata, fontBold, fontRegular, textoGris, textoBlanco),
                _buildTableRow("Notas", evento.observaciones, fontBold, fontRegular, textoGris, PdfColors.yellow),
              ]
            ),

            pw.SizedBox(height: 10),

            // --- 5. ITINERARIO ---
            _buildSectionTitle("ITINERARIO", fontBold, colorTitulo),
            pw.Table(
              border: pw.TableBorder.all(color: colorBorde, width: 0.5),
              children: [
                _buildTableRow("Recepción", evento.itinerario['inicio'] ?? '--', fontBold, fontRegular, textoGris, textoBlanco),
                _buildTableRow("Comida", evento.itinerario['comida'] ?? '--', fontBold, fontRegular, textoGris, textoBlanco),
                _buildTableRow("Pastel", evento.itinerario['pastel'] ?? '--', fontBold, fontRegular, textoGris, textoBlanco),
                _buildTableRow("Fin", evento.itinerario['fin'] ?? '--', fontBold, fontRegular, textoGris, textoBlanco),
              ]
            ),

            pw.SizedBox(height: 25),

            // --- FIRMAS ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildSignatureLine("ADMINISTRACIÓN PLAY DEIT", fontBold, textoBlanco),
                _buildSignatureLine("CLIENTE: ${evento.cliente.toUpperCase()}", fontBold, textoBlanco),
              ]
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Contrato_${evento.cliente}.pdf',
    );
  }

  // --- AYUDANTES DE DISEÑO ---

  static pw.Widget _buildSectionTitle(String text, pw.Font font, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 3, top: 5),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 10, color: color, fontWeight: pw.FontWeight.bold))
    );
  }

  static pw.TableRow _buildTableRow(String label, String value, pw.Font fontLabel, pw.Font fontValue, PdfColor colorLabel, PdfColor colorValue) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
          child: pw.Text(label, style: pw.TextStyle(font: fontLabel, fontSize: 8, color: colorLabel))
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
          child: pw.Text(value.isEmpty ? "---" : value, 
            style: pw.TextStyle(font: fontValue, fontSize: 8, color: colorValue))
        ),
      ]
    );
  }

  static pw.Widget _buildSignatureLine(String label, pw.Font font, PdfColor color) {
    return pw.Column(
      children: [
        pw.Container(width: 130, height: 1, color: color),
        pw.SizedBox(height: 3),
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 7, color: color)),
      ]
    );
  }
}