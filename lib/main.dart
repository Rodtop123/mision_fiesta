import 'package:flutter/foundation.dart'; // 👈 ESTA ES LA CLAVE PARA WEB
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/calendario_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);

  try {
    // 🔍 LÓGICA INTELIGENTE DE PLATAFORMA
    // Si es WEB o es WINDOWS, usamos la configuración manual
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          // Busca "current_key" en el json
          apiKey: "AIzaSyAEs9ceRZ1AO-ct3uByglWiV1f543MGB8g", 
          
          // Busca "mobilesdk_app_id" en el json
          appId: "1:632660716164:android:c506279cbe22ed2906b0d1", 
          
          // Busca "project_number" en el json (o pon cualquiera si no usas notificaciones)
          messagingSenderId: "632660716164", 
          
          // Busca "project_id" en el json
          projectId: "misionfiesta-22d46", 
          
          // Opcional: Tu ID de proyecto + .appspot.com
          storageBucket: "mision-fiesta.appspot.com", 
        ),
      );
      
    } else {
      // 📱 ANDROID / IOS (Configuración automática)
      await Firebase.initializeApp();
    }
  } catch (e) {
    print("⚠️ Error iniciando Firebase: $e");
  }

  runApp(const MisionFiestaApp());
}

class MisionFiestaApp extends StatelessWidget {
  const MisionFiestaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Misión Fiesta',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0B1026), 
        primaryColor: const Color(0xFF1B2240),
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF), 
          secondary: Color(0xFFFFD700), 
          surface: Color(0xFF161C36), 
          error: Colors.redAccent,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1B2240),
          labelStyle: const TextStyle(color: Colors.white54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF00E5FF)),
          ),
        ),
      ),
      home: const CalendarioDespegueScreen(), 
    );
  }
}