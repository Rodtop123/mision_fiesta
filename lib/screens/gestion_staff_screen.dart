import 'package:flutter/material.dart';
import '../models/staff_model.dart';
import '../services/firebase_service.dart';

class GestionStaffScreen extends StatefulWidget {
  const GestionStaffScreen({super.key});

  @override
  _GestionStaffScreenState createState() => _GestionStaffScreenState();
}

class _GestionStaffScreenState extends State<GestionStaffScreen> {
  final FirebaseService _service = FirebaseService();
  final TextEditingController _nombreCtrl = TextEditingController();
  String _rolSeleccionado = 'Mesero';

  void _agregarEmpleado() {
    if (_nombreCtrl.text.isEmpty) return;
    
    final nuevo = Staff(id: '', nombre: _nombreCtrl.text, rol: _rolSeleccionado);
    _service.agregarStaff(nuevo);
    _nombreCtrl.clear();
    Navigator.pop(context); // Cerrar dialogo
  }

  void _mostrarDialogoAgregar() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2240),
        title: const Text("Reclutar Tripulante", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nombreCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Nombre", labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24))
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              initialValue: _rolSeleccionado,
              dropdownColor: const Color(0xFF161C36),
              style: const TextStyle(color: Colors.white),
              items: ['Mesero', 'Nanita', 'Limpieza'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (val) => setState(() => _rolSeleccionado = val!),
              decoration: const InputDecoration(labelText: "Rol", labelStyle: TextStyle(color: Colors.white54)),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(onPressed: _agregarEmpleado, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)), child: const Text("AGREGAR", style: TextStyle(color: Colors.black))),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1026),
      appBar: AppBar(
        title: const Text("Tripulación (Nómina)", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF00E5FF)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoAgregar,
        backgroundColor: const Color(0xFF00E5FF),
        child: const Icon(Icons.person_add, color: Colors.black),
      ),
      body: StreamBuilder<List<Staff>>(
        stream: _service.obtenerStaff(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final staff = snapshot.data!;
          
          if (staff.isEmpty) return const Center(child: Text("No hay personal registrado", style: TextStyle(color: Colors.white30)));

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: staff.length,
            itemBuilder: (context, index) {
              final empleado = staff[index];
              return Card(
                color: const Color(0xFF161C36),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getColorPorRol(empleado.rol),
                    child: Icon(_getIconPorRol(empleado.rol), color: Colors.black, size: 20),
                  ),
                  title: Text(empleado.nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(empleado.rol, style: const TextStyle(color: Colors.white54)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _service.borrarStaff(empleado.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getColorPorRol(String rol) {
    if (rol == 'Mesero') return const Color(0xFFFFD700);
    if (rol == 'Nanita') return const Color(0xFFE040FB);
    return const Color(0xFF00FFAA); // Limpieza
  }
  
  IconData _getIconPorRol(String rol) {
    if (rol == 'Mesero') return Icons.restaurant;
    if (rol == 'Nanita') return Icons.child_care;
    return Icons.cleaning_services;
  }
}