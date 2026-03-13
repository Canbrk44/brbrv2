import 'package:flutter/material.dart';
import 'profil_ekrani.dart';
import 'randevular_ekrani.dart';
import 'randevu_detay_ekrani.dart';
import 'en_iyiler_ekrani.dart';
import 'salon_giris_ekrani.dart';
import '../services/database_service.dart';

class AnaSayfa extends StatefulWidget {
  final bool isGuest;
  final String? phoneNumber;
  final String? userName;
  final int initialIndex;

  const AnaSayfa({
    super.key, 
    this.isGuest = false, 
    this.phoneNumber, 
    this.userName,
    this.initialIndex = 0,
  });

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  late int _seciliIndex;
  late List<Widget> _sayfalar;
  String _seciliSehir = "Ankara, Çankaya"; 

  @override
  void initState() {
    super.initState();
    _seciliIndex = widget.initialIndex;
    _guncelleSayfalar();
  }

  void _guncelleSayfalar() {
    _sayfalar = [
      AnaSayfaIcerik(
        musteriTelefon: widget.phoneNumber, 
        userName: widget.userName, 
        seciliSehir: _seciliSehir,
      ),
      EnIyilerEkrani(musteriTelefon: widget.phoneNumber, userName: widget.userName),
      RandevularEkrani(musteriTelefon: widget.phoneNumber),
      ProfilEkrani(isGuest: widget.isGuest, phoneNumber: widget.phoneNumber, userName: widget.userName),
    ];
  }

  void _sehirSecimiGoster() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Şehir Seçin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _sehirSatiri("İstanbul, Kadıköy"),
            _sehirSatiri("Ankara, Çankaya"),
            _sehirSatiri("İzmir, Konak"),
          ],
        ),
      ),
    );
  }

  Widget _sehirSatiri(String sehir) {
    return ListTile(
      title: Text(sehir),
      onTap: () {
        setState(() {
          _seciliSehir = sehir;
          _guncelleSayfalar();
        });
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _seciliIndex == 0 ? AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.store_rounded, color: Color(0xFF0F172A), size: 20),
            tooltip: "Salon Girişi",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SalonGirisEkrani())),
          ),
        ),
        title: GestureDetector(
          onTap: _sehirSecimiGoster,
          child: Column(
            children: [
              Text("Konum", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
                  const SizedBox(width: 4),
                  Text(_seciliSehir, style: const TextStyle(fontSize: 16)),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ) : null,
      body: IndexedStack(
        index: _seciliIndex,
        children: _sayfalar,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _seciliIndex,
        onTap: (index) {
          setState(() { _seciliIndex = index; });
        },
        selectedItemColor: const Color(0xFF0F172A),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Ana Sayfa"),
          BottomNavigationBarItem(icon: Icon(Icons.workspace_premium_rounded), label: "En İyiler"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: "Randevular"),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profil"),
        ],
      ),
    );
  }
}

class AnaSayfaIcerik extends StatelessWidget {
  final String? musteriTelefon;
  final String? userName;
  final String seciliSehir;

  const AnaSayfaIcerik({super.key, this.musteriTelefon, this.userName, required this.seciliSehir});

  @override
  Widget build(BuildContext context) {
    final DatabaseService db = DatabaseService();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: db.salonlariGetir(seciliSehir),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Hata: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final berberler = snapshot.data ?? [];

        if (berberler.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storefront_outlined, size: 80, color: Colors.grey),
                const SizedBox(height: 20),
                Text("$seciliSehir için henüz bir salon eklenmedi."),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: berberler.length,
          itemBuilder: (context, index) => _berberKarti(context, berberler[index]),
        );
      },
    );
  }

  Widget _berberKarti(BuildContext context, Map<String, dynamic> berber) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RandevuDetayEkrani(berber: berber, musteriTelefon: musteriTelefon, userName: userName))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(20), 
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
              child: Image.network(
                berber['resim'] ?? 'https://images.pexels.com/photos/3993323/pexels-photo-3993323.jpeg', 
                width: 110, height: 110, fit: BoxFit.cover,
                errorBuilder: (c,e,s) => Container(width: 110, height: 110, color: Colors.grey[100], child: const Icon(Icons.image_not_supported)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(berber['isim'] ?? 'İsimsiz Salon', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 4),
                  Row(children: [const Icon(Icons.star_rounded, color: Colors.amber, size: 18), Text(" ${berber['puan'] ?? '0.0'}", style: const TextStyle(fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 4),
                  Text(berber['sehir'] ?? "", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
