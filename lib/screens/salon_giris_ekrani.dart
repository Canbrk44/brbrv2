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
        const SnackBar(content: Text("Lütfen e-posta ve şifre alanlarını doldurun.")),
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
      String mesaj = "Bir hata oluştu: ${e.message}";
      if (e.code == 'user-not-found') mesaj = "Kullanıcı bulunamadı.";
      else if (e.code == 'wrong-password') mesaj = "Hatalı şifre.";
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(mesaj),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.store_rounded, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 32),
              const Text(
                "Salon Paneli",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const Text(
                "Yönetici hesabınızla giriş yapın",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              
              // E-posta Alanı
              _inputLabel("E-POSTA ADRESİ"),
              TextField(
                controller: _emailController,
                decoration: _inputDecoration(Icons.email_outlined, "ornek@salon.com"),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              
              // Şifre Alanı
              _inputLabel("ŞİFRE"),
              TextField(
                controller: _sifreController,
                obscureText: !_sifreGoster,
                decoration: _inputDecoration(
                  Icons.lock_outline_rounded, 
                  "••••••••",
                  suffixIcon: IconButton(
                    icon: Icon(_sifreGoster ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                    onPressed: () => setState(() => _sifreGoster = !_sifreGoster),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text("Şifremi Unuttum", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 32),
              
              _yukleniyor 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)))
                : ElevatedButton(
                    onPressed: _girisYap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                    ),
                    child: const Text("GİRİŞ YAP", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
              const SizedBox(height: 40),
              const Center(
                child: Text(
                  "Henüz bir salonunuz yok mu? Bize ulaşın.",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: 1),
      ),
    );
  }

  InputDecoration _inputDecoration(IconData icon, String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF0F172A), size: 22),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
      ),
    );
  }
}
