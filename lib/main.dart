import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'screens/giris_ekrani.dart';
import 'screens/ana_sayfa.dart';

void main() async {
  // Uygulama başlatılmadan önce Flutter bileşenlerini hazırla
  WidgetsFlutterBinding.ensureInitialized();
  
  // Kullanıcı bilgilerini güvenli bir şekilde çek
  String? phone;
  String? name;
  
  try {
    final prefs = await SharedPreferences.getInstance();
    phone = prefs.getString('user_phone');
    name = prefs.getString('user_name');
  } catch (e) {
    debugPrint("SharedPreferences hatası: $e");
  }

  // Konum iznini iste ama uygulamanın açılmasını engelleme (Arka planda çalışsın)
  _konumIzniIste();

  runApp(BerberApp(
    initialScreen: (phone != null && name != null) 
      ? AnaSayfa(phoneNumber: phone, userName: name, isGuest: false)
      : const GirisEkrani(),
  ));
}

// Konum izni isteme fonksiyonu (Daha güvenli ve asenkron)
void _konumIzniIste() async {
  try {
    bool servisEtkin = await Geolocator.isLocationServiceEnabled();
    if (!servisEtkin) return;

    LocationPermission izin = await Geolocator.checkPermission();
    if (izin == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  } catch (e) {
    debugPrint("Konum izni istenirken hata oluştu: $e");
  }
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
          titleTextStyle: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
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
