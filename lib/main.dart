import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/giris_ekrani.dart';
import 'screens/ana_sayfa.dart';
import 'screens/salon_panel_ekrani.dart'; 
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
  final String? ownerEmail = prefs.getString('owner_email');

  _konumIzniIste();

  Widget initialScreen;
  if (ownerEmail != null) {
    initialScreen = SalonPanelEkrani(ownerEmail: ownerEmail);
  } else if (phone != null && name != null) {
    initialScreen = AnaSayfa(phoneNumber: phone, userName: name, isGuest: false);
  } else {
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
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0F111A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE91E63),
          brightness: Brightness.dark,
          primary: const Color(0xFFE91E63),
          secondary: const Color(0xFF9C27B0),
          surface: const Color(0xFF161925),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F111A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF161925).withOpacity(0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), 
            side: const BorderSide(color: Colors.white10, width: 0.5)
          ),
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF161925),
          selectedItemColor: Color(0xFFE91E63),
          unselectedItemColor: Colors.white24,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
      ),
      home: initialScreen,
    );
  }
}

// Görseldeki gradyan etkisini veren sihirli widget
class GradientBackground extends StatelessWidget {
  final Widget child;
  final Color accentColor;

  const GradientBackground({super.key, required this.child, this.accentColor = const Color(0xFFE91E63)});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F111A),
        gradient: RadialGradient(
          center: const Alignment(0.8, -0.6), // Sağ üstten hafif parlama
          radius: 1.2,
          colors: [
            accentColor.withOpacity(0.12), // Sekme renginin çok hafif tonu
            const Color(0xFF0F111A),
          ],
        ),
      ),
      child: child,
    );
  }
}
