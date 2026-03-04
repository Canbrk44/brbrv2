import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  String _seciliSehir = "İstanbul, Kadıköy"; // Varsayılanı Admin paneliyle uyumlu yaptık

  @override
  void initState() {
    super.initState();
    _seciliIndex = widget.initialIndex;
    _guncelleSayfalar();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.phoneNumber != null) {
        _gecmisRandevuKontrolEt();
        _yaklasanRandevuKontrolEt();
      }
    });
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
            _sehirSatiri("Bursa, Nilüfer"),
            _sehirSatiri("Antalya, Muratpaşa"),
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
      body: _sayfalar[_seciliIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _seciliIndex,
        onTap: (index) {
          setState(() {
            _seciliIndex = index;
            _guncelleSayfalar();
          });
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

  // Randevu kontrolleri (Öncekiyle aynı)
  void _gecmisRandevuKontrolEt() async {
    final r = await _dbService.oylanmamisGecmisRandevuGetir(widget.phoneNumber!);
    if (r != null) { /* Oylama Popup */ }
  }
  void _yaklasanRandevuKontrolEt() async {
    final r = await _dbService.yaklasanBugunkuRandevuyuGetir(widget.phoneNumber!);
    if (r != null) { /* Hatırlatma Popup */ }
  }
}

class AnaSayfaIcerik extends StatelessWidget {
  final String? musteriTelefon;
  final String? userName;
  final String seciliSehir;

  const AnaSayfaIcerik({super.key, this.musteriTelefon, this.userName, required this.seciliSehir});

  Future<List<Map<String, dynamic>>> _getSalonlar() async {
    try {
      // 10.0.2.2 emülatör için localhost adresidir.
      final response = await http.get(Uri.parse('http://10.0.2.2:3000/api/salonlar')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        List<Map<String, dynamic>> all = List<Map<String, dynamic>>.from(json.decode(response.body));
        
        // Şehir eşleşmesini daha esnek yapıyoruz
        return all.where((s) {
          String sSehir = s['sehir'].toString().toLowerCase().trim();
          String target = seciliSehir.toLowerCase().trim();
          return sSehir == target;
        }).toList();
      }
    } catch (e) {
      debugPrint("API Bağlantı Hatası: $e");
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => (context as Element).markNeedsBuild(),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getSalonlar(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final berberler = snapshot.data ?? [];

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Merhaba ${userName ?? 'Misafir'},", style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  Text("Hoş geldin!", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 30),
                  Text("$seciliSehir İçindeki Salonlar", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  if (berberler.isEmpty)
                    Container(
                      height: 200,
                      alignment: Center,
                      child: const Text("Bu şehirde henüz kayıtlı salon bulunmuyor.\n(Admin panelinden eklediğinizden ve şehri doğru seçtiğinizden emin olun.)", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true, 
                      physics: const NeverScrollableScrollPhysics(), 
                      itemCount: berberler.length, 
                      itemBuilder: (context, index) => _berberKarti(context, berberler[index])
                    ),
                ],
              ),
            ),
          );
        },
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
              tag: 'salon_${berber['id']}', 
              child: ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                child: Image.network(
                  berber['resim'] ?? 'https://images.pexels.com/photos/3993323/pexels-photo-3993323.jpeg', 
                  width: 100, 
                  height: 100, 
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(width: 100, height: 100, color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                ),
              )
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(berber['isim'] ?? 'İsimsiz Salon', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 4),
                  Row(children: [const Icon(Icons.star_rounded, color: Colors.amber, size: 18), Text(" ${berber['puan']?.toString() ?? '0.0'}")]),
                  const SizedBox(height: 8),
                  Text(berber['sehir'] ?? "", style: const TextStyle(color: Colors.blueGrey, fontSize: 11)),
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
