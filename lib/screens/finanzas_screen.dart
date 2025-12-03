import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/evento_model.dart';
import '../services/firebase_service.dart';

class CalculadoraUtilidadScreen extends StatefulWidget {
  final Evento evento;
  const CalculadoraUtilidadScreen({super.key, required this.evento});

  @override
  _CalculadoraUtilidadScreenState createState() => _CalculadoraUtilidadScreenState();
}

class _CalculadoraUtilidadScreenState extends State<CalculadoraUtilidadScreen> {
  final FirebaseService _service = FirebaseService();

  // Variables dinámicas
  Map<String, double> _preciosUnitarios = {}; 
  bool _cargando = true;

  // Variables de estado
  final Map<String, int> _cantidadesUsadas = {};
  double _totalIngreso = 0;
  double _costoNomina = 0;
  double _costoInsumos = 0;
  double _utilidadNeta = 0;

  @override
  void initState() {
    super.initState();
    _totalIngreso = widget.evento.precioTotal;
    _cargarDatosDeLaNube();
  }

  Future<void> _cargarDatosDeLaNube() async {
    // 1. Descargar precios de Firebase
    Map<String, double> preciosNube = await _service.obtenerCatalogoPrecios();
    
    if (mounted) {
      setState(() {
        _preciosUnitarios = preciosNube;
        
        // 2. Inicializar contadores
        _inicializarInsumos();
        
        // 3. Calcular finanzas iniciales
        _calcularNomina();
        _recalcularFinanzas();
        
        _cargando = false; 
      });
    }
  }

  void _inicializarInsumos() {
    // Solo agregamos al formulario los que NO son sueldos
    _preciosUnitarios.forEach((nombre, precio) {
      if (!nombre.startsWith('Sueldo')) {
        _cantidadesUsadas[nombre] = 0; 
      }
    });
    
    // Cargar datos previos si existen
    if (widget.evento.consumo.containsKey('cantidades_finales')) {
      Map<String, dynamic> guardado = widget.evento.consumo['cantidades_finales'];
      guardado.forEach((key, val) {
        if (_cantidadesUsadas.containsKey(key)) {
          _cantidadesUsadas[key] = val as int;
        }
      });
    } else if (widget.evento.consumo.containsKey('checklist')) {
      List<dynamic> checklist = widget.evento.consumo['checklist'];
      for (var item in checklist) {
        if (_cantidadesUsadas.containsKey(item['item'])) {
          _cantidadesUsadas[item['item']] = item['cantidad'];
        }
      }
    }
  }

  void _calcularNomina() {
    int numMeseros = widget.evento.staffAsignado['Mesero']?.length ?? 0;
    int numNanitas = widget.evento.staffAsignado['Nanita']?.length ?? 0;
    int numLimpieza = widget.evento.staffAsignado['Limpieza']?.length ?? 0;

    double sueldoMesero = _preciosUnitarios['Sueldo Mesero'] ?? 0;
    double sueldoNanita = _preciosUnitarios['Sueldo Nanita'] ?? 0;
    double sueldoLimpieza = _preciosUnitarios['Sueldo Limpieza'] ?? 0;

    _costoNomina = (numMeseros * sueldoMesero) + 
                   (numNanitas * sueldoNanita) + 
                   (numLimpieza * sueldoLimpieza);
  }

  void _recalcularFinanzas() {
    double gastoInsumos = 0;
    _cantidadesUsadas.forEach((item, cantidad) {
      double precio = _preciosUnitarios[item] ?? 0;
      gastoInsumos += (cantidad * precio);
    });

    setState(() {
      _costoInsumos = gastoInsumos;
      _utilidadNeta = _totalIngreso - (_costoNomina + _costoInsumos);
    });
  }

  Future<void> _cerrarMision() async {
    Map<String, dynamic> cierre = {
      'estatus': 'FINALIZADO',
      'consumo': {
        ...widget.evento.consumo,
        'cantidades_finales': _cantidadesUsadas,
        'gasto_nomina': _costoNomina,
        'gasto_insumos': _costoInsumos,
        'ganancia_neta': _utilidadNeta
      }
    };
    await _service.actualizarEvento(widget.evento.id, cierre);
    if (mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("💰 Misión Cerrada Exitosamente.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B1026),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B1026),
      appBar: AppBar(
        title: const Text("Cierre de Misión", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF00E5FF)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResumenCard(),
            const SizedBox(height: 20),
            const Text("📉 DESGLOSE DE COSTOS", style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5)),
            const SizedBox(height: 10),

            // NÓMINA
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: const Color(0xFF1B2240), borderRadius: BorderRadius.circular(15)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("👨‍🚀 Nómina de Tripulación", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text("-\$${_costoNomina.toStringAsFixed(0)}", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(color: Colors.white10),
                  _buildStaffRow("Meseros", widget.evento.staffAsignado['Mesero']?.length ?? 0, _preciosUnitarios['Sueldo Mesero'] ?? 0),
                  _buildStaffRow("Nanitas", widget.evento.staffAsignado['Nanita']?.length ?? 0, _preciosUnitarios['Sueldo Nanita'] ?? 0),
                  _buildStaffRow("Limpieza", widget.evento.staffAsignado['Limpieza']?.length ?? 0, _preciosUnitarios['Sueldo Limpieza'] ?? 0),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // INSUMOS
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: const Color(0xFF161C36), borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3))),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("📦 Consumo de Insumos", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text("-\$${_costoInsumos.toStringAsFixed(0)}", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text("Cantidades utilizadas:", style: TextStyle(color: Colors.white30, fontSize: 10)),
                  const Divider(color: Colors.white10),
                  
                  // Generar lista dinámica excluyendo sueldos
                  ..._preciosUnitarios.keys.where((k) => !k.startsWith('Sueldo')).map((nombreItem) {
                    return _buildInsumoCounter(nombreItem, _preciosUnitarios[nombreItem]!);
                  }).toList(),
                ],
              ),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _cerrarMision,
                icon: const Icon(Icons.lock_outline, color: Colors.black),
                label: const Text("CONFIRMAR CIERRE Y GUARDAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FFAA), padding: const EdgeInsets.all(18)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF00FFAA).withOpacity(0.2), const Color(0xFF1B2240)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00FFAA)),
      ),
      child: Column(
        children: [
          const Text("UTILIDAD FINAL", style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2)),
          const SizedBox(height: 5),
          Text("\$ ${NumberFormat("#,##0.00").format(_utilidadNeta)}", style: const TextStyle(color: Color(0xFF00FFAA), fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(children: [const Text("Ingreso", style: TextStyle(color: Colors.white54, fontSize: 10)), Text("\$${_totalIngreso.toInt()}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
              Column(children: [const Text("Gastos", style: TextStyle(color: Colors.white54, fontSize: 10)), Text("-\$${(_costoNomina + _costoInsumos).toInt()}", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))]),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStaffRow(String rol, int cantidad, double costoUnitario) {
    if (cantidad == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$cantidad x $rol", style: const TextStyle(color: Colors.white70)),
          Text("\$${(cantidad * costoUnitario).toInt()}", style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildInsumoCounter(String nombre, double precio) {
    int cantidad = _cantidadesUsadas[nombre] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 4, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(nombre, style: const TextStyle(color: Colors.white)), Text("\$${precio.toInt()} c/u", style: const TextStyle(color: Colors.white30, fontSize: 10))])),
          GestureDetector(onTap: () { if (cantidad > 0) setState(() { _cantidadesUsadas[nombre] = cantidad - 1; _recalcularFinanzas(); }); }, child: Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(5)), child: const Icon(Icons.remove, color: Colors.white, size: 16))),
          const SizedBox(width: 15),
          Text("$cantidad", style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 15),
          GestureDetector(onTap: () { setState(() { _cantidadesUsadas[nombre] = cantidad + 1; _recalcularFinanzas(); }); }, child: Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(5)), child: const Icon(Icons.add, color: Colors.white, size: 16))),
          Expanded(flex: 2, child: Text("\$${(cantidad * precio).toInt()}", textAlign: TextAlign.right, style: const TextStyle(color: Colors.white54)))
        ],
      ),
    );
  }
}