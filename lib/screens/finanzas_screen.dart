import 'package:flutter/material.dart';
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
  final TextEditingController _gastosRealesCtrl = TextEditingController();
  
  double _ingresoTotal = 0;
  double _gastos = 0;
  double _utilidad = 0;

  @override
  void initState() {
    super.initState();
    _ingresoTotal = widget.evento.precioTotal;
    // Si ya habíamos guardado gastos antes, cargarlos
    if (widget.evento.consumo['gasto_operativo'] != null) {
      _gastos = (widget.evento.consumo['gasto_operativo'] as num).toDouble();
      _gastosCtrl.text = _gastos.toString();
    }
    _calcular();
  }
  
  // Alias para controller
  TextEditingController get _gastosCtrl => _gastosRealesCtrl;

  void _calcular() {
    double gastosInput = double.tryParse(_gastosCtrl.text) ?? 0;
    setState(() {
      _gastos = gastosInput;
      _utilidad = _ingresoTotal - _gastos;
    });
  }

  Future<void> _cerrarMision() async {
    Map<String, dynamic> cierre = {
      'estatus': 'FINALIZADO', // Cambia a verde en calendario
      'consumo': {
        ...widget.evento.consumo, // Mantiene lo del checklist
        'gasto_operativo': _gastos,
        'ganancia_neta': _utilidad
      }
    };
    
    await _service.actualizarEvento(widget.evento.id, cierre);
    Navigator.popUntil(context, (route) => route.isFirst); // Volver al inicio
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Misión Finalizada. Ganancia registrada.")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cierre Financiero"), backgroundColor: Colors.transparent, iconTheme: IconThemeData(color: Colors.white)),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            _buildCard("Ingreso Total", _ingresoTotal, Colors.green),
            SizedBox(height: 10),
            TextField(
              controller: _gastosCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: Colors.white),
              onChanged: (_) => _calcular(),
              decoration: InputDecoration(
                labelText: "Gastos Operativos Reales (Insumos + Staff)",
                labelStyle: TextStyle(color: Colors.white54),
                filled: true, fillColor: Color(0xFF1B2240),
                prefixIcon: Icon(Icons.remove_circle, color: Colors.red),
                border: OutlineInputBorder()
              ),
            ),
            SizedBox(height: 20),
            Divider(color: Colors.white24),
            SizedBox(height: 20),
            _buildCard("UTILIDAD NETA", _utilidad, _utilidad > 0 ? Color(0xFFFFD700) : Colors.red, grande: true),
            
            Spacer(),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _cerrarMision,
                icon: Icon(Icons.lock),
                label: Text("CERRAR Y GUARDAR"),
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00FFAA), foregroundColor: Colors.black, padding: EdgeInsets.all(20)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String titulo, double monto, Color color, {bool grande = false}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(color: Color(0xFF161C36), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(
        children: [
          Text(titulo, style: TextStyle(color: Colors.white54)),
          Text("\$ ${monto.toStringAsFixed(2)}", style: TextStyle(color: color, fontSize: grande ? 40 : 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}