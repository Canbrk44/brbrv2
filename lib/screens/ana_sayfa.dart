import 'dart:math';
import 'package:flutter/material.dart';
import 'profil_ekrani.dart';
import 'randevular_ekrani.dart';
import 'randevu_detay_ekrani.dart';
import 'en_iyiler_ekrani.dart';
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
  _AnaSayfaState createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  late int _seciliIndex;
  late List<Widget> _sayfalar;
  final DatabaseService _dbService = DatabaseService();
  String _seciliSehir = "Istanbul, Kadikoy";

  final List<String> _sehirler = [
    "Adana", "Ankara", "Antalya", "Bursa", "Canakkale", "Denizli", "Diyarbakir", "Eskisehir", 
    "Gaziantep", "Hatay", "Isparta", "Mersin", "Istanbul, Kadikoy", "Istanbul, Besiktas", 
    "Istanbul, Sisli", "Izmir", "Kayseri", "Kocaeli", "Konya", "Mugla", "Samsun", "Trabzon"
  ];

  @override
  void initState() {
    super.initState();
    _seciliIndex = widget.initialIndex;
    _sayfalar = [
      AnaSayfaIcerik(musteriTelefon: widget.phoneNumber, userName: widget.userName, seciliSehir: _seciliSehir),
      EnIyilerEkrani(musteriTelefon: widget.phoneNumber, userName: widget.userName),
      RandevularEkrani(musteriTelefon: widget.phoneNumber),
      ProfilEkrani(isGuest: widget.isGuest, phoneNumber: widget.phoneNumber, userName: widget.userName),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.phoneNumber != null) {
        _gecmisRandevuKontrolEt();
        _yaklasanRandevuKontrolEt();
      }
    });
  }

  void _sehirSecimiGoster() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Sehir Secin", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _sehirler.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_sehirler[index], style: TextStyle(fontWeight: _seciliSehir == _sehirler[index] ? FontWeight.bold : FontWeight.normal)),
                    trailing: _seciliSehir == _sehirler[index] ? Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary) : null,
                    onTap: () {
                      setState(() {
                        _seciliSehir = _sehirler[index];
                        _sayfalar[0] = AnaSayfaIcerik(musteriTelefon: widget.phoneNumber, userName: widget.userName, seciliSehir: _seciliSehir);
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _gecmisRandevuKontrolEt() async {
    final randevu = await _dbService.oylanmamisGecmisRandevuGetir(widget.phoneNumber!);
    if (randevu != null && mounted) {
      _oylamaPopupGoster(randevu);
    }
  }

  void _yaklasanRandevuKontrolEt() async {
    final randevu = await _dbService.yaklasanBugunkuRandevuyuGetir(widget.phoneNumber!);
    if (randevu != null && mounted) {
      _hatirlatmaPopupGoster(randevu);
    }
  }

  void _hatirlatmaPopupGoster(Map<String, dynamic> r) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Row(children: [Icon(Icons.notifications_active, color: Colors.amber), SizedBox(width: 10), Text("Randevu Hatirlatici")]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Bugun icin bir randevunuz bulunuyor!", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 15),
            Text("Salon: ${r['berberIsmi']}"),
            Text("Usta: ${r['ustaIsmi']}"),
            const SizedBox(height: 5),
            Text("Saat: ${r['saat']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ANLADIM")),
          ElevatedButton(onPressed: () { Navigator.pop(context); setState(() => _seciliIndex = 2); }, child: const Text("DETAYLARA GIT")),
        ],
      ),
    );
  }

  void _oylamaPopupGoster(Map<String, dynamic> r) {
    double ustaPuani = 0;
    double berberPuani = 0;
    final TextEditingController yorumC = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: Text("${r['berberIsmi']} Deneyiminizi Oylayin"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Hizmetiniz tamamlandi! Lutfen degerlendirin."),
                const SizedBox(height: 20),
                Text("Usta: ${r['ustaIsmi']}", style: const TextStyle(fontWeight: FontWeight.w600)),
                _yildizSatiri((p) => setS(() => ustaPuani = p.toDouble()), ustaPuani.toInt()),
                const SizedBox(height: 15),
                const Text("Berber / Salon", style: TextStyle(fontWeight: FontWeight.w600)),
                _yildizSatiri((p) => setS(() => berberPuani = p.toDouble()), berberPuani.toInt()),
                const SizedBox(height: 20),
                TextField(controller: yorumC, maxLines: 3, decoration: InputDecoration(hintText: "Usta hakkinda yorumunuzu buraya yazin...", fillColor: Colors.grey[100], filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))),
              ],
            ),
          ),
          actions: [
            ElevatedButton(onPressed: (ustaPuani > 0 && berberPuani > 0) ? () async { await _dbService.yorumKaydet(ustaIsmi: r['ustaIsmi'], salonIsmi: r['berberIsmi'], musteriAd: widget.userName ?? "Anonim", puan: ustaPuani, yorumMetni: yorumC.text); await _dbService.randevuyuTamamlaVeOyla(r['id']); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Degerlendirmeniz icin tesekkurler!"))); } : null, child: const Text("GONDER VE TAMAMLA")),
          ],
        ),
      ),
    );
  }

  Widget _yildizSatiri(Function(int) onSelect, int puan) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (index) => IconButton(icon: Icon(index < puan ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 30), onPressed: () => onSelect(index + 1))));
  }

  void _sayfaDegistir(int index) {
    setState(() {
      _seciliIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _seciliIndex == 0 ? AppBar(
        title: GestureDetector(
          onTap: _sehirSecimiGoster,
          child: Column(
            children: [
              Text("Konum", style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.normal)),
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
        actions: [
          if (widget.userName != null)
            IconButton(icon: const Icon(Icons.notifications_none_rounded), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ) : null,
      body: _sayfalar[_seciliIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _seciliIndex,
        onTap: _sayfaDegistir,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Ana Sayfa"),
          BottomNavigationBarItem(icon: Icon(Icons.workspace_premium_rounded), label: "En Iyiler"),
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
  AnaSayfaIcerik({super.key, this.musteriTelefon, this.userName, required this.seciliSehir});

  final List<String> salonEkleri = ["Barber", "Salon", "Kuafor", "Style", "Makas", "Kesim", "Premium"];
  final List<String> isimler = ["Ahmet", "Mehmet", "Can", "Bora", "Deniz", "Ege", "Fatih", "Gokhan"];
  final List<String> resimler = [
    'https://images.pexels.com/photos/1319460/pexels-photo-1319460.jpeg?auto=compress&cs=tinysrgb&w=400',
    'https://images.pexels.com/photos/1813272/pexels-photo-1813272.jpeg?auto=compress&cs=tinysrgb&w=400',
    'https://images.pexels.com/photos/705255/pexels-photo-705255.jpeg?auto=compress&cs=tinysrgb&w=400',
    'https://images.pexels.com/photos/2040189/pexels-photo-2040189.jpeg?auto=compress&cs=tinysrgb&w=400',
    'https://images.pexels.com/photos/1570807/pexels-photo-1570807.jpeg?auto=compress&cs=tinysrgb&w=400',
    'https://images.pexels.com/photos/2521978/pexels-photo-2521978.jpeg?auto=compress&cs=tinysrgb&w=400',
    'https://images.pexels.com/photos/3992874/pexels-photo-3992874.jpeg?auto=compress&cs=tinysrgb&w=400',
    'https://images.pexels.com/photos/1453005/pexels-photo-1453005.jpeg?auto=compress&cs=tinysrgb&w=400'
  ];

  List<Map<String, dynamic>> _sehireOzelVeriUret(String sehir) {
    Random random = Random(sehir.hashCode); // Her sehir icin farkli ama sabit sonuc uretir
    List<Map<String, dynamic>> sonuclar = [];
    
    for (int i = 0; i < 8; i++) {
      String ustaIsmi = isimler[random.nextInt(isimler.length)];
      String salonIsmi = "$ustaIsmi ${salonEkleri[random.nextInt(salonEkleri.length)]}";
      double puan = 4.0 + (random.nextInt(11) / 10.0);
      double mesafe = 0.5 + (random.nextInt(50) / 10.0);
      
      sonuclar.add({
        'isim': salonIsmi,
        'puan': puan.toStringAsFixed(1),
        'uzaklik': "${mesafe.toStringAsFixed(1)} km",
        'resim': resimler[random.nextInt(resimler.length)],
        'enIyiUsta': "$ustaIsmi Yilmaz"
      });
    }
    return sonuclar;
  }

  @override
  Widget build(BuildContext context) {
    final berberler = _sehireOzelVeriUret(seciliSehir);
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Merhaba ${userName ?? 'Misafir'},", style: const TextStyle(fontSize: 16, color: Colors.grey)),
            Text("Hoş geldin!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 20),
            TextField(decoration: InputDecoration(hintText: "Berber veya Salon ara...", prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.primary))),
            const SizedBox(height: 30),
            Text("$seciliSehir Icindeki Populer Berberler", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: berberler.length, itemBuilder: (context, index) => _berberKarti(context, berberler[index])),
          ],
        ),
      ),
    );
  }

  Widget _berberKarti(BuildContext context, Map<String, dynamic> berber) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RandevuDetayEkrani(berber: berber, musteriTelefon: musteriTelefon, userName: userName))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Row(
          children: [
            Hero(
              tag: berber['isim'], 
              child: ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                child: Image.network(
                  berber['resim'], 
                  width: 100, 
                  height: 100, 
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(width: 100, height: 100, color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
                ),
              )
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(berber['isim'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(children: [const Icon(Icons.star_rounded, color: Colors.amber, size: 18), Text(" ${berber['puan']}", style: const TextStyle(fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 8),
                  Text(berber['uzaklik'], style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12, fontWeight: FontWeight.bold)),
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
