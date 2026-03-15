import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'salon_panel_ekrani.dart';

class SalonGirisEkrani extends StatefulWidget {
  const SalonGirisEkrani({super.key});

  @override
  State<SalonGirisEkrani> createState() => _SalonGirisEkraniState();
}

class _SalonGirisEkraniState extends State<SalonGirisEkrani> {
  final _emailController = TextEditingController();
  final _sifreController = TextEditingController();
  bool _yukleniyor = false;
  bool _sifreGoster = false;

  Future<void> _girisYap() async {
    final email = _emailController.text.trim();
    final sifre = _sifreController.text.trim();

    if (email.isEmpty || sifre.isEmpty) {
      _uyariGoster("Lütfen e-posta ve şifrenizi girin.");
      return;
    }

    setState(() => _yukleniyor = true);
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: sifre,
      );
      
      if (mounted && credential.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SalonPanelEkrani(ownerEmail: credential.user!.email!)),
        );
      }
    } on FirebaseAuthException catch (e) {
      String mesaj = "E-posta veya şifre hatalı.";
      if (e.code == 'network-request-failed') mesaj = "İnternet bağlantınızı kontrol edin.";
      _uyariGoster(mesaj);
    } catch (e) {
      _uyariGoster("Beklenmedik bir hata oluştu.");
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  void _uyariGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mesaj, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: const Color(0xFFE91E63),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      body: Stack(
        children: [
          // Arka Plan Resmi
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage("https://images.unsplash.com/photo-1512690196248-7374bdb444a1?w=800"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Blur ve Karanlık Katman
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: const Color(0xFF0F111A).withOpacity(0.85)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 35.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  IconButton(
                    icon: const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 40),
                  const Center(
                    child: Column(
                      children: [
                        Icon(Icons.store_rounded, size: 80, color: Color(0xFFE91E63)),
                        SizedBox(height: 20),
                        Text(
                          "Salon Yönetimi",
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "İşletme sahibi girişi",
                          style: TextStyle(color: Colors.white38, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  
                  _inputLabel("E-POSTA ADRESİ"),
                  _buildTextField(
                    controller: _emailController,
                    icon: Icons.email_outlined,
                    hint: "admin@salon.com",
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 25),
                  
                  _inputLabel("ŞİFRE"),
                  _buildTextField(
                    controller: _sifreController,
                    icon: Icons.lock_outline_rounded,
                    hint: "••••••••",
                    obscureText: !_sifreGoster,
                    suffixIcon: IconButton(
                      icon: Icon(_sifreGoster ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white24, size: 20),
                      onPressed: () => setState(() => _sifreGoster = !_sifreGoster),
                    ),
                  ),
                  
                  const SizedBox(height: 50),
                  _yukleniyor 
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)))
                    : SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _girisYap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE91E63),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 10,
                            shadowColor: const Color(0xFFE91E63).withOpacity(0.4),
                          ),
                          child: const Text("GİRİŞ YAP", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          prefixIcon: Icon(icon, color: const Color(0xFFE91E63), size: 22),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        ),
      ),
    );
  }
}
