import 'package:flutter/material.dart';

class ProfilEkrani extends StatelessWidget {
  final bool isGuest;
  final String? phoneNumber;
  final String? userName;

  ProfilEkrani({this.isGuest = false, this.phoneNumber, this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profil", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: isGuest ? _ziyaretciGorunumu(context) : _profilGorunumu(context),
      ),
    );
  }

  Widget _ziyaretciGorunumu(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        children: [
          SizedBox(height: 50),
          Icon(Icons.account_circle_outlined, size: 100, color: Colors.grey[400]),
          SizedBox(height: 20),
          Text(
            "Profilinizi yönetmek için giriş yapın",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: Text("GİRİŞ YAP / KAYIT OL"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profilGorunumu(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Column(
      children: [
        SizedBox(height: 30),
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 55,
                backgroundColor: primaryColor.withOpacity(0.1),
                child: Icon(Icons.person, size: 60, color: primaryColor),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                  child: Icon(Icons.edit, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        Text(userName ?? "Kullanıcı", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(phoneNumber ?? "+90 5xx xxx xx xx", style: TextStyle(color: Colors.grey[600])),
        SizedBox(height: 40),
        _profilMenusu(Icons.person_outline, "Bilgilerimi Düzenle", () {}),
        _profilMenusu(Icons.calendar_month_outlined, "Randevularım", () {}),
        _profilMenusu(Icons.notifications_none_outlined, "Bildirim Ayarları", () {}),
        _profilMenusu(Icons.help_outline, "Yardım ve Destek", () {}),
        SizedBox(height: 20),
        _profilMenusu(Icons.logout, "Çıkış Yap", () => Navigator.of(context).popUntil((route) => route.isFirst), renk: Colors.red),
      ],
    );
  }

  Widget _profilMenusu(IconData ikon, String baslik, VoidCallback onTap, {Color? renk}) {
    return ListTile(
      leading: Icon(ikon, color: renk ?? Colors.black87),
      title: Text(baslik, style: TextStyle(color: renk ?? Colors.black87, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
