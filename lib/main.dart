import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/giris_ekrani.dart';
import 'screens/ana_sayfa.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Otomatik giriş kontrolü
  final prefs = await SharedPreferences.getInstance();
  final String? phone = prefs.getString('user_phone');
  final String? name = prefs.getString('user_name');

  runApp(BerberApp(
    initialScreen: (phone != null && name != null) 
      ? AnaSayfa(phoneNumber: phone, userName: name, isGuest: false)
      : GirisEkrani(),
  ));
}

class BerberApp extends StatelessWidget {
  final Widget initialScreen;
  const BerberApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyRandevum',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          primary: const Color(0xFF0F172A),
          secondary: const Color(0xFF38BDF8),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
      ),
      home: initialScreen,
    );
  }
}
