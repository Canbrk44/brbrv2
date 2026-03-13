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

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Arka Plan Resmi (Berber Temalı)
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage("https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=800"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Kahverengi Gradyan ve Blur
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF4E342E).withOpacity(0.4),
                    const Color(0xFF2D1B18).withOpacity(0.95),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  // Logo Alanı
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8D6E63).withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF8D6E63).withOpacity(0.3), width: 2),
                    ),
                    child: const Icon(Icons.content_cut_rounded, size: 60, color: Color(0xFFD7CCC8)),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "MyRandevum",
                    style: TextStyle(
                      fontSize: 40, 
                      fontWeight: FontWeight.w900, 
                      color: Colors.white, 
                      letterSpacing: -1,
                      fontFamily: 'Serif',
                    ),
                  ),
                  const Text(
                    "Asaletin ve Tarzın Adresi",
                    style: TextStyle(color: Color(0xFFD7CCC8), fontSize: 16, letterSpacing: 1),
                  ),
                  const SizedBox(height: 60),
                  // Giriş Formu (Cam Efekti)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _nameController,
                              icon: Icons.person_outline,
                              hint: "Adınız Soyadınız",
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _phoneController,
                              icon: Icons.phone_android_outlined,
                              hint: "05xx xxx xx xx",
                              keyboardType: TextInputType.phone,
                              formatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(11),
                              ],
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8D6E63),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  elevation: 8,
                                  shadowColor: Colors.black.withOpacity(0.5),
                                ),
                                onPressed: _isLoading ? null : _dogrulamaGonder,
                                child: _isLoading 
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text("GİRİŞ YAP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AnaSayfa(isGuest: true)));
                    },
                    child: const Text(
                      "Misafir Olarak Gözat",
                      style: TextStyle(color: Color(0xFFD7CCC8), fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 20),
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
      style: const TextStyle(color: Colors.white, fontSize: 16),
      keyboardType: keyboardType,
      inputFormatters: formatters,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFFD7CCC8), size: 22),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF8D6E63), width: 1.5),
        ),
      ),
    );
  }

  void _dogrulamaGonder() async {
    String phone = _phoneController.text;
    String name = _nameController.text;
    
    if (name.isNotEmpty && phone.length == 11 && phone.startsWith('0')) {
      setState(() => _isLoading = true);
      final mevcutMusteri = await _databaseService.musteriGetir(phone);
      setState(() => _isLoading = false);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SmsOnayEkrani(
            isLogin: true,
            userName: mevcutMusteri != null ? mevcutMusteri['adSoyad'] : name,
            musteriTelefon: phone,
            berberIsmi: "",
            ustaIsmi: "",
            tarih: "",
            saat: "",
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen bilgileri doğru doldurun."),
          backgroundColor: Color(0xFF4E342E),
        )
      );
    }
  }
}
