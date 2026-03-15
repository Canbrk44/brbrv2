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
  bool _isRegisterMode = false; 

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
      final user = await _databaseService.kullaniciGetir(phone);
      final bool userExists = user != null;

      if (_isRegisterMode) {
        if (userExists) {
          _uyariGoster("Bu telefon numarası zaten kayıtlı. Lütfen giriş yapın.");
          setState(() => _isRegisterMode = false);
        } else {
          _smsEkraninaGit(phone, name, false);
        }
      } else {
        if (!userExists) {
          _uyariGoster("Bu numara ile kayıtlı bir hesap bulunamadı. Lütfen kayıt olun.");
        } else {
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
          isLogin: true, 
          userName: name,
          musteriTelefon: phone,
          berberIsmi: "", ustaIsmi: "", tarih: "", saat: "",
        ),
      ),
    );
  }

  void _uyariGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mesaj), backgroundColor: const Color(0xFFE91E63), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage("https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=800"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: const Color(0xFF0F111A).withOpacity(0.85)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 35.0),
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  
                  // MARKA LOGO TASARIMI
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Arka parlaması
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE91E63).withOpacity(0.3),
                                blurRadius: 40,
                                spreadRadius: 10,
                              )
                            ],
                          ),
                        ),
                        // Ana Logo İkonu (Katmanlı Randevu Tasarımı)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161925),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: const Color(0xFFE91E63).withOpacity(0.5), width: 2),
                          ),
                          child: const Icon(
                            Icons.auto_stories_rounded, // Randevu defteri/ajanda tarzı
                            size: 50, 
                            color: Color(0xFFE91E63),
                          ),
                        ),
                        // Alt Köşedeki Onay/Saat İkonu
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                          ),
                        )
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 25),
                  const Text(
                    "MyRandevum", 
                    style: TextStyle(
                      fontSize: 32, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white, 
                      letterSpacing: 2,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))]
                    )
                  ),
                  const SizedBox(height: 60),
                  
                  Text(
                    _isRegisterMode ? "Hemen Kayıt Ol" : "Tekrar Hoş Geldin",
                    style: const TextStyle(fontSize: 20, color: Colors.white70, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 35),
                  
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
                  
                  const SizedBox(height: 40),
                  
                  _isLoading 
                    ? const CircularProgressIndicator(color: Color(0xFFE91E63))
                    : ElevatedButton(
                        onPressed: _islemBaslat,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 10,
                          shadowColor: const Color(0xFFE91E63).withOpacity(0.4),
                        ),
                        child: Text(_isRegisterMode ? "KAYIT OL" : "GİRİŞ YAP", 
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                  
                  const SizedBox(height: 25),
                  
                  TextButton(
                    onPressed: _modDegistir,
                    child: Text(
                      _isRegisterMode 
                        ? "Zaten hesabınız var mı? Giriş Yapın" 
                        : "Henüz üye değil misiniz? Kayıt Olun",
                      style: const TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnaSayfa(isGuest: true))),
                    child: const Text("Misafir Olarak Devam Et", style: TextStyle(color: Colors.white24, fontSize: 13)),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: keyboardType,
        inputFormatters: formatters,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFFE91E63), size: 22),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }
}
