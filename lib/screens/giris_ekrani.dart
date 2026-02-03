import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage("https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.3), const Color(0xFF0F172A).withOpacity(0.8)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(Icons.content_cut_rounded, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "MyRandevum",
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1),
                  ),
                  const Text(
                    "Modern ve Hızlı Randevu Deneyimi",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 60),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _nameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.person_outline, color: Colors.white70),
                                hintText: "Adınız Soyadınız",
                                hintStyle: TextStyle(color: Colors.white54),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: Colors.white),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(11),
                              ],
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.phone_outlined, color: Colors.white70),
                                hintText: "05xx xxx xx xx",
                                hintStyle: TextStyle(color: Colors.white54),
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF38BDF8),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _isLoading ? null : _dogrulamaGonder,
                                child: _isLoading 
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text("GİRİŞ YAP / KAYIT OL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AnaSayfa(isGuest: true)));
                    },
                    child: const Text("Üye olmadan devam et", style: TextStyle(color: Colors.white70, decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _dogrulamaGonder() async {
    String phone = _phoneController.text;
    String name = _nameController.text;
    
    if (name.isNotEmpty && phone.length == 11 && phone.startsWith('0')) {
      setState(() => _isLoading = true);
      
      // Müşteri daha önce kayıtlı mı kontrol et
      final mevcutMusteri = await _databaseService.musteriGetir(phone);
      
      setState(() => _isLoading = false);

      if (!mounted) return;

      // SMS Onay ekranına yönlendir (Giriş/Kayıt modunda)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SmsOnayEkrani(
            isLogin: true, // Giriş/Kayıt modu
            userName: mevcutMusteri != null ? mevcutMusteri['adSoyad'] : name,
            musteriTelefon: phone,
            // Diğer parametreler giriş modunda boş kalacak
            berberIsmi: "",
            ustaIsmi: "",
            tarih: "",
            saat: "",
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen bilgileri eksiksiz ve doğru doldurun.")));
    }
  }
}
