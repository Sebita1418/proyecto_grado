import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'screens/login/login_screen.dart';
import 'theme/mobility_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  runApp(const TransporteInteligenteApp());
}

class TransporteInteligenteApp extends StatelessWidget {
  const TransporteInteligenteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Transporte Inteligente',
      theme: MobilityTheme.light,
      home: const LoginScreen(),
    );
  }
}
