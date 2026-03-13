import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import 'ana_sayfa.dart';

class SmsOnayEkrani extends StatefulWidget {
  final bool isLogin;
  final String berberIsmi;
  final String ustaIsmi;
  final String tarih;
  final String saat;
  final String? musteriTelefon;
  final String? userName;
  final String? kisiTuru;

  const SmsOnayEkrani({
    super.key,
    this.isLogin = false,
    required this.berberIsmi,
    required this.ustaIsmi,
    required this.tarih,
    required this.saat,
    this.musteriTelefon,
    this.userName,
    this.kisiTuru,
  });

  @override
  _SmsOnayEkraniState createState() => _SmsOnayEkraniState();
}

class _SmsOnayEkraniState extends State<SmsOnayEkrani> {
  final TextEditingController _codeController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _dogrulaVeKaydet() async {
    if (_codeController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen 4 haneli kodu girin.")));
      return;
    }

    // Gerçek bir SMS doğrulaması simülasyonu için 1234 kodunu kabul edelim (Test amaçlı)
    // if (_codeController.text != "1234") { ... }

    if (widget.isLogin) {
      if (widget.userName != null && widget.musteriTelefon != null) {
        // Kullanıcıyı 'users' koleksiyonuna kaydet (veya güncelle)
        await _dbService.kullaniciKaydet(
          adSoyad: widget.userName!,
          telefon: widget.musteriTelefon!,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_phone', widget.musteriTelefon!);
        await prefs.setString('user_name', widget.userName!);

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => AnaSayfa(isGuest: false, phoneNumber: widget.musteriTelefon, userName: widget.userName)),
          (route) => false,
        );
      }
    } else {
      // Randevu oluşturma işlemi
      await _dbService.randevuOlustur(
        musteriTelefon: widget.musteriTelefon ?? "Misafir",
        musteriAd: widget.userName ?? "Misafir",
        berberIsmi: widget.berberIsmi,
        ustaIsmi: widget.ustaIsmi,
        tarih: widget.tarih,
        saat: widget.saat,
        kisiTuru: widget.kisiTuru ?? "Yetişkin",
      );

      if (!mounted) return;
      _basariliDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Doğrulama")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security_rounded, size: 80, color: Color(0xFF4E342E)),
            const SizedBox(height: 20),
            Text(
              widget.isLogin ? "Giriş Doğrulaması" : "Randevu Onayı",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "${widget.musteriTelefon} numarasına gönderilen onay kodunu girin.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 10),
              decoration: InputDecoration(
                hintText: "0000", 
                hintStyle: TextStyle(color: Colors.grey[300], letterSpacing: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _dogrulaVeKaydet,
              child: Text(widget.isLogin ? "DOĞRULA VE GİRİŞ YAP" : "ONAYLA VE RANDEVU AL"),
            ),
          ],
        ),
      ),
    );
  }

  void _basariliDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text("İşlem Başarılı!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("İşleminiz başarıyla tamamlandı.", textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => AnaSayfa(initialIndex: 2, phoneNumber: widget.musteriTelefon, userName: widget.userName, isGuest: widget.musteriTelefon == null)),
                  (route) => false,
                );
              },
              child: const Text("Tamam"),
            )
          ],
        ),
      ),
    );
  }
}
