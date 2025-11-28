import 'package:flutter/material.dart';
import '../models/evento_model.dart';
import '../services/firebase_service.dart';
import 'finanzas_screen.dart'; // Para navegar al cierre

class ListaSuministrosScreen extends StatefulWidget {
  final Evento evento;
  const ListaSuministrosScreen({super.key, required this.evento});

  @override
  _ListaSuministrosScreenState createState() => _ListaSuministrosScreenState();
}

class _ListaSuministrosScreenState extends State<ListaSuministrosScreen> {
  final FirebaseService _service = FirebaseService();
  List<Map<String, dynamic>> _checklist = [];

  @override
  void initState() {
    super.initState();
    // Si ya hay datos en Firebase, úsalos. Si no, genera sugeridos.
    if (widget.evento.consumo.isNotEmpty && widget.evento.consumo['checklist'] != null) {
      _checklist = List<Map<String, dynamic>>.from(widget.evento.consumo['checklist']);
    } else {
      _generarSugeridos();
    }
  }

  void _generarSugeridos() {
    int pax = widget.evento.invitados;
    _checklist = [
      {"item": "Bolsas de Hielo", "cantidad": (pax * 0.06).ceil(), "check": false},
      {"item": "Refrescos 2L", "cantidad": (pax * 0.05).ceil(), "check": false},
      {"item": "Vasos", "cantidad": pax + 10, "check": false},
      {"item": "Platos", "cantidad": pax + 10, "check": false},
      {"item": "Piñata", "cantidad": 1, "check": false},
    ];
  }

  Future<void> _guardarCambios() async {
    // Actualizamos el campo 'consumo' dentro del evento
    Map<String, dynamic> nuevosDatos = {
      'consumo': {
        'checklist': _checklist,
        'ultimo_guardado': DateTime.now().toString()
      }
    };
    await _service.actualizarEvento(widget.evento.id, nuevosDatos);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Bodega actualizada")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Insumos: ${widget.evento.cliente}", style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Color(0xFF00E5FF)),
        actions: [
          IconButton(
            icon: Icon(Icons.attach_money, color: Color(0xFFFFD700)),
            onPressed: () {
               // Navegar a Finanzas pasando el mismo evento
               Navigator.push(context, MaterialPageRoute(builder: (context) => CalculadoraUtilidadScreen(evento: widget.evento)));
            },
          )
        ],
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(20),
        itemCount: _checklist.length,
        itemBuilder: (context, index) {
          final item = _checklist[index];
          return Card(
            color: Color(0xFF1B2240),
            child: CheckboxListTile(
              activeColor: Color(0xFF00E5FF),
              checkColor: Colors.black,
              title: Text("${item['cantidad']} x ${item['item']}", style: TextStyle(color: Colors.white)),
              value: item['check'],
              onChanged: (val) {
                setState(() => item['check'] = val);
                _guardarCambios(); // Guardado automático al tocar
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _guardarCambios,
        label: Text("GUARDAR"),
        icon: Icon(Icons.save),
        backgroundColor: Color(0xFF00E5FF),
      ),
    );
  }
}