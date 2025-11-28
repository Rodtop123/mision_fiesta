import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/evento_model.dart';
import '../services/firebase_service.dart';
import 'cotizador_screen.dart';
import 'insumos_screen.dart';
import 'detalle_mision_screen.dart';

class CalendarioDespegueScreen extends StatefulWidget {
  const CalendarioDespegueScreen({super.key});

  @override
  _CalendarioDespegueScreenState createState() => _CalendarioDespegueScreenState();
}

class _CalendarioDespegueScreenState extends State<CalendarioDespegueScreen> {
  DateTime _fechaSeleccionada = DateTime.now();
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("MISIÓN FIESTA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            Text("Base de Control", style: TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
           Icon(Icons.rocket, color: Color(0xFFFFD700)),
           SizedBox(width: 20)
        ],
      ),
      body: Column(
        children: [
          // 1. CALENDARIO HORIZONTAL
          _buildCalendario(),

          SizedBox(height: 20),

          // 2. LISTA DE EVENTOS (Desde Firebase)
          Expanded(
            child: StreamBuilder<List<Evento>>(
              stream: _firebaseService.obtenerEventos(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState("Sin datos en el sistema");
                }

                // Filtrar eventos por fecha seleccionada
                final eventosDelDia = snapshot.data!.where((e) => 
                  e.fecha.day == _fechaSeleccionada.day && 
                  e.fecha.month == _fechaSeleccionada.month &&
                  e.fecha.year == _fechaSeleccionada.year
                ).toList();

                if (eventosDelDia.isEmpty) {
                  return _buildEmptyState("Sin misiones este día");
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  itemCount: eventosDelDia.length,
                  itemBuilder: (context, index) {
                    return _buildTarjetaEvento(eventosDelDia[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => NuevaMisionScreen()));
        },
        label: Text("NUEVA MISIÓN", style: TextStyle(fontWeight: FontWeight.bold)),
        icon: Icon(Icons.add),
        backgroundColor: Color(0xFF00E5FF),
      ),
    );
  }

  // WIDGET: Calendario (Aquí es donde se te cortó antes)
  Widget _buildCalendario() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 30, // Próximos 30 días
        itemBuilder: (context, index) {
          DateTime fecha = DateTime.now().add(Duration(days: index));
          bool isSelected = fecha.day == _fechaSeleccionada.day;

          return GestureDetector(
            onTap: () => setState(() => _fechaSeleccionada = fecha),
            child: Container(
              width: 70,
              margin: EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: isSelected ? Color(0xFF00E5FF).withOpacity(0.2) : Color(0xFF1B2240),
                borderRadius: BorderRadius.circular(15),
                border: isSelected ? Border.all(color: Color(0xFF00E5FF)) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('MMM').format(fecha).toUpperCase(), style: TextStyle(color: Colors.white54, fontSize: 10)),
                  Text("${fecha.day}", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // WIDGET: Tarjeta de Evento
  Widget _buildTarjetaEvento(Evento evento) {
    Color colorStatus = evento.estatus == 'CONFIRMADO' ? Color(0xFF00FFAA) : Color(0xFFFFD700);
    
    return GestureDetector(
      onTap: () {
        // 👇 AHORA VAMOS AL DETALLE COMPLETO (MACHOTE)
        Navigator.push(context, MaterialPageRoute(builder: (context) => DetalleMisionScreen(evento: evento)));
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 15),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Color(0xFF161C36),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorStatus.withOpacity(0.5))
        ),
        child: Row(
          children: [
             Column(
               children: [
                 Text(DateFormat('HH:mm').format(evento.fecha), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                 SizedBox(height: 5),
                 Icon(Icons.circle, color: colorStatus, size: 10)
               ],
             ),
             SizedBox(width: 15),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(evento.cliente, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                   Text("Paquete: ${evento.paquete} (${evento.invitados} px)", style: TextStyle(color: Colors.white70, fontSize: 12)),
                 ],
               ),
             ),
             Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 15)
          ],
        ),
      ),
    );
  }

  // WIDGET: Estado Vacío
  Widget _buildEmptyState(String mensaje) {
    return Center(child: Text(mensaje, style: TextStyle(color: Colors.white24)));
  }
}