import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import 'giris_ekrani.dart';
import 'profil_duzenle_ekrani.dart'; // DOĞRU DOSYA İSMİ

class ProfilEkrani extends StatefulWidget {
  final bool isGuest;
  final String? phoneNumber;
  final String? userName;

  const ProfilEkrani({super.key, this.isGuest = false, this.phoneNumber, this.userName});

  @override
  State<ProfilEkrani> createState() => _ProfilEkraniState();
}

class _ProfilEkraniState extends State<ProfilEkrani> {
  final DatabaseService _db = DatabaseService();
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _user;
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    if (!widget.isGuest) _kullaniciYukle();
    else setState(() => _yukleniyor = false);
  }

  Future<void> _kullaniciYukle() async {
    final data = await _db.kullaniciGetir(widget.phoneNumber!);
    if (mounted) setState(() { _user = data; _yukleniyor = false; });
  }

  Future<void> _resimDegistir() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      String? url = await _db.profilResmiYukle(File(image.path), widget.phoneNumber!);
      if (url != null) _kullaniciYukle();
    }
  }

  Future<void> _cikisYap() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const GirisEkrani()), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_yukleniyor) return const Center(child: CircularProgressIndicator(color: Color(0xFFFF9800)));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Profilim", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            _profilKarti(),
            const SizedBox(height: 30),
            _ayarlarBolumu(),
            const SizedBox(height: 40),
            _cikisButonu(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _profilKarti() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161925),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white.withOpacity(0.05),
                backgroundImage: _user?['profilResmi'] != null && _user?['profilResmi'].isNotEmpty 
                  ? NetworkImage(_user!['profilResmi']) 
                  : const NetworkImage("https://i.pravatar.cc/300"),
              ),
              if (!widget.isGuest)
                GestureDetector(
                  onTap: _resimDegistir,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Color(0xFFFF9800), shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(widget.userName ?? "Misafir Kullanıcı", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(widget.phoneNumber ?? "Giriş yapılmadı", style: const TextStyle(color: Colors.white38, fontSize: 13)),
          if (!widget.isGuest) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, color: Colors.green, size: 14),
                  SizedBox(width: 6),
                  const Text("Onaylı Üye", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _ayarlarBolumu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("AYARLAR", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 15),
        _ayarSatiri("Kişisel Bilgiler", Icons.person_outline, () async {
          if (widget.isGuest) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen önce giriş yapın.")));
            return;
          }
          // DOĞRU EKRAN ÇAĞRISI
          bool? guncellendi = await Navigator.push(
            context, 
            MaterialPageRoute(builder: (c) => ProfilDuzenleEkrani(
              currentName: widget.userName ?? "", 
              phoneNumber: widget.phoneNumber!,
              profilePic: _user?['profilResmi'],
            ))
          );
          if (guncellendi == true) _kullaniciYukle();
        }),
        _ayarSatiri("Bildirim Ayarları", Icons.notifications_none, () {}),
        _ayarSatiri("Uygulama Teması", Icons.palette_outlined, () {}),
        _ayarSatiri("Hakkımızda", Icons.info_outline, () {}),
        _ayarSatiri("Yardım & Destek", Icons.help_outline, () {}),
      ],
    );
  }

  Widget _ayarSatiri(String baslik, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF161925), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFFF9800), size: 22),
        title: Text(baslik, style: const TextStyle(color: Colors.white, fontSize: 15)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white10, size: 14),
        onTap: onTap,
      ),
    );
  }

  Widget _cikisButonu() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.withOpacity(0.1),
        foregroundColor: Colors.red,
        side: BorderSide(color: Colors.red.withOpacity(0.3)),
        elevation: 0,
      ),
      onPressed: _cikisYap,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.logout_rounded, size: 18),
          SizedBox(width: 10),
          Text("Hesaptan Çıkış Yap", style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
