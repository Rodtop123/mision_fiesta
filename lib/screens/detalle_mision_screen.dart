import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/evento_model.dart';
import 'insumos_screen.dart'; 
import '../services/pdf_generator.dart'; // Importante para el PDF

class DetalleMisionScreen extends StatelessWidget {
  final Evento evento;

  DetalleMisionScreen({required this.evento});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0B1026),
      appBar: AppBar(
        title: Text("Expediente", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Color(0xFF00E5FF)),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 15),
            decoration: BoxDecoration(
              color: Color(0xFF1B2240),
              shape: BoxShape.circle,
              border: Border.all(color: Color(0xFFFFD700).withOpacity(0.5))
            ),
            child: IconButton(
              icon: Icon(Icons.picture_as_pdf, color: Color(0xFFFFD700)),
              tooltip: "Generar Contrato",
              onPressed: () {
                PdfGenerator.generarYMostrarPDF(evento);
              },
            ),
          ),
        ],
      ),
      
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TARJETA PRINCIPAL (CLIENTE)
            _buildCardHeader(),
            
            SizedBox(height: 20),
            
            // TARJETA DE LOGÍSTICA
            Text("📋 Datos Operativos", style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5)),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(color: Color(0xFF1B2240), borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  _buildRowInfo("Paquete", evento.paquete, Icons.rocket),
                  _buildRowInfo("Invitados", "${evento.invitados} Pax", Icons.groups),
                  Divider(color: Colors.white10),
                  _buildRowInfo("Sabor Aguas", evento.saborAguas, Icons.water_drop),
                  _buildRowInfo("Refrescos", evento.refrescos, Icons.local_drink),
                  _buildRowInfo("Botana", evento.botana, Icons.tapas),
                  Divider(color: Colors.white10),
                  _buildRowInfo("Pastel", evento.pastel, Icons.cake),
                  _buildRowInfo("Piñata", evento.pinata, Icons.star),
                ],
              ),
            ),

            SizedBox(height: 20),

            // TARJETA DE ITINERARIO
            Text("⏱️ Cronograma", style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5)),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(color: Color(0xFF161C36), borderRadius: BorderRadius.circular(20), border: Border.all(color: Color(0xFF00E5FF).withOpacity(0.3))),
              child: Column(
                children: [
                  _buildTimeRow("Recepción", evento.itinerario['inicio'] ?? '--'),
                  _buildTimeRow("Comida", evento.itinerario['comida'] ?? '--'),
                  _buildTimeRow("Pastel", evento.itinerario['pastel'] ?? '--'),
                  _buildTimeRow("Fin Misión", evento.itinerario['fin'] ?? '--'),
                ],
              ),
            ),

            SizedBox(height: 20),
            
            // OBSERVACIONES
            if (evento.observaciones.isNotEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.amber.withOpacity(0.5))),
                child: Text("⚠️ NOTA: ${evento.observaciones}", style: TextStyle(color: Colors.amber)),
              ),

            SizedBox(height: 30),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ListaSuministrosScreen(evento: evento)));
        },
        backgroundColor: Color(0xFF00E5FF),
        icon: Icon(Icons.inventory, color: Colors.black),
        label: Text("VER BODEGA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  } // <--- ESTA LLAVE CIERRA EL BUILD

  // --- WIDGETS AUXILIARES ---

  Widget _buildCardHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF00E5FF).withOpacity(0.2), Color(0xFF1B2240)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFF00E5FF)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(evento.cliente, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                Text(evento.telefono, style: TextStyle(color: Colors.white70)),
              ]),
              CircleAvatar(backgroundColor: Color(0xFF00E5FF), child: Icon(Icons.person, color: Colors.black)),
            ],
          ),
          SizedBox(height: 15),
          Divider(color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Cumpleañero: ${evento.cumpleanero}", style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
              Text(DateFormat('dd/MMM/yyyy').format(evento.fecha), style: TextStyle(color: Colors.white)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRowInfo(String label, String val, IconData icon) {
    if (val.isEmpty) return SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white30, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: RichText(text: TextSpan(
              style: TextStyle(color: Colors.white70),
              children: [
                TextSpan(text: "$label: ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white54)),
                TextSpan(text: val, style: TextStyle(color: Colors.white)),
              ],
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(String label, String time) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white54)),
          Text(time, style: TextStyle(color: Color(0xFF00FFAA), fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}