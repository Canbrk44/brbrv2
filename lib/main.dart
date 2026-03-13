import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/date_symbol_data_local.dart'; // Yerelleştirme için eklendi
import 'screens/giris_ekrani.dart';
import 'screens/ana_sayfa.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Türkçe tarih formatlarını hazırlıyoruz
  await initializeDateFormatting('tr_TR', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final String? phone = prefs.getString('user_phone');
  final String? name = prefs.getString('user_name');

  _konumIzniIste();

  runApp(BerberApp(
    initialScreen: (phone != null && name != null)
        ? AnaSayfa(phoneNumber: phone, userName: name, isGuest: false)
        : const GirisEkrani(),
  ));
}

void _konumIzniIste() async {
  try {
    bool servisEtkin = await Geolocator.isLocationServiceEnabled();
    if (!servisEtkin) return;

    LocationPermission izin = await Geolocator.checkPermission();
    if (izin == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  } catch (e) {
    debugPrint("Konum hatası: $e");
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
      // Uygulamanın varsayılan dilini Türkçe yapalım
      locale: const Locale('tr', 'TR'),
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF4E342E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4E342E),
          primary: const Color(0xFF4E342E),
          secondary: const Color(0xFF8D6E63),
          surface: Colors.white,
          background: const Color(0xFFFDF5E6),
        ),
        scaffoldBackgroundColor: const Color(0xFFFDF5E6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF4E342E),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(color: Color(0xFF4E342E), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4E342E),
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
