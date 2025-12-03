import 'package:flutter/material.dart';
import '../models/evento_model.dart';
import '../services/firebase_service.dart';
import 'finanzas_screen.dart';

class ListaSuministrosScreen extends StatefulWidget {
  final Evento evento;
  const ListaSuministrosScreen({super.key, required this.evento});

  @override
  _ListaSuministrosScreenState createState() => _ListaSuministrosScreenState();
}

class _ListaSuministrosScreenState extends State<ListaSuministrosScreen> {
  final FirebaseService _service = FirebaseService();
  List<Map<String, dynamic>> _checklist = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    // 1. Si ya hay checklist guardado en este evento, úsalo
    if (widget.evento.consumo.containsKey('checklist')) {
      setState(() {
        _checklist = List<Map<String, dynamic>>.from(widget.evento.consumo['checklist']);
        _cargando = false;
      });
    } else {
      // 2. Si es NUEVO: Descargar configuración y calcular
      Map<String, double> factores = await _service.obtenerFactores();
      // Necesitamos también los nombres de los productos (keys de precios)
      Map<String, double> precios = await _service.obtenerCatalogoPrecios();
      
      _generarSugeridosDinamico(precios, factores);
    }
  }

  void _generarSugeridosDinamico(Map<String, double> precios, Map<String, double> factores) {
    int pax = widget.evento.invitados;
    List<Map<String, dynamic>> listaGenerada = [];

    // Recorremos TODOS los productos que existen en tu configuración
    precios.forEach((nombreProducto, precio) {
      // Ignoramos los sueldos, solo queremos insumos
      if (!nombreProducto.startsWith('Sueldo')) {
        
        // Buscamos si tiene factor configurado
        double factor = factores[nombreProducto] ?? 0.0;
        
        // Calculamos cantidad
        int cantidadSugerida = 0;
        if (factor > 0) {
          // Fórmula: Invitados * Factor
          // (Ej: 100 * 0.06 = 6 bolsas)
          cantidadSugerida = (pax * factor).ceil();
        }
        // Si el factor es 0, la cantidad inicial es 0 (se llena manual)

        listaGenerada.add({
          "item": nombreProducto,
          "cantidad": cantidadSugerida,
          "check": false
        });
      }
    });

    // Ordenar alfabéticamente para que sea fácil buscar
    listaGenerada.sort((a, b) => (a['item'] as String).compareTo(b['item'] as String));

    setState(() {
      _checklist = listaGenerada;
      _cargando = false;
    });
  }

  Future<void> _guardarCambios() async {
    Map<String, dynamic> nuevosDatos = {
      'consumo': {
        ...widget.evento.consumo, 
        'checklist': _checklist,
      }
    };
    await _service.actualizarEvento(widget.evento.id, nuevosDatos);
  }

  void _editarCantidad(int index, int delta) {
    setState(() {
      int actual = _checklist[index]['cantidad'];
      if (actual + delta >= 0) {
        _checklist[index]['cantidad'] = actual + delta;
        _guardarCambios();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Scaffold(backgroundColor: Color(0xFF0B1026), body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFF0B1026),
      appBar: AppBar(
        title: Text("Bodega: ${widget.evento.cliente}", style: const TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF00E5FF)),
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_money, color: Color(0xFFFFD700)),
            tooltip: "Ir a Cierre Financiero",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CalculadoraUtilidadScreen(evento: widget.evento))),
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _checklist.length,
        itemBuilder: (context, index) {
          final item = _checklist[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: const Color(0xFF1B2240), borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Checkbox(
                  activeColor: const Color(0xFF00E5FF),
                  checkColor: Colors.black,
                  value: item['check'],
                  onChanged: (val) {
                    setState(() => item['check'] = val);
                    _guardarCambios();
                  }
                ),
                Expanded(child: Text(item['item'], style: TextStyle(color: item['check'] ? Colors.white38 : Colors.white, decoration: item['check'] ? TextDecoration.lineThrough : null))),
                
                if (!item['check']) ...[
                  IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.white30, size: 20), onPressed: () => _editarCantidad(index, -1)),
                  Text("${item['cantidad']}", style: const TextStyle(color: Color(0xFF00FFAA), fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.white30, size: 20), onPressed: () => _editarCantidad(index, 1)),
                ] else 
                  Padding(padding: const EdgeInsets.only(right: 20), child: Text("${item['cantidad']}", style: const TextStyle(color: Colors.white30))),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _guardarCambios();
          Navigator.pop(context);
        },
        label: const Text("GUARDAR"),
        icon: const Icon(Icons.save),
        backgroundColor: const Color(0xFF00E5FF),
      ),
    );
  }
}