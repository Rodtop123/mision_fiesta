import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../models/evento_model.dart';
import 'package:intl/date_symbol_data_local.dart';

class PdfGenerator {
  
  // ==========================================
  // 1. CONTRATO INDIVIDUAL (MISIONES)
  // ==========================================
  static Future<void> generarYMostrarPDF(Evento evento) async {
    await initializeDateFormatting('es', null);
    
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();
    final imageBytes = await rootBundle.load('assets/fondo_pdf.png');
    final image = pw.MemoryImage(imageBytes.buffer.asUint8List());

    const PdfColor textoBlanco = PdfColors.white;
    const PdfColor textoGris = PdfColors.grey300;
    const PdfColor colorTitulo = PdfColors.cyanAccent;
    const PdfColor colorAcento = PdfColors.amberAccent; 
    const PdfColor colorBorde = PdfColors.grey500;

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
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              "Página ${context.pageNumber} de ${context.pagesCount} - Generado por Misión Fiesta",
              style: pw.TextStyle(font: fontRegular, fontSize: 8, color: textoGris),
            ),
          );
        },
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 50), 

            // DATOS GENERALES
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
                _buildTableRow("Fecha", DateFormat('EEEE d \'de\' MMMM, yyyy', 'es').format(evento.fecha).toUpperCase(), fontBold, fontRegular, textoGris, textoBlanco),
                _buildTableRow("Cumpleañero", evento.cumpleanero, fontBold, fontRegular, textoGris, textoBlanco),
              ]
            ),
            
            pw.SizedBox(height: 10),

            // DETALLES
            _buildSectionTitle("ESPECIFICACIONES", fontBold, colorTitulo),
            pw.Table(
              border: pw.TableBorder.all(color: colorBorde, width: 0.5),
              children: [
                _buildTableRow("Paquete", evento.paquete.toUpperCase(), fontBold, fontRegular, textoGris, textoBlanco),
                _buildTableRow("Tripulación", "${evento.invitados} Personas", fontBold, fontRegular, textoGris, textoBlanco),
              ]
            ),

            // EXTRAS
            if (evento.extras.isNotEmpty) ...[
               pw.SizedBox(height: 10),
               _buildSectionTitle("ADICIONALES SOLICITADOS", fontBold, colorAcento),
               pw.Table(
                 border: pw.TableBorder.all(color: colorAcento, width: 0.5),
                 children: evento.extras.map((ext) {
                   double costo = (ext['costo'] as num).toDouble();
                   return pw.TableRow(
                     children: [
                       pw.Padding(
                         padding: const pw.EdgeInsets.all(4), 
                         child: pw.Text(ext['texto'], style: pw.TextStyle(font: fontRegular, fontSize: 8, color: textoBlanco))
                       ),
                       pw.Padding(
                         padding: const pw.EdgeInsets.all(4),
                         child: pw.Text(
                           costo > 0 ? "+\$ ${costo.toStringAsFixed(2)}" : "Incluido", 
                           style: pw.TextStyle(font: fontBold, fontSize: 8, color: textoBlanco), 
                           textAlign: pw.TextAlign.right
                         )
                       ),
                     ]
                   );
                 }).toList()
               ),
            ],

            pw.SizedBox(height: 10),

            // FINANZAS
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
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: colorAcento),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("SALDO PENDIENTE", style: pw.TextStyle(font: fontBold, color: PdfColors.white, fontSize: 12))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("\$ ${NumberFormat("#,##0.00").format(saldoPendiente)}", style: pw.TextStyle(font: fontBold, color: PdfColors.white, fontSize: 12), textAlign: pw.TextAlign.right)),
                    ]
                  ),
                ]
              )
            ),
            
            pw.SizedBox(height: 10),

            // LOGÍSTICA
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

            // ITINERARIO
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

            // FIRMAS
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

  // ==========================================
  // 2. REPORTE UTILIDAD
  // ==========================================
  static Future<void> generarReporteUtilidad(List<Evento> eventos, double total) async {
    await initializeDateFormatting('es', null);
    final pdf = pw.Document();
    final fontBold = await PdfGoogleFonts.openSansBold();
    final fontRegular = await PdfGoogleFonts.openSansRegular();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        footer: (pw.Context context) => pw.Container(alignment: pw.Alignment.centerRight, margin: const pw.EdgeInsets.only(top: 10), child: pw.Text("Página ${context.pageNumber} de ${context.pagesCount}", style: pw.TextStyle(font: fontRegular, fontSize: 8))),
        build: (pw.Context context) {
          return [
            pw.Header(level: 0, child: pw.Text("REPORTE DE UTILIDADES", style: pw.TextStyle(font: fontBold, fontSize: 18))),
            pw.SizedBox(height: 20),
            pw.Table(border: pw.TableBorder.all(color: PdfColors.grey), children: [
                pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey200), children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("Fecha", style: pw.TextStyle(font: fontBold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("Cliente", style: pw.TextStyle(font: fontBold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("Utilidad", style: pw.TextStyle(font: fontBold))),
                ]),
                ...eventos.map((e) {
                   final utilidad = (e.consumo['ganancia_neta'] as num?)?.toDouble() ?? 0;
                   return pw.TableRow(children: [
                       pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(DateFormat('dd/MM/yyyy').format(e.fecha), style: pw.TextStyle(font: fontRegular))),
                       pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(e.cliente, style: pw.TextStyle(font: fontRegular))),
                       pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("\$ ${utilidad.toStringAsFixed(2)}", style: pw.TextStyle(font: fontRegular), textAlign: pw.TextAlign.right)),
                   ]);
                }).toList()
            ]),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
                pw.Text("TOTAL: ", style: pw.TextStyle(font: fontBold, fontSize: 16)),
                pw.Text("\$ ${NumberFormat("#,##0.00").format(total)}", style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.green900)),
            ])
          ];
        }
      )
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Reporte_Financiero.pdf');
  }

  // ==========================================
  // 3. CUADRANTE DE TURNOS (CALENDARIO GRÁFICO)
  // ==========================================
  static Future<void> generarReporteStaff(List<Evento> eventos, DateTime fechaFoco, bool esMensual) async {
    await initializeDateFormatting('es', null);
    
    final pdf = pw.Document();
    final fontBold = await PdfGoogleFonts.openSansBold();
    final fontRegular = await PdfGoogleFonts.openSansRegular();

    String titulo = esMensual 
      ? DateFormat('MMMM yyyy', 'es').format(fechaFoco).toUpperCase()
      : "SEMANA DEL ${DateFormat('dd/MMM', 'es').format(fechaFoco).toUpperCase()}";

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Header(
                level: 0, 
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("CUADRANTE DE TRIPULACIÓN", style: pw.TextStyle(font: fontBold, fontSize: 16)),
                    pw.Text(titulo, style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.blue900)),
                  ]
                )
              ),
              pw.SizedBox(height: 10),
              
              esMensual 
                ? _buildCalendarioMensual(eventos, fechaFoco, fontBold, fontRegular)
                : _buildCalendarioSemanal(eventos, fechaFoco, fontBold, fontRegular),
            ]
          );
        }
      )
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Cuadrante_Staff.pdf');
  }

  // ==========================================
  // 4. LISTA DE COMPRAS SEMANAL (NUEVO)
  // ==========================================
  static Future<void> generarListaCompras(Map<String, num> items, String periodo) async {
    await initializeDateFormatting('es', null);
    final pdf = pw.Document();
    final fontBold = await PdfGoogleFonts.openSansBold();
    final fontRegular = await PdfGoogleFonts.openSansRegular();

    final listaItems = items.entries.toList();
    listaItems.sort((a, b) => a.key.compareTo(b.key));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0, 
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("LISTA DE COMPRAS / BODEGA", style: pw.TextStyle(font: fontBold, fontSize: 16)),
                  pw.Text(periodo.toUpperCase(), style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.blue900)),
                ]
              )
            ),
            pw.SizedBox(height: 20),
            
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(3), 
                1: const pw.FlexColumnWidth(1), 
                2: const pw.FlexColumnWidth(1), 
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("PRODUCTO / INSUMO", style: pw.TextStyle(font: fontBold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("CANTIDAD", style: pw.TextStyle(font: fontBold), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("CHECK", style: pw.TextStyle(font: fontBold), textAlign: pw.TextAlign.center)),
                  ]
                ),
                ...listaItems.map((entry) {
                   return pw.TableRow(
                     children: [
                       pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(entry.key, style: pw.TextStyle(font: fontRegular))),
                       pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(entry.value.toString(), style: pw.TextStyle(font: fontBold, fontSize: 12), textAlign: pw.TextAlign.center)),
                       pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Container(width: 10, height: 10, decoration: pw.BoxDecoration(border: pw.Border.all()))),
                     ]
                   );
                }).toList()
              ]
            ),
          ];
        }
      )
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Lista_Compras.pdf');
  }


  // ==========================================
  // HELPERS INTERNOS Y LÓGICA DE CALENDARIO
  // ==========================================

  static pw.Widget _buildCalendarioMensual(List<Evento> eventos, DateTime mes, pw.Font fontBold, pw.Font fontRegular) {
    final int daysInMonth = _getDaysInMonth(mes.year, mes.month);
    final firstDayOfMonth = DateTime(mes.year, mes.month, 1);
    final startingWeekday = firstDayOfMonth.weekday; 

    final List<pw.Widget> celdas = [];
    final diasSemana = ['LUN', 'MAR', 'MIE', 'JUE', 'VIE', 'SAB', 'DOM'];
    for (var dia in diasSemana) {
      celdas.add(pw.Container(alignment: pw.Alignment.center, padding: const pw.EdgeInsets.all(5), color: PdfColors.grey300, child: pw.Text(dia, style: pw.TextStyle(font: fontBold, fontSize: 10))));
    }

    for (int i = 1; i < startingWeekday; i++) {
      celdas.add(pw.Container(decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400))));
    }

    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(mes.year, mes.month, i);
      final eventosDelDia = eventos.where((e) => isSameDay(e.fecha, date)).toList();
      celdas.add(_buildDiaCelda(i, eventosDelDia, fontBold, fontRegular));
    }

    int totalCells = (startingWeekday - 1) + daysInMonth;
    int remaining = 7 - (totalCells % 7);
    if (remaining < 7) {
      for (int i = 0; i < remaining; i++) {
        celdas.add(pw.Container(decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400))));
      }
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey600),
      children: _chunkList(celdas, 7).map((row) => pw.TableRow(children: row)).toList(),
    );
  }

  static pw.Widget _buildCalendarioSemanal(List<Evento> eventos, DateTime fechaFoco, pw.Font fontBold, pw.Font fontRegular) {
    final inicioSemana = fechaFoco.subtract(Duration(days: fechaFoco.weekday - 1));
    final List<pw.Widget> celdasHeader = [];
    final List<pw.Widget> celdasBody = [];

    for (int i = 0; i < 7; i++) {
      final date = inicioSemana.add(Duration(days: i));
      celdasHeader.add(pw.Container(alignment: pw.Alignment.center, padding: const pw.EdgeInsets.all(5), color: PdfColors.grey300, child: pw.Text(DateFormat('E d').format(date).toUpperCase(), style: pw.TextStyle(font: fontBold, fontSize: 10))));
      final eventosDelDia = eventos.where((e) => isSameDay(e.fecha, date)).toList();
      celdasBody.add(_buildDiaCelda(date.day, eventosDelDia, fontBold, fontRegular, minHeight: 350));
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey600),
      children: [pw.TableRow(children: celdasHeader), pw.TableRow(children: celdasBody)]
    );
  }

  static pw.Widget _buildDiaCelda(int dia, List<Evento> eventos, pw.Font fb, pw.Font fr, {double minHeight = 65}) {
    return pw.Container(
      height: minHeight,
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Align(alignment: pw.Alignment.topRight, child: pw.Text("$dia", style: pw.TextStyle(font: fb, fontSize: 8, color: PdfColors.grey700))),
          ...eventos.map((e) {
            final horario = "${e.itinerario['inicio'] ?? '?'} - ${e.itinerario['fin'] ?? '?'}";
            List<String> staffNombres = [];
            if (e.staffAsignado['Mesero'] != null) staffNombres.addAll(List<String>.from(e.staffAsignado['Mesero']!));
            if (e.staffAsignado['Nanita'] != null) staffNombres.addAll(List<String>.from(e.staffAsignado['Nanita']!));
            
            return pw.Container(
              margin: const pw.EdgeInsets.only(top: 2),
              padding: const pw.EdgeInsets.all(2),
              decoration: const pw.BoxDecoration(color: PdfColors.blue50, borderRadius: pw.BorderRadius.all(pw.Radius.circular(2))),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(horario, style: pw.TextStyle(font: fb, fontSize: 6, color: PdfColors.blue900)),
                  pw.Text(e.cliente, style: pw.TextStyle(font: fb, fontSize: 7)),
                  pw.Text(staffNombres.join(", "), style: pw.TextStyle(font: fr, fontSize: 6, color: PdfColors.grey800)),
                ]
              )
            );
          })
        ]
      )
    );
  }

  static int _getDaysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;
  
  static bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    List<List<T>> chunks = [];
    for (int i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(i, i + chunkSize > list.length ? list.length : i + chunkSize));
    }
    return chunks;
  }
  
  static pw.Widget _buildSectionTitle(String text, pw.Font font, PdfColor color) {
    return pw.Container(margin: const pw.EdgeInsets.only(bottom: 3, top: 5), child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 10, color: color, fontWeight: pw.FontWeight.bold)));
  }
  static pw.TableRow _buildTableRow(String label, String value, pw.Font fontLabel, pw.Font fontValue, PdfColor colorLabel, PdfColor colorValue) {
    return pw.TableRow(children: [pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4), child: pw.Text(label, style: pw.TextStyle(font: fontLabel, fontSize: 8, color: colorLabel))), pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4), child: pw.Text(value.isEmpty ? "---" : value, style: pw.TextStyle(font: fontValue, fontSize: 8, color: colorValue)))]);
  }
  static pw.Widget _buildSignatureLine(String label, pw.Font font, PdfColor color) {
    return pw.Column(children: [pw.Container(width: 130, height: 1, color: color), pw.SizedBox(height: 3), pw.Text(label, style: pw.TextStyle(font: font, fontSize: 7, color: color))]);
  }
}