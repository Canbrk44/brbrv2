import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';

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
  bool _isLoading = true; // Başlangıçta true yaparak titremeyi önleyelim

  final List<String> _sehirler = [
    "Adana", "Adıyaman", "Afyonkarahisar", "Ağrı", "Aksaray", "Amasya", "Ankara", "Antalya", "Ardahan", "Artvin", "Aydın", "Balıkesir", "Bartın", "Batman", "Bayburt", "Bilecik", "Bingöl", "Bitlis", "Bolu", "Burdur", "Bursa", "Çanakkale", "Çankırı", "Çorum", "Denizli", "Diyarbakır", "Düzce", "Edirne", "Elazığ", "Erzincan", "Erzurum", "Eskişehir", "Gaziantep", "Giresun", "Gümüşhane", "Hakkari", "Hatay", "Iğdır", "Isparta", "İstanbul", "İzmir", "Kahramanmaraş", "Karabük", "Karaman", "Kars", "Kastamonu", "Kayseri", "Kırıkkale", "Kırklareli", "Kırşehir", "Kilis", "Kocaeli", "Konya", "Kütahya", "Malatya", "Manisa", "Mardin", "Mersin", "Muğla", "Muş", "Nevşehir", "Niğde", "Ordu", "Osmaniye", "Rize", "Sakarya", "Samsun", "Siirt", "Sinop", "Sivas", "Şanlıurfa", "Şırnak", "Tekirdağ", "Tokat", "Trabzon", "Tunceli", "Uşak", "Van", "Yalova", "Yozgat", "Zonguldak"
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentName;
    _localProfilePic = widget.profilePic;
    _userDataYukle();
  }

  Future<void> _userDataYukle() async {
    try {
      setState(() => _isLoading = true);
      final data = await _db.kullaniciGetir(widget.phoneNumber);
      if (data != null && mounted) {
        setState(() {
          _emailController.text = data['email'] ?? "";
          _seciliCinsiyet = (data['cinsiyet'] != null && data['cinsiyet'].isNotEmpty) ? data['cinsiyet'] : null;
          _seciliSehir = (data['sehir'] != null && data['sehir'].isNotEmpty) ? data['sehir'] : null;
          if (data['dogumTarihi'] != null && data['dogumTarihi'].toString().length > 5) {
            try {
              _dogumTarihi = DateFormat('dd.MM.yyyy').parse(data['dogumTarihi']);
            } catch(e) {
              debugPrint("Tarih ayrıştırma hatası: $e");
            }
          }
        });
      }
    } catch (e) {
      debugPrint("Kullanıcı verisi yükleme hatası: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _tarihSec() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dogumTarihi ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF4E342E))),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dogumTarihi = picked);
  }

  Future<void> _kaydet() async {
    if (_nameController.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen geçerli bir isim girin.")));
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await _db.kullaniciKaydet(
        adSoyad: _nameController.text.trim(),
        telefon: widget.phoneNumber,
        profilResmi: _localProfilePic,
        dogumTarihi: _dogumTarihi != null ? DateFormat('dd.MM.yyyy').format(_dogumTarihi!) : null,
        cinsiyet: _seciliCinsiyet,
        sehir: _seciliSehir,
        email: _emailController.text.trim(),
        yeniKayit: false,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _nameController.text.trim());

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profiliniz başarıyla güncellendi.")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kaydedilirken bir hata oluştu.")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF4E342E);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Profil Bilgileri", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (!_isLoading)
            TextButton(onPressed: _kaydet, child: const Text("KAYDET", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold))),
        ],
      ),
      body: _isLoading 
      ? const Center(child: CircularProgressIndicator(color: primaryColor))
      : SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: primaryColor.withOpacity(0.1),
                      backgroundImage: (_localProfilePic != null && _localProfilePic!.isNotEmpty) ? NetworkImage(_localProfilePic!) : null,
                      child: (_localProfilePic == null || _localProfilePic!.isEmpty) ? const Icon(Icons.person, size: 60, color: primaryColor) : null,
                    ),
                    Positioned(bottom: 0, right: 0, child: GestureDetector(onTap: () async {
                      final XFile? img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
                      if (img != null) {
                        setState(() => _isLoading = true);
                        String? url = await _db.profilResmiYukle(File(img.path), widget.phoneNumber);
                        setState(() { _localProfilePic = url; _isLoading = false; });
                      }
                    }, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: const Icon(Icons.camera_alt, color: Colors.white, size: 16)))),
                  ],
                ),
              ),
              const SizedBox(height: 35),
              _label("AD SOYAD"),
              _textField(_nameController, Icons.person_outline, "Ad Soyad"),
              const SizedBox(height: 20),
              _label("E-POSTA"),
              _textField(_emailController, Icons.email_outlined, "E-posta adresi", type: TextInputType.emailAddress),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label("DOĞUM TARİHİ"),
                        GestureDetector(
                          onTap: _tarihSec,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                            decoration: BoxDecoration(color: const Color(0xFFF5F7F8), borderRadius: BorderRadius.circular(15)),
                            child: Row(children: [const Icon(Icons.cake_outlined, size: 20, color: primaryColor), const SizedBox(width: 10), Text(_dogumTarihi == null ? "Seçiniz" : DateFormat('dd.MM.yyyy').format(_dogumTarihi!), style: TextStyle(color: _dogumTarihi == null ? Colors.grey : Colors.black87))]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label("CİNSİYET"),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(color: const Color(0xFFF5F7F8), borderRadius: BorderRadius.circular(15)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: (_seciliCinsiyet == null || _seciliCinsiyet!.isEmpty) ? null : _seciliCinsiyet,
                              hint: const Text("Seçiniz", style: TextStyle(fontSize: 14)),
                              isExpanded: true,
                              items: ["Erkek", "Kadın"].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14)))).toList(),
                              onChanged: (v) => setState(() => _seciliCinsiyet = v),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _label("YAŞADIĞINIZ ŞEHİR"),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(color: const Color(0xFFF5F7F8), borderRadius: BorderRadius.circular(15)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: (_seciliSehir == null || _seciliSehir!.isEmpty) ? null : _seciliSehir,
                    hint: const Text("Şehir Seçiniz"),
                    isExpanded: true,
                    menuMaxHeight: 300,
                    items: _sehirler.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _seciliSehir = v),
                  ),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(left: 5, bottom: 8), child: Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)));
  Widget _textField(TextEditingController c, IconData i, String h, {TextInputType? type}) => TextField(controller: c, keyboardType: type, decoration: InputDecoration(prefixIcon: Icon(i, color: const Color(0xFF4E342E), size: 20), hintText: h, filled: true, fillColor: const Color(0xFFF5F7F8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 15)));
}
