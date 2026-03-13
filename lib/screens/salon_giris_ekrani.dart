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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen e-posta ve şifrenizi girin.")),
      );
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
      String mesaj = "Bir hata oluştu. Lütfen tekrar deneyin.";
      
      // FIREBASE HATA KODLARINI TÜRKÇELEŞTİRME
      switch (e.code) {
        case 'user-not-found':
          mesaj = "Bu e-posta adresi ile kayıtlı bir kullanıcı bulunamadı.";
          break;
        case 'wrong-password':
          mesaj = "Girdiğiniz şifre hatalı. Lütfen kontrol edin.";
          break;
        case 'invalid-email':
          mesaj = "Lütfen geçerli bir e-posta adresi girin.";
          break;
        case 'user-disabled':
          mesaj = "Bu hesap dondurulmuştur. Lütfen destek ile iletişime geçin.";
          break;
        case 'too-many-requests':
          mesaj = "Çok fazla hatalı deneme yaptınız. Lütfen bir süre bekleyin.";
          break;
        case 'network-request-failed':
          mesaj = "İnternet bağlantınızı kontrol edin.";
          break;
        case 'invalid-credential':
          mesaj = "E-posta veya şifre hatalı.";
          break;
        default:
          mesaj = "Giriş yapılamadı: Bilgilerinizi kontrol edin.";
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(mesaj, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF4E342E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Beklenmedik bir hata oluştu.")));
      }
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage("https://images.unsplash.com/photo-1512690196248-7374bdb444a1?w=800"),
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
                  colors: [
                    const Color(0xFF4E342E).withOpacity(0.6),
                    const Color(0xFF2D1B18).withOpacity(0.98),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 40),
                  const Center(
                    child: Column(
                      children: [
                        Icon(Icons.store_rounded, size: 80, color: Color(0xFFD7CCC8)),
                        SizedBox(height: 20),
                        Text(
                          "Salon Yönetimi",
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          "Yönetici girişi yaparak salonunuzu yönetin",
                          style: TextStyle(color: Color(0xFFD7CCC8), fontSize: 14),
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
                  const SizedBox(height: 24),
                  
                  _inputLabel("ŞİFRE"),
                  _buildTextField(
                    controller: _sifreController,
                    icon: Icons.lock_outline_rounded,
                    hint: "••••••••",
                    obscureText: !_sifreGoster,
                    suffixIcon: IconButton(
                      icon: Icon(_sifreGoster ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white70, size: 20),
                      onPressed: () => setState(() => _sifreGoster = !_sifreGoster),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  _yukleniyor 
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF8D6E63)))
                    : SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _girisYap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8D6E63),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 10,
                          ),
                          child: const Text("GİRİŞ YAP", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD7CCC8), letterSpacing: 1.5),
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
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30),
        prefixIcon: Icon(icon, color: const Color(0xFFD7CCC8), size: 22),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF8D6E63), width: 2),
        ),
      ),
    );
  }
}
