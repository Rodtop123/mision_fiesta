import 'package:cloud_firestore/cloud_firestore.dart';

class Evento {
  String id;
  DateTime fecha;
  String cliente;
  String telefono; // Nuevo
  String cumpleanero; // Nuevo (Viene del Machote)
  String paquete;
  int invitados;
  double precioTotal;
  double anticipo;
  String estatus; // 'COTIZACION', 'CONFIRMADO', 'FINALIZADO'
  
  // Datos del Machote (Logística)
  String saborAguas;
  String refrescos;
  String botana; // Basica o Premium
  String pastel; // Sabor o "Lo trae cliente"
  String pinata; // Personaje
  String observaciones;
  
  // Itinerario (Horas clave)
  Map<String, String> itinerario; 
  
  Map<String, dynamic> consumo; // Insumos

  Evento({
    required this.id,
    required this.fecha,
    required this.cliente,
    this.telefono = '',
    this.cumpleanero = '',
    required this.paquete,
    required this.invitados,
    required this.precioTotal,
    required this.anticipo,
    required this.estatus,
    this.saborAguas = '',
    this.refrescos = '',
    this.botana = '',
    this.pastel = '',
    this.pinata = '',
    this.observaciones = '',
    this.itinerario = const {},
    this.consumo = const {},
  });

  factory Evento.fromMap(Map<String, dynamic> data, String documentId) {
    return Evento(
      id: documentId,
      fecha: (data['fecha'] as Timestamp).toDate(),
      cliente: data['cliente'] ?? '',
      telefono: data['telefono'] ?? '',
      cumpleanero: data['cumpleanero'] ?? '',
      paquete: data['paquete'] ?? '',
      invitados: data['invitados'] ?? 0,
      precioTotal: (data['precioTotal'] ?? 0).toDouble(),
      anticipo: (data['anticipo'] ?? 0).toDouble(),
      estatus: data['estatus'] ?? 'COTIZACION',
      saborAguas: data['saborAguas'] ?? '',
      refrescos: data['refrescos'] ?? '',
      botana: data['botana'] ?? '',
      pastel: data['pastel'] ?? '',
      pinata: data['pinata'] ?? '',
      observaciones: data['observaciones'] ?? '',
      itinerario: Map<String, String>.from(data['itinerario'] ?? {}),
      consumo: data['consumo'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fecha': fecha,
      'cliente': cliente,
      'telefono': telefono,
      'cumpleanero': cumpleanero,
      'paquete': paquete,
      'invitados': invitados,
      'precioTotal': precioTotal,
      'anticipo': anticipo,
      'estatus': estatus,
      'saborAguas': saborAguas,
      'refrescos': refrescos,
      'botana': botana,
      'pastel': pastel,
      'pinata': pinata,
      'observaciones': observaciones,
      'itinerario': itinerario,
      'consumo': consumo,
    };
  }
}