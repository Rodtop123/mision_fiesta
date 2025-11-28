import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/evento_model.dart';

class FirebaseService {
  final CollectionReference eventosRef = FirebaseFirestore.instance.collection('eventos');

  // 1. LEER EVENTOS (Para el Calendario)
  Stream<List<Evento>> obtenerEventos() {
    return eventosRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Evento.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // 2. GUARDAR NUEVA MISIÓN (Desde Cotizador)
  Future<void> crearEvento(Evento evento) {
    return eventosRef.add(evento.toMap());
  }

  // 3. ACTUALIZAR CONSUMO (Desde Bodega o Finanzas)
  Future<void> actualizarEvento(String id, Map<String, dynamic> datos) {
    return eventosRef.doc(id).update(datos);
  }
}