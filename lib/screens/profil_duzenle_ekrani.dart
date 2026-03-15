import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../main.dart';

class ProfilDuzenleEkrani extends StatefulWidget {
  final String currentName;
  final String phoneNumber;
  final String? profilePic;

  const ProfilDuzenleEkrani({
    super.key,
    required this.currentName,
    required this.phoneNumber,
    this.profilePic,
  });

  @override
  State<ProfilDuzenleEkrani> createState() => _ProfilDuzenleEkraniState();
}

class _ProfilDuzenleEkraniState extends State<ProfilDuzenleEkrani> {
  final DatabaseService _db = DatabaseService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  
  String? _localProfilePic;
  String? _seciliCinsiyet;
  String? _seciliSehir;
  DateTime? _dogumTarihi;
  bool _isLoading = true;

  final List<String> _sehirler = ["Adana", "Adıyaman", "Afyonkarahisar", "Ağrı", "Aksaray", "Amasya", "Ankara", "Antalya", "Ardahan", "Artvin", "Aydın", "Balıkesir", "Bartın", "Batman", "Bayburt", "Bilecik", "Bingöl", "Bitlis", "Bolu", "Burdur", "Bursa", "Çanakkale", "Çankırı", "Çorum", "Denizli", "Diyarbakır", "Düzce", "Edirne", "Elazığ", "Erzincan", "Erzurum", "Eskişehir", "Gaziantep", "Giresun", "Gümüşhane", "Hakkari", "Hatay", "Iğdır", "Isparta", "İstanbul", "İzmir", "Kahramanmaraş", "Karabük", "Karaman", "Kars", "Kastamonu", "Kayseri", "Kırıkkale", "Kırklareli", "Kırşehir", "Kilis", "Kocaeli", "Konya", "Kütahya", "Malatya", "Manisa", "Mardin", "Mersin", "Muğla", "Muş", "Nevşehir", "Niğde", "Ordu", "Osmaniye", "Rize", "Sakarya", "Samsun", "Siirt", "Sinop", "Sivas", "Şanlıurfa", "Şırnak", "Tekirdağ", "Tokat", "Trabzon", "Tunceli", "Uşak", "Van", "Yalova", "Yozgat", "Zonguldak"];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentName;
    _localProfilePic = widget.profilePic;
    _userDataYukle();
  }

  Future<void> _userDataYukle() async {
    try {
      final data = await _db.kullaniciGetir(widget.phoneNumber);
      if (data != null && mounted) {
        setState(() {
          _emailController.text = data['email'] ?? "";
          _seciliCinsiyet = data['cinsiyet'];
          _seciliSehir = data['sehir'];
          if (data['dogumTarihi'] != null && data['dogumTarihi'].toString().length > 5) {
            _dogumTarihi = DateFormat('dd.MM.yyyy').parse(data['dogumTarihi']);
          }
        });
      }
    } catch (e) {} finally { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _kaydet() async {
    setState(() => _isLoading = true);
    await _db.kullaniciKaydet(
      adSoyad: _nameController.text.trim(),
      telefon: widget.phoneNumber,
      profilResmi: _localProfilePic,
      dogumTarihi: _dogumTarihi != null ? DateFormat('dd.MM.yyyy').format(_dogumTarihi!) : null,
      cinsiyet: _seciliCinsiyet,
      sehir: _seciliSehir,
      email: _emailController.text.trim(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text.trim());
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text("Bilgileri Düzenle")),
      body: GradientBackground(
        accentColor: const Color(0xFFFF9800),
        child: _isLoading ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF9800))) : SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              _profilResmiSecici(),
              const SizedBox(height: 40),
              _inputAlan("AD SOYAD", _nameController, Icons.person_outline),
              const SizedBox(height: 20),
              _inputAlan("E-POSTA", _emailController, Icons.email_outlined),
              const SizedBox(height: 20),
              _sehirSecici(),
              const SizedBox(height: 20),
              _cinsiyetSecici(),
              const SizedBox(height: 50),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9800)),
                onPressed: _kaydet,
                child: const Text("DEĞİŞİKLİKLERİ KAYDET", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profilResmiSecici() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.white.withOpacity(0.05),
          backgroundImage: (_localProfilePic != null && _localProfilePic!.isNotEmpty) ? NetworkImage(_localProfilePic!) : const NetworkImage("https://i.pravatar.cc/300"),
        ),
        GestureDetector(
          onTap: () async {
            final XFile? img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
            if (img != null) {
              String? url = await _db.profilResmiYukle(File(img.path), widget.phoneNumber);
              setState(() => _localProfilePic = url);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Color(0xFFFF9800), shape: BoxShape.circle),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _inputAlan(String baslik, TextEditingController cont, IconData icon) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF161925), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: TextField(
        controller: cont,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: baslik,
          labelStyle: const TextStyle(color: Colors.white24, fontSize: 12),
          prefixIcon: Icon(icon, color: const Color(0xFFFF9800), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _sehirSecici() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: const Color(0xFF161925), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _seciliSehir,
          hint: const Text("Şehir Seçin", style: TextStyle(color: Colors.white24)),
          dropdownColor: const Color(0xFF161925),
          isExpanded: true,
          style: const TextStyle(color: Colors.white),
          items: _sehirler.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => _seciliSehir = v),
        ),
      ),
    );
  }

  Widget _cinsiyetSecici() {
    return Row(
      children: ["Erkek", "Kadın"].map((c) {
        bool isS = _seciliCinsiyet == c;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _seciliCinsiyet = c),
            child: Container(
              margin: EdgeInsets.only(right: c == "Erkek" ? 10 : 0, left: c == "Kadın" ? 10 : 0),
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: isS ? const Color(0xFFFF9800).withOpacity(0.1) : const Color(0xFF161925),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: isS ? const Color(0xFFFF9800) : Colors.white10),
              ),
              child: Center(child: Text(c, style: TextStyle(color: isS ? Colors.white : Colors.white38, fontWeight: FontWeight.bold))),
            ),
          ),
        );
      }).toList(),
    );
  }
}
