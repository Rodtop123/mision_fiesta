import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/evento_model.dart';
import '../services/firebase_service.dart';
import '../services/pdf_generator.dart';

class ReporteComprasScreen extends StatefulWidget {
  const ReporteComprasScreen({super.key});

  @override
  _ReporteComprasScreenState createState() => _ReporteComprasScreenState();
}

class _ReporteComprasScreenState extends State<ReporteComprasScreen> {
  final FirebaseService _service = FirebaseService();
  
  DateTime _fechaInicio = DateTime.now(); // Inicio de la semana a calcular
  Map<String, num> _listaCompras = {}; // Mapa acumulado
  bool _calculando = false;
  String _tituloPeriodo = "";

  @override
  void initState() {
    super.initState();
    // Ajustar al lunes de esta semana
    _fechaInicio = _fechaInicio.subtract(Duration(days: _fechaInicio.weekday - 1));
    _calcularNecesidades();
  }

  Future<void> _calcularNecesidades() async {
    setState(() {
      _calculando = true;
      _listaCompras.clear();
    });

    try {
      // 1. Obtener rango de fechas (Lunes a Domingo)
      DateTime inicio = DateTime(_fechaInicio.year, _fechaInicio.month, _fechaInicio.day);
      DateTime fin = inicio.add(const Duration(days: 6, hours: 23, minutes: 59));
      
      _tituloPeriodo = "Semana del ${DateFormat('d MMM').format(inicio)} al ${DateFormat('d MMM').format(fin)}";

      // 2. Obtener eventos
      final eventosStream = await _service.obtenerEventos().first; 
      
      final eventosSemana = eventosStream.where((e) => 
        e.fecha.isAfter(inicio.subtract(const Duration(seconds: 1))) && 
        e.fecha.isBefore(fin.add(const Duration(seconds: 1)))
      ).toList();

      // 3. Obtener Factores y Precios Base
      final factores = await _service.obtenerFactores();
      final preciosBase = await _service.obtenerCatalogoPrecios();

      // 4. PROCESAMIENTO (LA SUMA)
      for (var evento in eventosSemana) {
        
        if (evento.consumo.containsKey('checklist')) {
          // CASO A: Ya tiene lista guardada (usamos la real)
          List<dynamic> checklist = evento.consumo['checklist'];
          for (var item in checklist) {
            // Sumamos todo lo que esté en la lista
            String nombre = item['item'];
            int cantidad = item['cantidad'] ?? 0;
            _agregarAlTotal(nombre, cantidad);
          }
        } else {
          // CASO B: No tiene lista (calculamos estimado)
          int pax = evento.invitados;
          preciosBase.forEach((nombreProd, _) {
            if (!nombreProd.startsWith('Sueldo')) { // Ignorar sueldos
              double factor = factores[nombreProd] ?? 0.0;
              if (factor > 0) {
                int cantidadEstimada = (pax * factor).ceil();
                _agregarAlTotal(nombreProd, cantidadEstimada);
              }
            }
          });
        }
      }

      setState(() => _calculando = false);

    } catch (e) {
      print(e);
      setState(() => _calculando = false);
    }
  }

  void _agregarAlTotal(String item, num cantidad) {
    if (_listaCompras.containsKey(item)) {
      _listaCompras[item] = _listaCompras[item]! + cantidad;
    } else {
      _listaCompras[item] = cantidad;
    }
  }

  void _cambiarSemana(int dias) {
    setState(() {
      _fechaInicio = _fechaInicio.add(Duration(days: dias));
    });
    _calcularNecesidades();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1026),
      appBar: AppBar(
        title: const Text("Lista de Compras", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF00E5FF)),
        actions: [
          // 👇 ÚNICO BOTÓN: IMPRIMIR PDF (Quitamos el carrito redundante)
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Color(0xFFFFD700)),
            tooltip: "Imprimir Lista",
            onPressed: () => PdfGenerator.generarListaCompras(_listaCompras, _tituloPeriodo),
          )
        ],
      ),
      body: Column(
        children: [
          // CONTROL DE FECHAS
          Container(
            color: const Color(0xFF1B2240),
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left, color: Colors.white), onPressed: () => _cambiarSemana(-7)),
                Text(_tituloPeriodo, style: const TextStyle(color: Color(0xFF00FFAA), fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.chevron_right, color: Colors.white), onPressed: () => _cambiarSemana(7)),
              ],
            ),
          ),
          
          // LISTA
          Expanded(
            child: _calculando 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
              : _listaCompras.isEmpty 
                ? const Center(child: Text("No hay insumos necesarios para esta semana", style: TextStyle(color: Colors.white30)))
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _listaCompras.length,
                    itemBuilder: (context, index) {
                      String key = _listaCompras.keys.elementAt(index);
                      num cantidad = _listaCompras[key]!;
                      
                      return Card(
                        color: const Color(0xFF161C36),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          // Usamos un ícono genérico de caja/insumo en lugar del carrito para evitar confusión visual
                          leading: const Icon(Icons.inventory_2, color: Color(0xFF00E5FF)), 
                          title: Text(key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FFAA).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20)
                            ),
                            child: Text("$cantidad", style: const TextStyle(color: Color(0xFF00FFAA), fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}