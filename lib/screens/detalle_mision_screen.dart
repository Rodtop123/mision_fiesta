import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/evento_model.dart';
import '../services/firebase_service.dart';
import 'insumos_screen.dart'; 
import '../services/pdf_generator.dart';
import 'cotizador_screen.dart'; 

class DetalleMisionScreen extends StatefulWidget {
  final Evento evento;
  const DetalleMisionScreen({super.key, required this.evento});

  @override
  _DetalleMisionScreenState createState() => _DetalleMisionScreenState();
}

class _DetalleMisionScreenState extends State<DetalleMisionScreen> {
  final FirebaseService _service = FirebaseService();
  final TextEditingController _chatCtrl = TextEditingController();

  // Controladores para agregar extras
  final TextEditingController _extraNombreCtrl = TextEditingController();
  final TextEditingController _extraCostoCtrl = TextEditingController();

  void _enviarRespuesta() {
    if (_chatCtrl.text.isEmpty) return;
    List<Map<String, dynamic>> nuevosMensajes = List.from(widget.evento.mensajes);
    nuevosMensajes.add({
      'autor': 'admin',
      'texto': _chatCtrl.text,
      'fecha': DateTime.now().toString(),
    });
    FirebaseFirestore.instance.collection('eventos').doc(widget.evento.id).update({'mensajes': nuevosMensajes});
    _chatCtrl.clear();
  }

  // --- LÓGICA DE EXTRAS / RECORDATORIOS ---
  
  void _agregarExtra(double precioActualEvento) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2240),
        title: const Text("Agregar Recordatorio / Cargo", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _extraNombreCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Descripción (Ej. Velas)", labelStyle: TextStyle(color: Colors.white54))),
            const SizedBox(height: 10),
            TextField(controller: _extraCostoCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Costo Extra (Opcional)", labelStyle: TextStyle(color: Colors.white54), prefixText: "\$ ")),
            const SizedBox(height: 5),
            const Text("Si pones costo, se sumará al Total del Cliente.", style: TextStyle(color: Colors.amber, fontSize: 10)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
            child: const Text("AGREGAR", style: TextStyle(color: Colors.black)),
            onPressed: () async {
              if (_extraNombreCtrl.text.isNotEmpty) {
                double costoExtra = double.tryParse(_extraCostoCtrl.text) ?? 0.0;
                
                // 1. Crear el objeto extra
                Map<String, dynamic> nuevoExtra = {
                  'texto': _extraNombreCtrl.text,
                  'costo': costoExtra,
                  'hecho': false,
                };

                // 2. Actualizar en Firebase
                // Usamos arrayUnion para agregar a la lista y increment para sumar el precio atómicamente
                await FirebaseFirestore.instance.collection('eventos').doc(widget.evento.id).update({
                  'extras': FieldValue.arrayUnion([nuevoExtra]),
                  'precioTotal': FieldValue.increment(costoExtra) // Magia: Suma al total existente
                });

                _extraNombreCtrl.clear();
                _extraCostoCtrl.clear();
                Navigator.pop(ctx);
              }
            },
          )
        ],
      )
    );
  }

  void _toggleExtra(List<dynamic> listaActual, int index, double precioBase) async {
    // Para modificar un elemento de un array en Firestore, hay que bajarlo, modificarlo y subirlo todo
    List<Map<String, dynamic>> nuevaLista = List<Map<String, dynamic>>.from(listaActual);
    nuevaLista[index]['hecho'] = !nuevaLista[index]['hecho'];
    
    await FirebaseFirestore.instance.collection('eventos').doc(widget.evento.id).update({
      'extras': nuevaLista
    });
  }

  void _borrarExtra(List<dynamic> listaActual, int index) async {
    List<Map<String, dynamic>> nuevaLista = List<Map<String, dynamic>>.from(listaActual);
    double costoADescontar = (nuevaLista[index]['costo'] as num).toDouble();
    
    nuevaLista.removeAt(index);

    await FirebaseFirestore.instance.collection('eventos').doc(widget.evento.id).update({
      'extras': nuevaLista,
      'precioTotal': FieldValue.increment(-costoADescontar) // Restamos el costo al borrar
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('eventos').doc(widget.evento.id).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(backgroundColor: Color(0xFF0B1026), body: Center(child: CircularProgressIndicator()));
        
        Evento eventoActualizado = Evento.fromMap(snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);
        
        return Scaffold(
          backgroundColor: const Color(0xFF0B1026),
          appBar: AppBar(
            title: const Text("Expediente", style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Color(0xFF00E5FF)),
            actions: [
              IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => NuevaMisionScreen(eventoEditar: eventoActualizado)))),
              IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _confirmarBorrado(context)),
              Container(margin: const EdgeInsets.only(right: 10, left: 5), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFFD700))), child: IconButton(icon: const Icon(Icons.picture_as_pdf, color: Color(0xFFFFD700)), onPressed: () => PdfGenerator.generarYMostrarPDF(eventoActualizado))),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildCardHeader(eventoActualizado),
                const SizedBox(height: 20),
                
                // --- SECCIÓN NUEVA: EXTRAS Y RECORDATORIOS ---
                _buildExtrasSection(eventoActualizado),
                const SizedBox(height: 20),

                // CHAT
                Container(
                  height: 300,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF161C36), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3))),
                  child: Column(
                    children: [
                      const Text("💬 CHAT CON CLIENTE", style: TextStyle(color: Color(0xFF00FFAA), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      const Divider(color: Colors.white10),
                      Expanded(
                        child: eventoActualizado.mensajes.isEmpty 
                          ? const Center(child: Text("Sin mensajes aún", style: TextStyle(color: Colors.white30)))
                          : ListView.builder(
                              reverse: true,
                              itemCount: eventoActualizado.mensajes.length,
                              itemBuilder: (ctx, i) {
                                final msg = eventoActualizado.mensajes[eventoActualizado.mensajes.length - 1 - i];
                                bool esMio = msg['autor'] == 'admin';
                                return Align(
                                  alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: esMio ? const Color(0xFF00E5FF).withOpacity(0.2) : Colors.white10,
                                      borderRadius: BorderRadius.circular(10),
                                      border: esMio ? Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5)) : null
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(msg['texto'], style: const TextStyle(color: Colors.white)),
                                        Text(esMio ? "Tú" : "Cliente", style: const TextStyle(color: Colors.white30, fontSize: 8))
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                      ),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: TextField(controller: _chatCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "Responder...", hintStyle: TextStyle(color: Colors.white30), filled: true, fillColor: Color(0xFF0B1026), contentPadding: EdgeInsets.symmetric(horizontal: 15)))),
                        IconButton(icon: const Icon(Icons.send, color: Color(0xFF00E5FF)), onPressed: _enviarRespuesta)
                      ])
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                _buildInfoBlock("📋 Datos Operativos", [
                  _row("Paquete", eventoActualizado.paquete),
                  _row("Adultos", "${eventoActualizado.adultos}"),
                  _row("Niños", "${eventoActualizado.ninos}"),
                  _row("Total", "${eventoActualizado.invitados}"),
                  const Divider(color: Colors.white24),
                  _row("Aguas", eventoActualizado.saborAguas),
                  _row("Refrescos", eventoActualizado.refrescos),
                  _row("Botana", eventoActualizado.botana),
                  _row("Pastel", eventoActualizado.pastel),
                  _row("Piñata", eventoActualizado.pinata),
                ]),
                const SizedBox(height: 30),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ListaSuministrosScreen(evento: eventoActualizado))),
            backgroundColor: const Color(0xFF00E5FF),
            icon: const Icon(Icons.inventory, color: Colors.black),
            label: const Text("VER BODEGA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        );
      }
    );
  }

  // WIDGET DE EXTRAS (CHECKLIST DINÁMICA)
  Widget _buildExtrasSection(Evento e) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2240),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.withOpacity(0.5))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("🚀 EXTRAS Y RECORDATORIOS", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.amber),
                onPressed: () => _agregarExtra(e.precioTotal),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            ],
          ),
          const SizedBox(height: 10),
          if (e.extras.isEmpty) 
            const Text("No hay extras agregados.", style: TextStyle(color: Colors.white30, fontSize: 12)),
          
          ...e.extras.asMap().entries.map((entry) {
            int idx = entry.key;
            Map<String, dynamic> item = entry.value;
            double costo = (item['costo'] as num).toDouble();
            bool hecho = item['hecho'];

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => _toggleExtra(e.extras, idx, e.precioTotal),
                    child: Icon(hecho ? Icons.check_circle : Icons.circle_outlined, color: hecho ? const Color(0xFF00FFAA) : Colors.white54),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(item['texto'], style: TextStyle(color: hecho ? Colors.white30 : Colors.white, decoration: hecho ? TextDecoration.lineThrough : null)),
                  ),
                  if (costo > 0)
                    Text("+\$${costo.toStringAsFixed(0)}", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () => _borrarExtra(e.extras, idx),
                    child: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                  )
                ],
              ),
            );
          }).toList()
        ],
      ),
    );
  }

  void _confirmarBorrado(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1B2240),
      title: const Text("¿Eliminar?", style: TextStyle(color: Colors.white)),
      actions: [
        TextButton(child: const Text("No"), onPressed: () => Navigator.pop(ctx)),
        TextButton(child: const Text("SÍ", style: TextStyle(color: Colors.red)), onPressed: () {
          _service.borrarEvento(widget.evento.id);
          Navigator.pop(ctx); Navigator.pop(context);
        }),
      ],
    ));
  }

  Widget _buildCardHeader(Evento e) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFF00E5FF).withOpacity(0.2), const Color(0xFF1B2240)]), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF00E5FF))),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.cliente, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), Text(e.telefono, style: const TextStyle(color: Colors.white70))]),
          const CircleAvatar(backgroundColor: Color(0xFF00E5FF), child: Icon(Icons.person, color: Colors.black)),
        ]),
        const SizedBox(height: 15), const Divider(color: Colors.white24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Total a Pagar: \$${e.precioTotal.toStringAsFixed(0)}", style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)), Text(DateFormat('dd/MMM/yyyy').format(e.fecha), style: const TextStyle(color: Colors.white))])
      ]),
    );
  }
  
  Widget _buildInfoBlock(String title, List<Widget> children) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5)), const SizedBox(height: 10), Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF1B2240), borderRadius: BorderRadius.circular(20)), child: Column(children: children))]);
  Widget _row(String k, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Text("$k: ", style: const TextStyle(color: Colors.white54)), Expanded(child: Text(v, style: const TextStyle(color: Colors.white), textAlign: TextAlign.right))]));
}