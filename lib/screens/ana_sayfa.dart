import 'package:flutter/material.dart';
import 'profil_ekrani.dart';
import 'randevular_ekrani.dart';
import 'randevu_detay_ekrani.dart';
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

  @override
  void initState() {
    super.initState();
    _seciliIndex = widget.initialIndex;
    _sayfalar = [
      AnaSayfaIcerik(musteriTelefon: widget.phoneNumber, userName: widget.userName),
      RandevularEkrani(musteriTelefon: widget.phoneNumber),
      ProfilEkrani(
        isGuest: widget.isGuest,
        phoneNumber: widget.phoneNumber,
        userName: widget.userName,
      ),
    ];

    // Uygulama açıldığında oylanmamış geçmiş randevu kontrolü
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.phoneNumber != null) {
        _gecmisRandevuKontrolEt();
      }
    });
  }

  void _gecmisRandevuKontrolEt() async {
    final randevu = await _dbService.oylanmamisGecmisRandevuGetir(widget.phoneNumber!);
    if (randevu != null && mounted) {
      _oylamaPopupGoster(randevu);
    }
  }

  void _oylamaPopupGoster(Map<String, dynamic> r) {
    int ustaPuani = 0;
    int berberPuani = 0;
    final TextEditingController yorumC = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: Text("${r['berberIsmi']} Deneyiminizi Oylayın", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Hizmetiniz tamamlandı! Lütfen değerlendirin."),
                const SizedBox(height: 20),
                Text("Usta: ${r['ustaIsmi']}", style: const TextStyle(fontWeight: FontWeight.w600)),
                _yildizSatiri((p) => setS(() => ustaPuani = p), ustaPuani),
                const SizedBox(height: 15),
                const Text("Berber / Salon", style: TextStyle(fontWeight: FontWeight.w600)),
                _yildizSatiri((p) => setS(() => berberPuani = p), berberPuani),
                const SizedBox(height: 20),
                TextField(
                  controller: yorumC,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Yorumunuzu buraya yazın...",
                    fillColor: Colors.grey[100],
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: (ustaPuani > 0 && berberPuani > 0) ? () async {
                await _dbService.randevuyuTamamlaVeOyla(r['id']);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Değerlendirmeniz için teşekkürler!")));
              } : null,
              child: const Text("GÖNDER VE TAMAMLA"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _yildizSatiri(Function(int) onSelect, int puan) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) => IconButton(
        icon: Icon(index < puan ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 30),
        onPressed: () => onSelect(index + 1),
      )),
    );
  }

  void _sayfaDegistir(int index) {
    setState(() {
      _seciliIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
  const AnaSayfaIcerik({super.key, this.musteriTelefon, this.userName});

  final List<Map<String, dynamic>> berberler = const [
    {'isim': 'Ahmet Usta', 'puan': '4.8', 'uzaklik': '1.2 km', 'resim': 'https://images.pexels.com/photos/1319460/pexels-photo-1319460.jpeg?auto=compress&cs=tinysrgb&w=400'},
    {'isim': 'Makas Show', 'puan': '4.5', 'uzaklik': '800 m', 'resim': 'https://images.pexels.com/photos/1813272/pexels-photo-1813272.jpeg?auto=compress&cs=tinysrgb&w=400'},
    {'isim': 'Golden Cut', 'puan': '5.0', 'uzaklik': '2.5 km', 'resim': 'https://images.pexels.com/photos/705255/pexels-photo-705255.jpeg?auto=compress&cs=tinysrgb&w=400'},
    {'isim': 'Style Barber', 'puan': '4.2', 'uzaklik': '300 m', 'resim': 'https://images.pexels.com/photos/2040189/pexels-photo-2040189.jpeg?auto=compress&cs=tinysrgb&w=400'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text("Konum", style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.normal)),
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.redAccent),
                SizedBox(width: 4),
                Text("İstanbul, Kadıköy"),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Merhaba ${userName ?? ''},", style: TextStyle(fontSize: 16, color: Colors.grey[700])),
              Text("Hoş geldin!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  hintText: "Berber veya Salon ara...",
                  prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(height: 30),
              const Text("Popüler Berberler", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: berberler.length,
                itemBuilder: (context, index) => _berberKarti(context, berberler[index]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _berberKarti(BuildContext context, Map<String, dynamic> berber) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(
          builder: (context) => RandevuDetayEkrani(
            berber: berber,
            musteriTelefon: musteriTelefon,
            userName: userName,
          )
        )
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: berber['isim'],
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                  image: DecorationImage(
                    image: NetworkImage(berber['resim']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(berber['isim'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                      Text(" ${berber['puan']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
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
