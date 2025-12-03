import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/evento_model.dart';
import '../services/firebase_service.dart';
import '../services/pdf_generator.dart'; // Necesario para exportar

class ReporteUtilidadScreen extends StatefulWidget {
  const ReporteUtilidadScreen({super.key});

  @override
  _ReporteUtilidadScreenState createState() => _ReporteUtilidadScreenState();
}

class _ReporteUtilidadScreenState extends State<ReporteUtilidadScreen> {
  final FirebaseService _service = FirebaseService();
  List<Evento> _eventos = [];
  final Map<String, bool> _seleccionados = {}; // Guarda qué IDs están marcados
  double _totalUtilidad = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1026),
      appBar: AppBar(
        title: const Text("Reporte Financiero", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF00E5FF)),
        actions: [
          // BOTÓN DE EXPORTAR PDF
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Color(0xFFFFD700)), // Dorado
            tooltip: "Exportar Selección",
            onPressed: _exportarSeleccionPDF, // 👇 Llama a la función de abajo
          )
        ],
      ),
      body: Column(
        children: [
          // TARJETA DE TOTAL ACUMULADO
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2240),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD700))
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("UTILIDAD SELECCIONADA", style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text("\$ ${NumberFormat("#,##0.00").format(_totalUtilidad)}", style: const TextStyle(color: Color(0xFF00FFAA), fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Align(
              alignment: Alignment.centerLeft, 
              child: Text("Misiones Finalizadas (Marca para sumar)", style: TextStyle(color: Colors.white54, fontSize: 12))
            ),
          ),

          // LISTA DE EVENTOS FINALIZADOS
          Expanded(
            child: StreamBuilder<List<Evento>>(
              stream: _service.obtenerEventosFinalizados(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No hay misiones cerradas aún.", style: TextStyle(color: Colors.white30)));
                }
                
                // Actualizamos la lista local para poder filtrar después
                _eventos = snapshot.data!;
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: _eventos.length,
                  itemBuilder: (context, index) {
                    final evento = _eventos[index];
                    // Obtenemos la ganancia guardada (si es nula, es 0)
                    final utilidad = (evento.consumo['ganancia_neta'] as num?)?.toDouble() ?? 0;
                    final isSelected = _seleccionados[evento.id] ?? false;

                    return Card(
                      color: const Color(0xFF161C36),
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: CheckboxListTile(
                        activeColor: const Color(0xFF00E5FF),
                        checkColor: Colors.black,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        title: Text(evento.cliente, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(DateFormat('dd/MM/yyyy').format(evento.fecha), style: const TextStyle(color: Colors.white54)),
                        secondary: Text("\$ ${utilidad.toStringAsFixed(0)}", style: TextStyle(color: utilidad > 0 ? const Color(0xFF00FFAA) : Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                        value: isSelected,
                        onChanged: (val) {
                          setState(() {
                            _seleccionados[evento.id] = val!;
                            _recalcularTotal();
                          });
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 1. Sumar solo lo seleccionado
  void _recalcularTotal() {
    double suma = 0;
    for (var e in _eventos) {
      if (_seleccionados[e.id] == true) {
        suma += (e.consumo['ganancia_neta'] as num?)?.toDouble() ?? 0;
      }
    }
    _totalUtilidad = suma;
  }

  // 2. Filtrar y Generar PDF
  void _exportarSeleccionPDF() {
    // Filtramos la lista completa buscando solo los IDs marcados como true
    final listaParaImprimir = _eventos.where((e) => _seleccionados[e.id] == true).toList();

    if (listaParaImprimir.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecciona al menos una misión")));
      return;
    }

    // Llamamos al generador con la lista filtrada y el total calculado
    PdfGenerator.generarReporteUtilidad(listaParaImprimir, _totalUtilidad);
  }
}