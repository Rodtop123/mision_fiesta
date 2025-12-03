import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/evento_model.dart';
import '../services/firebase_service.dart';
import 'cotizador_screen.dart';
import 'detalle_mision_screen.dart';
// Imports de las otras secciones
import 'reporte_utilidad_screen.dart';
import 'calendario_staff_screen.dart';
import 'configuracion_precios_screen.dart';
import 'reporte_compras_screen.dart'; // El Carrito

class CalendarioDespegueScreen extends StatefulWidget {
  const CalendarioDespegueScreen({super.key});

  @override
  _CalendarioDespegueScreenState createState() => _CalendarioDespegueScreenState();
}

class _CalendarioDespegueScreenState extends State<CalendarioDespegueScreen> {
  int _indiceActual = 0; // Controla qué pestaña se ve (0, 1, 2)

  // Lista de las 3 pantallas principales
  final List<Widget> _pantallas = [
    const _HomeTab(),              // 0: Inicio (Calendario eventos)
    const CalendarioStaffScreen(), // 1: Tripulación
    const ReporteUtilidadScreen(), // 2: Finanzas
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1026),
      
      // EL CUERPO CAMBIA SEGÚN LA PESTAÑA
      body: _pantallas[_indiceActual],

      // BARRA DE NAVEGACIÓN INFERIOR
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: const Color(0xFF00E5FF).withOpacity(0.2),
          labelTextStyle: MaterialStateProperty.all(const TextStyle(color: Colors.white, fontSize: 12)),
          iconTheme: MaterialStateProperty.all(const IconThemeData(color: Colors.white)),
        ),
        child: NavigationBar(
          height: 70,
          backgroundColor: const Color(0xFF1B2240),
          selectedIndex: _indiceActual,
          onDestinationSelected: (index) => setState(() => _indiceActual = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.rocket_launch),
              selectedIcon: Icon(Icons.rocket_launch, color: Color(0xFF00E5FF)),
              label: 'Misiones',
            ),
            NavigationDestination(
              icon: Icon(Icons.badge),
              selectedIcon: Icon(Icons.badge, color: Color(0xFF00E5FF)),
              label: 'Tripulación',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_graph),
              selectedIcon: Icon(Icons.auto_graph, color: Color(0xFF00E5FF)),
              label: 'Finanzas',
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================
// PESTAÑA 1: HOME (CALENDARIO Y LISTA DE MISIONES)
// ==============================================================
// Hemos movido toda la lógica vieja aquí adentro para aislarla.

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  DateTime _diaSeleccionado = DateTime.now();
  DateTime _diaEnFoco = DateTime.now();
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1026),
      // APP BAR (Solo visible en esta pestaña)
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("MISIÓN FIESTA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            Text("Base de Control", style: TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
           // BOTÓN 1: CARRITO DE COMPRAS 🛒
           IconButton(
             icon: const Icon(Icons.shopping_cart, color: Colors.white),
             tooltip: "Lista de Compras Semanal",
             onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const ReporteComprasScreen()));
             },
           ),
           // BOTÓN 2: CONFIGURACIÓN MAESTRA ⚙️
           IconButton(
             icon: const Icon(Icons.settings, color: Color(0xFFFFD700)), // Dorado
             tooltip: "Configuración Maestra",
             onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const ConfiguracionPreciosScreen()));
             },
           ),
           const SizedBox(width: 10),
        ],
      ),
      
      // BOTÓN FLOTANTE (Nueva Misión)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NuevaMisionScreen())),
        label: const Text("NUEVA MISIÓN", style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF00E5FF),
      ),

      body: Column(
        children: [
          // CALENDARIO
          _buildTableCalendar(),

          const SizedBox(height: 10),
          const Divider(color: Colors.white10),

          // LISTA DE EVENTOS
          Expanded(
            child: StreamBuilder<List<Evento>>(
              stream: _firebaseService.obtenerEventos(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState("Sin datos en el sistema");
                }

                final inicioSemana = _diaEnFoco.subtract(Duration(days: _diaEnFoco.weekday - 1));
                final finSemana = inicioSemana.add(const Duration(days: 6));
                final start = DateTime(inicioSemana.year, inicioSemana.month, inicioSemana.day);
                final end = DateTime(finSemana.year, finSemana.month, finSemana.day, 23, 59, 59);

                final eventosDeLaSemana = snapshot.data!.where((e) => 
                  e.fecha.isAfter(start.subtract(const Duration(seconds: 1))) && 
                  e.fecha.isBefore(end.add(const Duration(seconds: 1)))
                ).toList();

                if (eventosDeLaSemana.isEmpty) {
                  return _buildEmptyState("Sin misiones esta semana");
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 80), // Espacio abajo para el botón flotante
                  itemCount: eventosDeLaSemana.length,
                  itemBuilder: (context, index) {
                    return _buildTarjetaEvento(eventosDeLaSemana[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCalendar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2240),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10)
      ),
      child: TableCalendar(
        locale: 'es_ES',
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _diaEnFoco,
        calendarFormat: CalendarFormat.week,
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          leftChevronIcon: Icon(Icons.chevron_left, color: Color(0xFF00E5FF)),
          rightChevronIcon: Icon(Icons.chevron_right, color: Color(0xFF00E5FF)),
        ),
        calendarStyle: const CalendarStyle(
          defaultTextStyle: TextStyle(color: Colors.white),
          weekendTextStyle: TextStyle(color: Color(0xFFFFD700)),
          todayDecoration: BoxDecoration(color: Color(0xFF00E5FF), shape: BoxShape.circle),
          selectedDecoration: BoxDecoration(color: Color(0xFFFFD700), shape: BoxShape.circle),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: Colors.white54),
          weekendStyle: TextStyle(color: Colors.white54),
        ),
        selectedDayPredicate: (day) => isSameDay(_diaSeleccionado, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _diaSeleccionado = selectedDay;
            _diaEnFoco = focusedDay;
          });
        },
        onPageChanged: (focusedDay) => setState(() => _diaEnFoco = focusedDay),
      ),
    );
  }

  Widget _buildTarjetaEvento(Evento evento) {
    Color colorStatus;
    switch (evento.estatus) {
      case 'FINALIZADO': colorStatus = const Color(0xFF00FFAA); break;
      case 'CONFIRMADO': colorStatus = const Color(0xFF00E5FF); break;
      default: colorStatus = const Color(0xFFFFD700);
    }

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetalleMisionScreen(evento: evento))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF161C36),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorStatus.withOpacity(0.5))
        ),
        child: Row(
          children: [
             Container(
               padding: const EdgeInsets.all(10),
               decoration: BoxDecoration(color: colorStatus.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
               child: Column(
                 children: [
                   Text(DateFormat('d').format(evento.fecha), style: TextStyle(color: colorStatus, fontWeight: FontWeight.bold, fontSize: 20)),
                   Text(DateFormat('MMM').format(evento.fecha).toUpperCase(), style: TextStyle(color: colorStatus, fontSize: 10)),
                 ],
               ),
             ),
             const SizedBox(width: 15),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(evento.cliente, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                   const SizedBox(height: 4),
                   Row(
                     children: [
                       const Icon(Icons.access_time, size: 12, color: Colors.white54),
                       const SizedBox(width: 4),
                       Text(DateFormat('HH:mm').format(evento.fecha), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                       const SizedBox(width: 10),
                       const Icon(Icons.rocket_launch, size: 12, color: Colors.white54),
                       const SizedBox(width: 4),
                       Text(evento.paquete, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                     ],
                   )
                 ],
               ),
             ),
             const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 15)
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String mensaje) {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.radar, color: Colors.white10, size: 60),
        const SizedBox(height: 10),
        Text(mensaje, style: const TextStyle(color: Colors.white24)),
      ],
    ));
  }
}