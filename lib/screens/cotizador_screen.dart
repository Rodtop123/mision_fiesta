import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/evento_model.dart';
import '../services/firebase_service.dart';
import '../models/staff_model.dart';
import 'gestion_staff_screen.dart';

class NuevaMisionScreen extends StatefulWidget {
  final Evento? eventoEditar;
  const NuevaMisionScreen({super.key, this.eventoEditar});

  @override
  _NuevaMisionScreenState createState() => _NuevaMisionScreenState();
}

class _NuevaMisionScreenState extends State<NuevaMisionScreen> {
  final FirebaseService _service = FirebaseService();

  Map<String, List<String>> _staffSeleccionado = {
    'Mesero': [], 'Nanita': [], 'Limpieza': []
  };
  
  final TextEditingController _clienteCtrl = TextEditingController();
  final TextEditingController _telefonoCtrl = TextEditingController();
  final TextEditingController _cumpleaneroCtrl = TextEditingController();
  final TextEditingController _adultosCtrl = TextEditingController(text: "30");
  final TextEditingController _ninosCtrl = TextEditingController(text: "20");
  
  final TextEditingController _aguasCtrl = TextEditingController();
  final TextEditingController _refrescosCtrl = TextEditingController();
  final TextEditingController _pastelCtrl = TextEditingController();
  final TextEditingController _pinataCtrl = TextEditingController();
  final TextEditingController _obsCtrl = TextEditingController();

  DateTime _fechaSeleccionada = DateTime.now();
  String _paqueteSeleccionado = 'Galáctico';
  String _botanaSeleccionada = 'Básica';
  
  TimeOfDay _horaInicio = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay _horaComida = const TimeOfDay(hour: 16, minute: 0);
  TimeOfDay _horaPastel = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _horaFin = const TimeOfDay(hour: 19, minute: 0);

  double _totalEstimado = 0;
  int _totalInvitadosCalculado = 50; // Variable para mostrar la suma en tiempo real

  final Map<String, double> _preciosBase = {'Galáctico': 650, 'Nebula': 690, 'Escolar': 460};

  @override
  void initState() {
    super.initState();
    if (widget.eventoEditar != null) {
      _cargarDatosExistentes();
      final e = widget.eventoEditar!;
      if (e.staffAsignado.isNotEmpty) {
        _staffSeleccionado = e.staffAsignado.map((key, value) => MapEntry(key, List<String>.from(value)));
      }
    } else {
      _calcular();
    }
  }

  void _cargarDatosExistentes() {
    final e = widget.eventoEditar!;
    _clienteCtrl.text = e.cliente;
    _telefonoCtrl.text = e.telefono;
    _cumpleaneroCtrl.text = e.cumpleanero;
    
    // Cargar separados
    _adultosCtrl.text = e.adultos.toString(); 
    _ninosCtrl.text = e.ninos.toString(); 
    
    _fechaSeleccionada = e.fecha;
    _paqueteSeleccionado = e.paquete;
    _botanaSeleccionada = e.botana.isEmpty ? 'Básica' : e.botana;
    _aguasCtrl.text = e.saborAguas;
    _refrescosCtrl.text = e.refrescos;
    _pastelCtrl.text = e.pastel;
    _pinataCtrl.text = e.pinata;
    _obsCtrl.text = e.observaciones;
    _totalEstimado = e.precioTotal;
    
    if (e.itinerario.isNotEmpty) {
      _horaInicio = _parseTime(e.itinerario['inicio']);
      _horaComida = _parseTime(e.itinerario['comida']);
      _horaPastel = _parseTime(e.itinerario['pastel']);
      _horaFin = _parseTime(e.itinerario['fin']);
    }
    _calcular(); // Para actualizar el total visual
  }
  
  TimeOfDay _parseTime(String? timeStr) {
    if (timeStr == null || timeStr == '--') return const TimeOfDay(hour: 12, minute: 0);
    try {
      final parts = timeStr.split(":");
      if(parts.length >= 2) {
         return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1].substring(0,2)));
      }
      return const TimeOfDay(hour: 14, minute: 0); 
    } catch (e) { return const TimeOfDay(hour: 14, minute: 0); }
  }

  void _calcular() {
    int adultos = int.tryParse(_adultosCtrl.text) ?? 0;
    int ninos = int.tryParse(_ninosCtrl.text) ?? 0;
    int totalPersonas = adultos + ninos;

    double precioUnitario = _preciosBase[_paqueteSeleccionado] ?? 0;
    if (_fechaSeleccionada.weekday >= 1 && _fechaSeleccionada.weekday <= 3) {
      precioUnitario = precioUnitario * 0.92; 
    }
    setState(() {
      _totalInvitadosCalculado = totalPersonas;
      _totalEstimado = totalPersonas * precioUnitario;
    });
  }

  Future<void> _guardarMision() async {
    if (_clienteCtrl.text.isEmpty) return;

    Map<String, String> itinerarioMap = {
      'inicio': "${_horaInicio.hour.toString().padLeft(2,'0')}:${_horaInicio.minute.toString().padLeft(2,'0')}",
      'comida': "${_horaComida.hour.toString().padLeft(2,'0')}:${_horaComida.minute.toString().padLeft(2,'0')}",
      'pastel': "${_horaPastel.hour.toString().padLeft(2,'0')}:${_horaPastel.minute.toString().padLeft(2,'0')}",
      'fin': "${_horaFin.hour.toString().padLeft(2,'0')}:${_horaFin.minute.toString().padLeft(2,'0')}",
    };

    int adultos = int.tryParse(_adultosCtrl.text) ?? 0;
    int ninos = int.tryParse(_ninosCtrl.text) ?? 0;

    Evento eventoAGuardar = Evento(
      id: widget.eventoEditar?.id ?? '', 
      fecha: _fechaSeleccionada,
      cliente: _clienteCtrl.text,
      telefono: _telefonoCtrl.text,
      cumpleanero: _cumpleaneroCtrl.text,
      paquete: _paqueteSeleccionado,
      // 👇 GUARDAMOS SEPARADO
      adultos: adultos,
      ninos: ninos,
      invitados: adultos + ninos, // Total para fórmulas
      precioTotal: _totalEstimado,
      anticipo: widget.eventoEditar?.anticipo ?? 0,
      estatus: widget.eventoEditar?.estatus ?? 'PENDIENTE',
      saborAguas: _aguasCtrl.text,
      refrescos: _refrescosCtrl.text,
      botana: _botanaSeleccionada,
      pastel: _pastelCtrl.text,
      pinata: _pinataCtrl.text,
      observaciones: _obsCtrl.text,
      itinerario: itinerarioMap,
      staffAsignado: _staffSeleccionado,
      mensajes: widget.eventoEditar?.mensajes ?? [], 
      consumo: widget.eventoEditar?.consumo ?? {},
    );

    if (widget.eventoEditar == null) {
      await _service.crearEvento(eventoAGuardar);
    } else {
      Map<String, dynamic> datosActualizados = eventoAGuardar.toMap();
      datosActualizados.remove('mensajes');
      await _service.actualizarEvento(eventoAGuardar.id, datosActualizados);
    }
    
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventoEditar == null ? "Nueva Misión" : "Editar Misión", style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF00E5FF)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("📋 Datos"),
            _buildInput("Cliente", _clienteCtrl, icon: Icons.person),
            _buildInput("Teléfono", _telefonoCtrl, icon: Icons.phone, isNum: true),
            _buildInput("Cumpleañero", _cumpleaneroCtrl, icon: Icons.cake),
            const SizedBox(height: 10),
            _buildDatePicker(),
            const SizedBox(height: 10),
            
            // 👇 AQUÍ ESTÁ EL CAMBIO DE UI
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _buildInput("Adultos", _adultosCtrl, isNum: true)),
                const SizedBox(width: 10),
                Expanded(child: _buildInput("Niños", _ninosCtrl, isNum: true)),
                const SizedBox(width: 15),
                // Visualizador del Total
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF00FFAA)),
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: Column(
                    children: [
                      const Text("TOTAL", style: TextStyle(color: Color(0xFF00FFAA), fontSize: 10, fontWeight: FontWeight.bold)),
                      Text("$_totalInvitadosCalculado", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ]
            ),
            
            const SizedBox(height: 20),
            _buildStaffSelector(),
            const SizedBox(height: 20),
            _buildSectionTitle("🍱 Suministros"),
            _buildDropdown("Paquete", _paqueteSeleccionado, _preciosBase.keys.toList(), (val) { setState(() => _paqueteSeleccionado = val!); _calcular(); }),
            _buildDropdown("Botana", _botanaSeleccionada, ['Básica', 'Premium', 'No incluye'], (val) => setState(() => _botanaSeleccionada = val!)),
            _buildInput("Aguas", _aguasCtrl),
            _buildInput("Refrescos", _refrescosCtrl),
            _buildInput("Pastel", _pastelCtrl),
            _buildInput("Piñata", _pinataCtrl),
            const SizedBox(height: 20),
            _buildSectionTitle("⏱️ Horarios"),
            _buildTimePicker("Inicio", _horaInicio, (t) => setState(() => _horaInicio = t)),
            _buildTimePicker("Comida", _horaComida, (t) => setState(() => _horaComida = t)),
            _buildTimePicker("Pastel", _horaPastel, (t) => setState(() => _horaPastel = t)),
            _buildTimePicker("Fin", _horaFin, (t) => setState(() => _horaFin = t)),
            const SizedBox(height: 20),
            _buildInput("Observaciones", _obsCtrl, maxLines: 3),
            const SizedBox(height: 30),
            Center(child: Text("Total: \$${_totalEstimado.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFFFFD700), fontSize: 22))),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _guardarMision, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)), child: const Text("GUARDAR CAMBIOS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Widgets auxiliares
  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(title, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 16, fontWeight: FontWeight.bold)));
  Widget _buildInput(String label, TextEditingController ctrl, {bool isNum = false, IconData? icon, int maxLines = 1}) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: ctrl, keyboardType: isNum ? TextInputType.number : TextInputType.text, maxLines: maxLines, onChanged: (_) => _calcular(), style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white54), prefixIcon: icon != null ? Icon(icon, color: Colors.white30) : null, filled: true, fillColor: const Color(0xFF1B2240), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))));
  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: const Color(0xFF1B2240), borderRadius: BorderRadius.circular(10)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.white70)), DropdownButton<String>(value: value, dropdownColor: const Color(0xFF161C36), style: const TextStyle(color: Colors.white), underline: Container(), items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: onChanged)]));
  Widget _buildDatePicker() => InkWell(onTap: () async { final DateTime? picked = await showDatePicker(context: context, initialDate: _fechaSeleccionada, firstDate: DateTime(2020), lastDate: DateTime(2030), builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF00E5FF))), child: child!)); if (picked != null) { setState(() => _fechaSeleccionada = picked); _calcular(); } }, child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: const Color(0xFF1B2240), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white24)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(DateFormat('dd/MM/yyyy').format(_fechaSeleccionada), style: const TextStyle(color: Colors.white)), const Icon(Icons.calendar_today, color: Color(0xFF00E5FF))])));
  Widget _buildTimePicker(String label, TimeOfDay time, Function(TimeOfDay) onTimeChanged) => InkWell(onTap: () async { final TimeOfDay? picked = await showTimePicker(context: context, initialTime: time, builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF00E5FF))), child: child!)); if (picked != null) onTimeChanged(picked); }, child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: const Color(0xFF161C36), borderRadius: BorderRadius.circular(10)), child: Row(children: [Text(label, style: const TextStyle(color: Colors.white70)), const Spacer(), Text(time.format(context), style: const TextStyle(color: Color(0xFF00FFAA), fontWeight: FontWeight.bold))])));
  
  Widget _buildStaffSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle("👩‍🚀 Tripulación Asignada"),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white54),
              tooltip: "Gestionar Nómina",
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GestionStaffScreen())),
            )
          ],
        ),
        StreamBuilder<List<Staff>>(
          stream: _service.obtenerStaff(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LinearProgressIndicator();
            final todosLosEmpleados = snapshot.data!;
            
            return Column(
              children: ['Mesero', 'Nanita', 'Limpieza'].map((rol) {
                final empleadosDelRol = todosLosEmpleados.where((s) => s.rol == rol).toList();
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF1B2240), borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rol.toUpperCase(), style: TextStyle(color: _getColorPorRol(rol), fontWeight: FontWeight.bold, fontSize: 12)),
                      if (empleadosDelRol.isEmpty) 
                        const Padding(padding: EdgeInsets.all(8.0), child: Text("No hay personal registrado", style: TextStyle(color: Colors.white24, fontSize: 10))),
                      
                      Wrap(
                        spacing: 8,
                        children: empleadosDelRol.map((emp) {
                          final isSelected = _staffSeleccionado[rol]?.contains(emp.nombre) ?? false;
                          return FilterChip(
                            label: Text(emp.nombre),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  _staffSeleccionado[rol]?.add(emp.nombre);
                                } else {
                                  _staffSeleccionado[rol]?.remove(emp.nombre);
                                }
                              });
                            },
                            backgroundColor: const Color(0xFF161C36),
                            selectedColor: _getColorPorRol(rol).withOpacity(0.5),
                            labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white60),
                            checkmarkColor: Colors.white,
                          );
                        }).toList(),
                      )
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Color _getColorPorRol(String rol) {
    if (rol == 'Mesero') return const Color(0xFFFFD700);
    if (rol == 'Nanita') return const Color(0xFFE040FB);
    return const Color(0xFF00FFAA); 
  }
}