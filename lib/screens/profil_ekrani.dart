import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/database_service.dart';
import 'sms_onay_ekrani.dart';
import 'giris_ekrani.dart';
import 'ana_sayfa.dart';
import 'profil_duzenle_ekrani.dart';

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
  String? _currentName;
  String? _profilePic;

  @override
  void initState() {
    super.initState();
    _currentName = widget.userName;
    _userDataGetir();
  }

  Future<void> _userDataGetir() async {
    if (widget.phoneNumber != null) {
      final data = await _db.kullaniciGetir(widget.phoneNumber!);
      if (data != null && mounted) {
        setState(() {
          _currentName = data['adSoyad'];
          _profilePic = data['profilResmi'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 220.0,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF4E342E),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text("Profilim", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, shadows: [Shadow(color: Colors.black45, blurRadius: 10)])),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network('https://images.pexels.com/photos/3992870/pexels-photo-3992870.jpeg', fit: BoxFit.cover),
                  const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87]))),
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
    final primaryColor = const Color(0xFF4E342E);
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        children: [
          Center(
            child: CircleAvatar(
              radius: 55, 
              backgroundColor: primaryColor.withOpacity(0.1), 
              backgroundImage: (_profilePic != null && _profilePic!.isNotEmpty) ? NetworkImage(_profilePic!) : null,
              child: (_profilePic == null || _profilePic!.isEmpty) ? Icon(Icons.person, size: 60, color: primaryColor) : null,
            ),
          ),
          const SizedBox(height: 20),
          Text(_currentName ?? "Kullanıcı", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(widget.phoneNumber ?? "", style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 40),
          
          _profilMenusu(Icons.person_outline, "Bilgilerimi Düzenle", () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilDuzenleEkrani(
                  currentName: _currentName ?? "",
                  phoneNumber: widget.phoneNumber!,
                  profilePic: _profilePic,
                ),
              ),
            );
            if (result == true) {
              _userDataGetir();
            }
          }),
          
          _profilMenusu(Icons.calendar_month_outlined, "Randevularım", () {
            Navigator.pushAndRemoveUntil(
              context, 
              MaterialPageRoute(builder: (context) => AnaSayfa(phoneNumber: widget.phoneNumber, userName: _currentName, initialIndex: 2)),
              (route) => false,
            );
          }),
          
          _profilMenusu(Icons.notifications_none_outlined, "Bildirim Ayarları", () {
            showDialog(context: context, builder: (c) => AlertDialog(title: const Text("Bildirimler"), content: const Text("Bildirim ayarlarınızı telefonunuzun ayarlar kısmından yönetebilirsiniz."), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("Anladım"))]));
          }),
          
          _profilMenusu(Icons.help_outline, "Yardım ve Destek", () async {
            final Uri url = Uri.parse("https://wa.me/905320000000");
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          }),
          
          const SizedBox(height: 20),
          _profilMenusu(Icons.logout, "Çıkış Yap", () => _cikisOnayDialog(context), renk: Colors.red),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _cikisOnayDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Çıkış Yap"),
        content: const Text("Hesabınızdan çıkış yapmak istediğinize emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Vazgeç", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cikisYap(context);
            },
            child: const Text("Evet, Çıkış Yap", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _cikisYap(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const GirisEkrani()), (route) => false);
  }

  void _girisPopupGoster(BuildContext context) {
    final nC = TextEditingController(); final pC = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => Container(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))), child: Padding(padding: const EdgeInsets.all(30.0), child: Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))), const SizedBox(height: 25), const Text("Giriş Yap / Kayıt Ol", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 30), TextField(controller: nC, decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline), hintText: "Adınız Soyadınız")), const SizedBox(height: 15), TextField(controller: pC, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)], decoration: const InputDecoration(prefixIcon: Icon(Icons.phone_outlined), hintText: "05xx xxx xx xx")), const SizedBox(height: 30), ElevatedButton(onPressed: () { if (nC.text.isNotEmpty && pC.text.length == 11) { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => SmsOnayEkrani(isLogin: true, userName: nC.text, musteriTelefon: pC.text, berberIsmi: "", ustaIsmi: "", tarih: "", saat: ""))); } }, child: const Text("SMS DOĞRULAMASINA GEÇ")), const SizedBox(height: 15)]))));
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
