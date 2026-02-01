import 'package:flutter/material.dart';
import 'profil_ekrani.dart';
import 'randevular_ekrani.dart';
import 'randevu_detay_ekrani.dart';

class AnaSayfa extends StatefulWidget {
  final bool isGuest;
  final String? phoneNumber;
  final String? userName;

  const AnaSayfa({super.key, this.isGuest = false, this.phoneNumber, this.userName});

  @override
  _AnaSayfaState createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  int _seciliIndex = 0;
  late List<Widget> _sayfalar;

  @override
  void initState() {
    super.initState();
    _sayfalar = [
      const AnaSayfaIcerik(),
      const RandevularEkrani(),
      ProfilEkrani(
        isGuest: widget.isGuest,
        phoneNumber: widget.phoneNumber,
        userName: widget.userName,
      ),
    ];
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
  const AnaSayfaIcerik({super.key});

  final List<Map<String, dynamic>> berberler = const [
    {'isim': 'Ahmet Usta', 'puan': '4.8', 'uzaklik': '1.2 km', 'resim': 'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=400'},
    {'isim': 'Makas Show', 'puan': '4.5', 'uzaklik': '800 m', 'resim': 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=400'},
    {'isim': 'Golden Cut', 'puan': '5.0', 'uzaklik': '2.5 km', 'resim': 'https://images.unsplash.com/photo-1621605815841-2cd6100b895c?w=400'},
    {'isim': 'Style Barber', 'puan': '4.2', 'uzaklik': '300 m', 'resim': 'https://images.unsplash.com/photo-1599351431202-1e0f0137899a?w=400'},
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Merhaba,", style: TextStyle(fontSize: 16, color: Colors.grey[700])),
              Text("Hoş geldin!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colorScheme.primary)),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  hintText: "Berber veya Salon ara...",
                  prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Popüler Berberler", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: () {}, child: const Text("Tümü")),
                ],
              ),
              const SizedBox(height: 10),
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
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RandevuDetayEkrani(berber: berber))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
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
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(berber['isim'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                        Text(" ${berber['puan']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(" (120 Yorum)", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        berber['uzaklik'],
                        style: TextStyle(color: colorScheme.secondary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
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
