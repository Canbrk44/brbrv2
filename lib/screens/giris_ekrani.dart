import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import 'ana_sayfa.dart';
import 'sms_onay_ekrani.dart';

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  _GirisEkraniState createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;
  bool _isRegisterMode = false; // Giriş mi Kayıt mı kontrolü

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _modDegistir() {
    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _phoneController.clear();
      _nameController.clear();
    });
  }

  // İşlem Başlat (Giriş veya Kayıt)
  void _islemBaslat() async {
    String phone = _phoneController.text.trim();
    String name = _nameController.text.trim();

    if (phone.length != 11 || !phone.startsWith('0')) {
      _uyariGoster("Lütfen geçerli bir telefon numarası girin.");
      return;
    }

    if (_isRegisterMode && name.isEmpty) {
      _uyariGoster("Lütfen adınızı ve soyadınızı girin.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Önce bu numara sistemde var mı kontrol et
      final user = await _databaseService.kullaniciGetir(phone);
      final bool userExists = user != null;

      if (_isRegisterMode) {
        // KAYIT MODU
        if (userExists) {
          _uyariGoster("Bu telefon numarası zaten kayıtlı. Lütfen giriş yapın.");
          setState(() => _isRegisterMode = false); // Otomatik giriş moduna at
        } else {
          // Yeni kayıt için SMS'e gönder
          _smsEkraninaGit(phone, name, false);
        }
      } else {
        // GİRİŞ MODU
        if (!userExists) {
          _uyariGoster("Bu numara ile kayıtlı bir hesap bulunamadı. Lütfen kayıt olun.");
        } else {
          // Mevcut kullanıcı için SMS'e gönder
          _smsEkraninaGit(phone, user['adSoyad'] ?? "", true);
        }
      }
    } catch (e) {
      _uyariGoster("Bir hata oluştu: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _smsEkraninaGit(String phone, String name, bool isLogin) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SmsOnayEkrani(
          isLogin: true, // Her iki durumda da SMS sonrası oturum açılacak
          userName: name,
          musteriTelefon: phone,
          berberIsmi: "", ustaIsmi: "", tarih: "", saat: "",
        ),
      ),
    );
  }

  void _uyariGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mesaj), backgroundColor: const Color(0xFF4E342E), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Arka Plan
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage("https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=800"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: const Color(0xFF2D1B18).withOpacity(0.85)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  // Logo
                  const Icon(Icons.content_cut_rounded, size: 70, color: Color(0xFFD7CCC8)),
                  const SizedBox(height: 16),
                  const Text(
                    "MyRandevum",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 50),
                  
                  // Form Alanı
                  Text(
                    _isRegisterMode ? "Hemen Kayıt Ol" : "Tekrar Hoş Geldin",
                    style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 30),
                  
                  if (_isRegisterMode) ...[
                    _buildTextField(
                      controller: _nameController,
                      icon: Icons.person_outline,
                      hint: "Adınız Soyadınız",
                    ),
                    const SizedBox(height: 15),
                  ],
                  
                  _buildTextField(
                    controller: _phoneController,
                    icon: Icons.phone_android_outlined,
                    hint: "Telefon Numaranız",
                    keyboardType: TextInputType.phone,
                    formatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : ElevatedButton(
                        onPressed: _islemBaslat,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8D6E63),
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: Text(_isRegisterMode ? "KAYIT OL" : "GİRİŞ YAP", 
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                  
                  const SizedBox(height: 20),
                  
                  // Mod Değiştirme Butonu
                  TextButton(
                    onPressed: _modDegistir,
                    child: Text(
                      _isRegisterMode 
                        ? "Zaten hesabınız var mı? Giriş Yapın" 
                        : "Henüz üye değil misiniz? Kayıt Olun",
                      style: const TextStyle(color: Color(0xFFD7CCC8), fontSize: 15),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnaSayfa(isGuest: true))),
                    child: const Text("Misafir Olarak Devam Et", style: TextStyle(color: Colors.white54)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      inputFormatters: formatters,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFFD7CCC8)),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
      ),
    );
  }
}
