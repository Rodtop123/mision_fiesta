import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/evento_model.dart';
import '../services/firebase_service.dart';
import '../services/pdf_generator.dart'; 

class CalendarioStaffScreen extends StatefulWidget {
  const CalendarioStaffScreen({super.key});

  @override
  _CalendarioStaffScreenState createState() => _CalendarioStaffScreenState();
}

class _CalendarioStaffScreenState extends State<CalendarioStaffScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.week; 
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final FirebaseService _service = FirebaseService();
  
  List<Evento> _eventosCargados = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1026),
      appBar: AppBar(
        title: const Text("Cuadrante de Turnos", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF00E5FF)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Color(0xFFFFD700)),
            tooltip: "Exportar Cuadrante",
            onPressed: _exportarCuadrantePDF,
          ),
          IconButton(
            icon: Icon(_calendarFormat == CalendarFormat.week ? Icons.calendar_view_month : Icons.calendar_view_week, color: Colors.white),
            onPressed: () {
              setState(() {
                _calendarFormat = _calendarFormat == CalendarFormat.week ? CalendarFormat.month : CalendarFormat.week;
              });
            },
            tooltip: "Cambiar Vista",
          )
        ],
      ),
      body: Column(
        children: [
          _buildCalendar(),
          const SizedBox(height: 10),
          // Indicador de qué periodo estamos viendo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _calendarFormat == CalendarFormat.week ? "Misiones de la Semana" : "Misiones del Mes",
                style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.bold)
              ),
            ),
          ),
          Expanded(child: _buildEventList()),
        ],
      ),
    );
  }

  void _exportarCuadrantePDF() {
    if (_eventosCargados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No hay eventos para exportar")));
      return;
    }

    DateTime inicio, fin;
    bool esMensual = _calendarFormat == CalendarFormat.month;
    
    if (esMensual) {
      inicio = DateTime(_focusedDay.year, _focusedDay.month, 1);
      fin = DateTime(_focusedDay.year, _focusedDay.month + 1, 0, 23, 59, 59);
    } else {
      inicio = _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1));
      inicio = DateTime(inicio.year, inicio.month, inicio.day);
      fin = inicio.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    }

    final eventosAImprimir = _eventosCargados.where((e) {
       return e.fecha.isAfter(inicio.subtract(const Duration(seconds: 1))) && 
              e.fecha.isBefore(fin.add(const Duration(seconds: 1)));
    }).toList();

    if (eventosAImprimir.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No hay eventos en este periodo")));
       return;
    }

    PdfGenerator.generarReporteStaff(eventosAImprimir, _focusedDay, esMensual);
  }

  Widget _buildCalendar() {
    return Container(
      color: const Color(0xFF1B2240),
      child: TableCalendar(
        locale: 'es_ES',
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        startingDayOfWeek: StartingDayOfWeek.monday,
        
        headerStyle: const HeaderStyle(
          titleCentered: true, 
          formatButtonVisible: false, 
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          leftChevronIcon: Icon(Icons.chevron_left, color: Color(0xFF00E5FF)),
          rightChevronIcon: Icon(Icons.chevron_right, color: Color(0xFF00E5FF)),
        ),
        calendarStyle: const CalendarStyle(
          defaultTextStyle: TextStyle(color: Colors.white),
          weekendTextStyle: TextStyle(color: Color(0xFFFFD700)),
          todayDecoration: BoxDecoration(color: Color(0xFF00E5FF), shape: BoxShape.circle),
          selectedDecoration: BoxDecoration(color: Color(0xFFFFD700), shape: BoxShape.circle),
          outsideTextStyle: TextStyle(color: Colors.white24),
        ),
        
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay; // Actualiza la lista al tocar un día también
          });
        },
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay; // ESTO ES CLAVE: Al deslizar, actualiza la lista
          });
        },
      ),
    );
  }

  Widget _buildEventList() {
    return StreamBuilder<List<Evento>>(
      stream: _service.obtenerEventos(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
        
        _eventosCargados = snapshot.data!;
        
        // 1. CALCULAR RANGO VISIBLE (SEMANA O MES)
        DateTime inicio, fin;

        if (_calendarFormat == CalendarFormat.month) {
          // Mes completo
          inicio = DateTime(_focusedDay.year, _focusedDay.month, 1);
          fin = DateTime(_focusedDay.year, _focusedDay.month + 1, 0, 23, 59, 59);
        } else {
          // Semana (Lunes a Domingo)
          inicio = _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1));
          inicio = DateTime(inicio.year, inicio.month, inicio.day); // Reset hora
          fin = inicio.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        }

        // 2. FILTRAR EVENTOS EN ESE RANGO
        final eventosVisibles = _eventosCargados.where((e) {
           return e.fecha.isAfter(inicio.subtract(const Duration(seconds: 1))) && 
                  e.fecha.isBefore(fin.add(const Duration(seconds: 1)));
        }).toList();

        if (eventosVisibles.isEmpty) {
           return Center(
             child: Text(
               _calendarFormat == CalendarFormat.week ? "Sin misiones esta semana" : "Sin misiones este mes", 
               style: const TextStyle(color: Colors.white30)
             )
           );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: eventosVisibles.length,
          itemBuilder: (context, index) {
            final e = eventosVisibles[index];
            final horario = "${e.itinerario['inicio'] ?? '?'} - ${e.itinerario['fin'] ?? '?'}";
            
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF161C36),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3))
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Mostrar Fecha y Cliente
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat('EEEE d', 'es').format(e.fecha).toUpperCase(), style: const TextStyle(color: Color(0xFF00FFAA), fontSize: 10, fontWeight: FontWeight.bold)),
                            Text("Misión: ${e.cliente}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                      Text(horario, style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(color: Colors.white10),
                  _buildStaffList("Meseros", e.staffAsignado['Mesero'], const Color(0xFFFFD700)),
                  _buildStaffList("Nanitas", e.staffAsignado['Nanita'], const Color(0xFFE040FB)),
                  _buildStaffList("Limpieza", e.staffAsignado['Limpieza'], const Color(0xFF00FFAA)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStaffList(String rol, List<dynamic>? nombres, Color color) {
    if (nombres == null || nombres.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 70, child: Text("$rol:", style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold))),
          Expanded(child: Text(nombres.join(", "), style: const TextStyle(color: Colors.white70, fontSize: 12))),
        ],
      ),
    );
  }
}