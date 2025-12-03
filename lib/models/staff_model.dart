class Staff {
  String id;
  String nombre;
  String rol; // 'Mesero', 'Nanita', 'Limpieza'

  Staff({required this.id, required this.nombre, required this.rol});

  Map<String, dynamic> toMap() {
    return {'nombre': nombre, 'rol': rol};
  }

  factory Staff.fromMap(Map<String, dynamic> data, String id) {
    return Staff(
      id: id,
      nombre: data['nombre'] ?? '',
      rol: data['rol'] ?? 'Mesero',
    );
  }
}