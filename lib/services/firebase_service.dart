import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/evento_model.dart';
import '../models/staff_model.dart';

class FirebaseService {
  final CollectionReference eventosRef = FirebaseFirestore.instance.collection('eventos');
  final CollectionReference staffRef = FirebaseFirestore.instance.collection('staff');
  final DocumentReference preciosRef = FirebaseFirestore.instance.collection('configuracion').doc('lista_precios');

  // --- EVENTOS ---
  Stream<List<Evento>> obtenerEventos() {
    return eventosRef.orderBy('fecha').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Evento.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Stream<List<Evento>> obtenerEventosFinalizados() {
    return eventosRef
        .where('estatus', isEqualTo: 'FINALIZADO')
        .orderBy('fecha')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Evento.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> crearEvento(Evento evento) {
    return eventosRef.add(evento.toMap());
  }

  Future<void> actualizarEvento(String id, Map<String, dynamic> datos) {
    return eventosRef.doc(id).update(datos);
  }
  
  Future<void> editarEventoCompleto(Evento evento) {
    return eventosRef.doc(evento.id).update(evento.toMap());
  }

  Future<void> borrarEvento(String id) {
    return eventosRef.doc(id).delete();
  }

  // --- STAFF ---
  Stream<List<Staff>> obtenerStaff() {
    return staffRef.orderBy('nombre').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Staff.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> agregarStaff(Staff staff) {
    return staffRef.add(staff.toMap());
  }

  Future<void> borrarStaff(String id) {
    return staffRef.doc(id).delete();
  }

  // --- PRECIOS Y CONFIGURACIÓN (NUEVO) ---
  Future<Map<String, double>> obtenerCatalogoPrecios() async {
    try {
      DocumentSnapshot doc = await preciosRef.get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Convertir valores a double de forma segura
        return data.map((key, value) => MapEntry(key, (value as num).toDouble()));
      } else {
        // SI NO EXISTEN: Subimos los precios base por primera vez
        Map<String, double> preciosBase = {
          'Bolsas de Hielo': 25.0,
          'Refrescos 2L': 38.0,
          'Garrafones Agua': 15.0,
          'Vasos (Paq)': 45.0,
          'Platos (Paq)': 35.0,
          'Tenedores (Paq)': 20.0,
          'Servilletas (Paq)': 15.0,
          'Piñata': 250.0,
          'Bolsas Dulces': 35.0,
          'Extra Limpieza': 100.0,
          'Sueldo Mesero': 350.0,
          'Sueldo Nanita': 300.0,
          'Sueldo Limpieza': 250.0,
        };
        await preciosRef.set(preciosBase);
        return preciosBase;
      }
    } catch (e) {
      print("Error obteniendo precios: $e");
      return {};
    }
  }

  Future<void> guardarCatalogoPrecios(Map<String, double> precios) async {
    try {
      await preciosRef.set(precios);
    } catch (e) {
      print("Error guardando precios: $e");
      rethrow;
    }
  }
  // --- FACTORES DE CONSUMO (FÓRMULAS) ---
  final DocumentReference factoresRef = FirebaseFirestore.instance.collection('configuracion').doc('factores_consumo');

  Future<Map<String, double>> obtenerFactores() async {
    try {
      DocumentSnapshot doc = await factoresRef.get();
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data.map((key, value) => MapEntry(key, (value as num).toDouble()));
      } else {
        // Valores por defecto si no existen
        Map<String, double> defaultFactores = {
          'factor_hielo': 0.06,
          'factor_refresco': 0.05,
          'factor_dulces': 0.60,
          'factor_vasos': 1.1,
        };
        await factoresRef.set(defaultFactores);
        return defaultFactores;
      }
    } catch (e) {
      print("Error factores: $e");
      return {};
    }
  }

  Future<void> guardarFactores(Map<String, double> factores) async {
    await factoresRef.set(factores);
  }
}