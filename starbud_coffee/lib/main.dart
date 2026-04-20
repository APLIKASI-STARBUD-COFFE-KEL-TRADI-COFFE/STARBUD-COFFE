import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/login_page.dart';
import 'pages/welcome_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StarBud Coffee',

      themeMode: ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        textTheme: GoogleFonts.poppinsTextTheme(),
        primaryColor: const Color.fromRGBO(78, 52, 46, 1),
        scaffoldBackgroundColor: const Color(0xFFFFF8E1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4E342E),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),

      home: const WelcomePage(),

      routes: {
        '/login': (context) => const LoginPage(),
        '/welcome': (context) => const WelcomePage(), 
      },
    );
  }
}
