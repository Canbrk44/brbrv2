import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sms_onay_ekrani.dart';
import 'giris_ekrani.dart';

class ProfilEkrani extends StatefulWidget {
  final bool isGuest;
  final String? phoneNumber;
  final String? userName;

  const ProfilEkrani({super.key, this.isGuest = false, this.phoneNumber, this.userName});

  @override
  State<ProfilEkrani> createState() => _ProfilEkraniState();
}

class _ProfilEkraniState extends State<ProfilEkrani> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _girisPopupGoster(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 25),
              const Text("Giriş Yap / Kayıt Ol", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Profilinizi yönetmek için bilgilerinizi girin.", style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 30),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline), hintText: "Adınız Soyadınız"),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
                decoration: const InputDecoration(prefixIcon: Icon(Icons.phone_outlined), hintText: "05xx xxx xx xx"),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  String name = _nameController.text;
                  String phone = _phoneController.text;
                  if (name.isNotEmpty && phone.length == 11 && phone.startsWith('0')) {
                    Navigator.pop(context); // Popup'ı kapat
                    // SMS Onayına gönder
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SmsOnayEkrani(
                          isLogin: true,
                          userName: name,
                          musteriTelefon: phone,
                          berberIsmi: "",
                          ustaIsmi: "",
                          tarih: "",
                          saat: "",
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen bilgileri doğru girin.")));
                  }
                },
                child: const Text("SMS DOĞRULAMASINA GEÇ"),
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // WOW HEADER - PROFİL
          SliverAppBar(
            expandedHeight: 220.0,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF4E342E),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                "Profilim", 
                style: TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 18,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 10)]
                )
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.pexels.com/photos/3992870/pexels-photo-3992870.jpeg',
                    fit: BoxFit.cover,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: widget.isGuest ? _ziyaretciGorunumu(context) : _profilGorunumu(context),
          ),
        ],
      ),
    );
  }

  Widget _ziyaretciGorunumu(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        children: [
          const SizedBox(height: 50),
          Icon(Icons.account_circle_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text("Profilinizi yönetmek için giriş yapın", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 30),
          ElevatedButton(onPressed: () => _girisPopupGoster(context), child: const Text("GİRİŞ YAP / KAYIT OL")),
        ],
      ),
    );
  }

  Widget _profilGorunumu(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(radius: 55, backgroundColor: primaryColor.withOpacity(0.1), child: Icon(Icons.person, size: 60, color: primaryColor)),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                    child: const Icon(Icons.edit, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(widget.userName ?? "Kullanıcı", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(widget.phoneNumber ?? "+90 5xx xxx xx xx", style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 40),
          _profilMenusu(Icons.person_outline, "Bilgilerimi Düzenle", () {}),
          _profilMenusu(Icons.calendar_month_outlined, "Randevularım", () {}),
          _profilMenusu(Icons.notifications_none_outlined, "Bildirim Ayarları", () {}),
          _profilMenusu(Icons.help_outline, "Yardım ve Destek", () {}),
          const SizedBox(height: 20),
          _profilMenusu(Icons.logout, "Çıkış Yap", () => _cikisYap(context), renk: Colors.red),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _cikisYap(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Tüm verileri sil (otomatik girişi iptal et)
    
    if (!mounted) return;
    
    // stack'i temizleyip giriş ekranına yönlendir
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const GirisEkrani()),
      (route) => false,
    );
  }

  Widget _profilMenusu(IconData ikon, String baslik, VoidCallback onTap, {Color? renk}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: ListTile(
        leading: Icon(ikon, color: renk ?? Colors.black87),
        title: Text(baslik, style: TextStyle(color: renk ?? Colors.black87, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }
}
