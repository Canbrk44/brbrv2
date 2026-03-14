import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/giris_ekrani.dart';
import 'screens/ana_sayfa.dart';
import 'screens/salon_panel_ekrani.dart'; // Eklendi
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final String? phone = prefs.getString('user_phone');
  final String? name = prefs.getString('user_name');
  final String? ownerEmail = prefs.getString('owner_email'); // Salon sahibi kontrolü

  _konumIzniIste();

  Widget initialScreen;
  if (ownerEmail != null) {
    // Eğer salon sahibi girişi varsa direkt panele git
    initialScreen = SalonPanelEkrani(ownerEmail: ownerEmail);
  } else if (phone != null && name != null) {
    // Normal kullanıcı girişi
    initialScreen = AnaSayfa(phoneNumber: phone, userName: name, isGuest: false);
  } else {
    // Giriş yapılmamış
    initialScreen = const GirisEkrani();
  }

  runApp(BerberApp(initialScreen: initialScreen));
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
      locale: const Locale('tr', 'TR'),
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF4E342E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4E342E),
          primary: const Color(0xFF4E342E),
          secondary: const Color(0xFF8D6E63),
          surface: Colors.white,
          background: const Color(0xFFF5F7F8),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7F8),
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
