import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/evento_model.dart';
import '../services/firebase_service.dart';

class NuevaMisionScreen extends StatefulWidget {
  const NuevaMisionScreen({super.key});

  @override
  _NuevaMisionScreenState createState() => _NuevaMisionScreenState();
}

class _NuevaMisionScreenState extends State<NuevaMisionScreen> {
  final FirebaseService _service = FirebaseService();
  
  // Datos Generales
  final TextEditingController _clienteCtrl = TextEditingController();
  final TextEditingController _telefonoCtrl = TextEditingController();
  final TextEditingController _cumpleaneroCtrl = TextEditingController();
  final TextEditingController _adultosCtrl = TextEditingController(text: "30");
  final TextEditingController _ninosCtrl = TextEditingController(text: "20");
  
  // Datos del Machote (Logística)
  final TextEditingController _aguasCtrl = TextEditingController();
  final TextEditingController _refrescosCtrl = TextEditingController();
  final TextEditingController _pastelCtrl = TextEditingController();
  final TextEditingController _pinataCtrl = TextEditingController();
  final TextEditingController _obsCtrl = TextEditingController();

  DateTime _fechaSeleccionada = DateTime.now();
  String _paqueteSeleccionado = 'Galáctico';
  String _botanaSeleccionada = 'Básica';
  
  // Itinerario (Horas por defecto)
  TimeOfDay _horaInicio = TimeOfDay(hour: 14, minute: 0);
  TimeOfDay _horaComida = TimeOfDay(hour: 16, minute: 0);
  TimeOfDay _horaPastel = TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _horaFin = TimeOfDay(hour: 19, minute: 0);

  double _totalEstimado = 0;

  final Map<String, double> _preciosBase = {
    'Galáctico': 650, 'Nebula': 690, 'Escolar': 460,
  };

  @override
  void initState() {
    super.initState();
    _calcular();
  }

  void _calcular() {
    int totalPersonas = (int.tryParse(_adultosCtrl.text) ?? 0) + (int.tryParse(_ninosCtrl.text) ?? 0);
    double precioUnitario = _preciosBase[_paqueteSeleccionado] ?? 0;
    if (_fechaSeleccionada.weekday >= 1 && _fechaSeleccionada.weekday <= 3) {
      precioUnitario = precioUnitario * 0.92; // Descuento Lun-Mie
    }
    setState(() {
      _totalEstimado = totalPersonas * precioUnitario;
    });
  }

  Future<void> _guardarMision() async {
    if (_clienteCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Falta nombre del cliente")));
      return;
    }

    // Convertir horas a String para guardar
    Map<String, String> itinerarioMap = {
      'inicio': _horaInicio.format(context),
      'comida': _horaComida.format(context),
      'pastel': _horaPastel.format(context),
      'fin': _horaFin.format(context),
    };

    Evento nuevoEvento = Evento(
      id: '',
      fecha: _fechaSeleccionada,
      cliente: _clienteCtrl.text,
      telefono: _telefonoCtrl.text,
      cumpleanero: _cumpleaneroCtrl.text,
      paquete: _paqueteSeleccionado,
      invitados: (int.tryParse(_adultosCtrl.text) ?? 0) + (int.tryParse(_ninosCtrl.text) ?? 0),
      precioTotal: _totalEstimado,
      anticipo: 0,
      estatus: 'PENDIENTE',
      // Datos Machote
      saborAguas: _aguasCtrl.text,
      refrescos: _refrescosCtrl.text,
      botana: _botanaSeleccionada,
      pastel: _pastelCtrl.text,
      pinata: _pinataCtrl.text,
      observaciones: _obsCtrl.text,
      itinerario: itinerarioMap,
    );

    await _service.crearEvento(nuevoEvento);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Nueva Misión", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Color(0xFF00E5FF)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("📋 Datos de la Tripulación"),
            _buildInput("Cliente", _clienteCtrl, icon: Icons.person),
            _buildInput("Teléfono", _telefonoCtrl, icon: Icons.phone, isNum: true),
            _buildInput("Cumpleañero(a) y Edad", _cumpleaneroCtrl, icon: Icons.cake),
            
            SizedBox(height: 20),
            _buildSectionTitle("🚀 Lanzamiento"),
            _buildDatePicker(),
            SizedBox(height: 10),
            Row(children: [
              Expanded(child: _buildInput("Adultos", _adultosCtrl, isNum: true)),
              SizedBox(width: 10),
              Expanded(child: _buildInput("Niños", _ninosCtrl, isNum: true)),
            ]),
            
            SizedBox(height: 20),
            _buildSectionTitle("🍱 Suministros (Machote)"),
            _buildDropdown("Paquete", _paqueteSeleccionado, _preciosBase.keys.toList(), (val) {
              setState(() => _paqueteSeleccionado = val!); _calcular();
            }),
            _buildDropdown("Botana", _botanaSeleccionada, ['Básica', 'Premium', 'No incluye'], (val) => setState(() => _botanaSeleccionada = val!)),
            _buildInput("Sabores de Agua", _aguasCtrl, icon: Icons.local_drink),
            _buildInput("Detalle Refrescos", _refrescosCtrl, icon: Icons.local_bar),
            _buildInput("Pastel (Sabor/Trae)", _pastelCtrl, icon: Icons.cookie),
            _buildInput("Piñata (Personaje)", _pinataCtrl, icon: Icons.star),
            
            SizedBox(height: 20),
            _buildSectionTitle("⏱️ Itinerario de Vuelo"),
            _buildTimePicker("Inicio Evento", _horaInicio, (t) => setState(() => _horaInicio = t)),
            _buildTimePicker("Hora Comida", _horaComida, (t) => setState(() => _horaComida = t)),
            _buildTimePicker("Hora Pastel", _horaPastel, (t) => setState(() => _horaPastel = t)),
            _buildTimePicker("Fin Evento", _horaFin, (t) => setState(() => _horaFin = t)),

            SizedBox(height: 20),
            _buildInput("Observaciones / Notas", _obsCtrl, maxLines: 3),

            SizedBox(height: 30),
            Center(child: Text("Total Estimado: \$${_totalEstimado.toStringAsFixed(2)}", style: TextStyle(color: Color(0xFFFFD700), fontSize: 22, fontWeight: FontWeight.bold))),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _guardarMision,
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00E5FF), padding: EdgeInsets.symmetric(vertical: 15)),
                child: Text("CONFIRMAR Y GUARDAR", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              ),
            ),
            SizedBox(height: 40), // Espacio extra abajo
          ],
        ),
      ),
    );
  }

  // --- Widgets Auxiliares ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Text(title, style: TextStyle(color: Color(0xFF00E5FF), fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }

  Widget _buildInput(String label, TextEditingController ctrl, {bool isNum = false, IconData? icon, int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        onChanged: (_) => _calcular(),
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white54),
          prefixIcon: icon != null ? Icon(icon, color: Colors.white30) : null,
          filled: true,
          fillColor: Color(0xFF1B2240),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(color: Color(0xFF1B2240), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white70)),
          DropdownButton<String>(
            value: value,
            dropdownColor: Color(0xFF161C36),
            style: TextStyle(color: Colors.white),
            underline: Container(),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context, initialDate: _fechaSeleccionada, firstDate: DateTime.now(), lastDate: DateTime(2030),
          builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: Color(0xFF00E5FF))), child: child!),
        );
        if (picked != null) { setState(() => _fechaSeleccionada = picked); _calcular(); }
      },
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(color: Color(0xFF1B2240), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white24)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(DateFormat('dd/MM/yyyy').format(_fechaSeleccionada), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Icon(Icons.calendar_today, color: Color(0xFF00E5FF)),
        ]),
      ),
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay time, Function(TimeOfDay) onTimeChanged) {
    return InkWell(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context, initialTime: time,
          builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: Color(0xFF00E5FF))), child: child!),
        );
        if (picked != null) onTimeChanged(picked);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(color: Color(0xFF161C36), borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(Icons.access_time, color: Colors.white30, size: 20),
          SizedBox(width: 10),
          Text(label, style: TextStyle(color: Colors.white70)),
          Spacer(),
          Text(time.format(context), style: TextStyle(color: Color(0xFF00FFAA), fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}