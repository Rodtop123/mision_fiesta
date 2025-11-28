import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/calendario_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); 
  await initializeDateFormatting('es', null);
  runApp(MisionFiestaApp());
}

class MisionFiestaApp extends StatelessWidget {
  const MisionFiestaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Misión Fiesta',
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFF0B1026),
        primaryColor: Color(0xFF1B2240),
        useMaterial3: true,
      ),
      // Tu pantalla inicial es el Calendario
      home: CalendarioDespegueScreen(), 
    );
  }
}