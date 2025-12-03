import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class ConfiguracionPreciosScreen extends StatefulWidget {
  const ConfiguracionPreciosScreen({super.key});

  @override
  _ConfiguracionPreciosScreenState createState() => _ConfiguracionPreciosScreenState();
}

class _ConfiguracionPreciosScreenState extends State<ConfiguracionPreciosScreen> {
  final FirebaseService _service = FirebaseService();
  bool _cargando = true;
  
  // Controladores para Precios y Factores
  final Map<String, TextEditingController> _ctrlPrecios = {};
  final Map<String, TextEditingController> _ctrlFactores = {};

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final precios = await _service.obtenerCatalogoPrecios();
      final factores = await _service.obtenerFactores(); // Necesitas haber agregado esto en el paso anterior

      precios.forEach((nombre, valor) {
        _ctrlPrecios[nombre] = TextEditingController(text: valor.toStringAsFixed(0));
        // Si existe factor para este producto, lo cargamos, si no, 0
        double factor = factores[nombre] ?? 0.0;
        _ctrlFactores[nombre] = TextEditingController(text: factor.toString());
      });

      setState(() => _cargando = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _guardarCambios() async {
    setState(() => _cargando = true);
    
    Map<String, double> preciosGuardar = {};
    Map<String, double> factoresGuardar = {};

    _ctrlPrecios.forEach((nombre, ctrl) {
      preciosGuardar[nombre] = double.tryParse(ctrl.text) ?? 0.0;
      // Guardamos el factor correspondiente
      if (_ctrlFactores.containsKey(nombre)) {
        factoresGuardar[nombre] = double.tryParse(_ctrlFactores[nombre]!.text) ?? 0.0;
      }
    });

    await _service.guardarCatalogoPrecios(preciosGuardar);
    await _service.guardarFactores(factoresGuardar); // Asegúrate de tener esta función en firebase_service

    setState(() => _cargando = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Base de datos actualizada")));
      Navigator.pop(context);
    }
  }

  void _agregarNuevoProducto() {
    TextEditingController nombreCtrl = TextEditingController();
    TextEditingController precioCtrl = TextEditingController();
    TextEditingController factorCtrl = TextEditingController(text: "0"); // Por defecto no se calcula solo

    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2240),
        title: const Text("Nuevo Suministro", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _inputDialog("Nombre (Ej. Cerveza)", nombreCtrl),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _inputDialog("Precio (\$)", precioCtrl, isNum: true)),
                const SizedBox(width: 10),
                Expanded(child: _inputDialog("Factor (x Pers)", factorCtrl, isNum: true)),
              ],
            ),
            const SizedBox(height: 5),
            const Text("Factor: 0.06 = Hielo | 1.1 = Vasos | 0 = Manual", style: TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
            child: const Text("AGREGAR", style: TextStyle(color: Colors.black)),
            onPressed: () {
              if (nombreCtrl.text.isNotEmpty && precioCtrl.text.isNotEmpty) {
                setState(() {
                  String nombre = nombreCtrl.text;
                  _ctrlPrecios[nombre] = TextEditingController(text: precioCtrl.text);
                  _ctrlFactores[nombre] = TextEditingController(text: factorCtrl.text);
                });
                Navigator.pop(ctx);
              }
            }, 
          )
        ],
      )
    );
  }

  void _eliminarItem(String key) {
    setState(() {
      _ctrlPrecios.remove(key);
      _ctrlFactores.remove(key);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Scaffold(backgroundColor: Color(0xFF0B1026), body: Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))));

    // Separamos para visualizar mejor
    final sueldos = _ctrlPrecios.keys.where((k) => k.startsWith('Sueldo')).toList();
    final insumos = _ctrlPrecios.keys.where((k) => !k.startsWith('Sueldo')).toList();
    insumos.sort(); 

    return Scaffold(
      backgroundColor: const Color(0xFF0B1026),
      appBar: AppBar(
        title: const Text("Configuración Maestra", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF00E5FF)),
        actions: [
          IconButton(icon: const Icon(Icons.add_circle, size: 30, color: Color(0xFF00E5FF)), onPressed: _agregarNuevoProducto)
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader("📦 INSUMOS (Precio y Factor)"),
            const Padding(padding: EdgeInsets.only(bottom: 10), child: Text("Factor: Cuánto se usa por invitado automáticamente.", style: TextStyle(color: Colors.white30, fontSize: 10))),
            ...insumos.map((k) => _buildRow(k, isSalary: false)),
            
            const SizedBox(height: 30),
            _sectionHeader("💰 NÓMINA BASE"),
            ...sueldos.map((k) => _buildRow(k, isSalary: true)),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save, color: Colors.black),
                label: const Text("GUARDAR CAMBIOS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                onPressed: _guardarCambios,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FFAA), padding: const EdgeInsets.all(18)),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String key, {required bool isSalary}) {
    return Dismissible(
      key: Key(key),
      direction: DismissDirection.endToStart,
      background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
      onDismissed: (_) => _eliminarItem(key),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSalary ? const Color(0xFF1B2240) : const Color(0xFF161C36),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10)
        ),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text(key, style: TextStyle(color: isSalary ? const Color(0xFFFFD700) : Colors.white, fontSize: 14))),
            // Precio
            const Text("\$ ", style: TextStyle(color: Colors.white30)),
            Expanded(flex: 1, child: _miniInput(_ctrlPrecios[key]!)),
            // Factor (Solo si no es sueldo)
            if (!isSalary) ...[
              const SizedBox(width: 10),
              const Text("x ", style: TextStyle(color: Colors.amber, fontSize: 12)),
              Expanded(flex: 1, child: _miniInput(_ctrlFactores[key]!, color: Colors.amber)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _miniInput(TextEditingController ctrl, {Color color = const Color(0xFF00E5FF)}) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: TextStyle(color: color, fontWeight: FontWeight.bold),
      decoration: const InputDecoration(isDense: true, border: InputBorder.none),
    );
  }

  Widget _inputDialog(String label, TextEditingController ctrl, {bool isNum = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white54), enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24))),
    );
  }

  Widget _sectionHeader(String t) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(t, style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)));
}