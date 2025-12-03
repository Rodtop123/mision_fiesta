import 'package:cloud_firestore/cloud_firestore.dart';

class Evento {
  String id;
  DateTime fecha;
  String cliente;
  String telefono;
  String cumpleanero;
  String paquete;
  int invitados;
  int adultos;
  int ninos;
  double precioTotal;
  double anticipo;
  String estatus;
  
  String saborAguas;
  String refrescos;
  String botana;
  String pastel;
  String pinata;
  String observaciones;
  Map<String, String> itinerario; 
  Map<String, dynamic> consumo;
  Map<String, List<dynamic>> staffAsignado;
  List<Map<String, dynamic>> mensajes;
  
  // 👇 NUEVO CAMPO: EXTRAS / RECORDATORIOS
  // Estructura: [{'texto': 'Velas', 'costo': 0, 'hecho': false}]
  List<Map<String, dynamic>> extras; 

  Evento({
    required this.id,
    required this.fecha,
    required this.cliente,
    this.telefono = '',
    this.cumpleanero = '',
    required this.paquete,
    this.invitados = 0,
    this.adultos = 0,
    this.ninos = 0,
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
    this.staffAsignado = const {},
    this.mensajes = const [],
    this.extras = const [], // Inicializar vacío
  });

  factory Evento.fromMap(Map<String, dynamic> data, String documentId) {
    return Evento(
      id: documentId,
      fecha: (data['fecha'] as Timestamp).toDate(),
      cliente: data['cliente'] ?? '',
      telefono: data['telefono'] ?? '',
      cumpleanero: data['cumpleanero'] ?? '',
      paquete: data['paquete'] ?? '',
      adultos: data['adultos'] ?? 0,
      ninos: data['ninos'] ?? 0,
      invitados: data['invitados'] ?? 0,
      precioTotal: (data['precioTotal'] ?? 0).toDouble(),
      anticipo: (data['anticipo'] ?? 0).toDouble(),
      estatus: data['estatus'] ?? 'SOLICITUD',
      saborAguas: data['saborAguas'] ?? '',
      refrescos: data['refrescos'] ?? '',
      botana: data['botana'] ?? '',
      pastel: data['pastel'] ?? '',
      pinata: data['pinata'] ?? '',
      observaciones: data['observaciones'] ?? '',
      itinerario: Map<String, String>.from(data['itinerario'] ?? {}),
      consumo: data['consumo'] ?? {},
      staffAsignado: Map<String, List<dynamic>>.from(data['staffAsignado'] ?? {}),
      mensajes: List<Map<String, dynamic>>.from(data['mensajes'] ?? []),
      // 👇 Mapeo del nuevo campo
      extras: List<Map<String, dynamic>>.from(data['extras'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fecha': fecha,
      'cliente': cliente,
      'telefono': telefono,
      'cumpleanero': cumpleanero,
      'paquete': paquete,
      'adultos': adultos,
      'ninos': ninos,
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
      'staffAsignado': staffAsignado,
      'mensajes': mensajes,
      'extras': extras, // Guardar nuevo campo
    };
  }
}