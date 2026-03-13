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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: _seciliIndex == 0 ? AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.store_rounded, color: theme.primaryColor, size: 20),
            tooltip: "Salon Girişi",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SalonGirisEkrani())),
          ),
        ),
        title: GestureDetector(
          onTap: _sehirSecimiGoster,
          child: Column(
            children: [
              Text("Konum", style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, size: 14, color: theme.primaryColor),
                  const SizedBox(width: 4),
                  Text(_seciliSehir, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
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
        selectedItemColor: theme.primaryColor,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: "Keşfet"),
          BottomNavigationBarItem(icon: Icon(Icons.star_outline_rounded), activeIcon: Icon(Icons.star_rounded), label: "En İyiler"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today_rounded), label: "Randevular"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: "Profil"),
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
    final theme = Theme.of(context);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: db.salonlariGetir(seciliSehir),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Hata: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final berberler = snapshot.data ?? [];
        final topBerberler = berberler.where((b) => (double.tryParse(b['puan']?.toString() ?? '0') ?? 0) >= 4.5).toList();

        return CustomScrollView(
          slivers: [
            // Karşılama Metni
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Merhaba, ${userName?.split(' ')[0] ?? 'Misafir'} 👋",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const Text(
                      "Bugün tarzını yenilemeye ne dersin?",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            // Top Salonlar Slider
            if (topBerberler.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Text("Öne Çıkan Salonlar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    scrollDirection: Axis.horizontal,
                    itemCount: topBerberler.length,
                    itemBuilder: (context, index) => _topBerberKarti(context, topBerberler[index]),
                  ),
                ),
              ),
            ],

            // Tüm Salonlar Başlığı
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 30, 20, 15),
                child: Text("Yakınındaki Tüm Salonlar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),

            // Tüm Salonlar Listesi
            if (berberler.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.storefront_outlined, size: 80, color: Colors.grey),
                      const SizedBox(height: 20),
                      Text("$seciliSehir için henüz bir salon eklenmedi."),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _berberKarti(context, berberler[index]),
                    childCount: berberler.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        );
      },
    );
  }

  Widget _topBerberKarti(BuildContext context, Map<String, dynamic> berber) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RandevuDetayEkrani(berber: berber, musteriTelefon: musteriTelefon, userName: userName))),
      child: Container(
        width: 280,
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                    child: Image.network(
                      berber['resim'] ?? 'https://images.pexels.com/photos/3993323/pexels-photo-3993323.jpeg',
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(color: Colors.grey[100], child: const Icon(Icons.image_not_supported)),
                    ),
                  ),
                  Positioned(
                    top: 15,
                    right: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                          Text(" ${berber['puan'] ?? '0.0'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(berber['isim'] ?? 'İsimsiz Salon', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: theme.primaryColor),
                      const SizedBox(width: 4),
                      Text(berber['sehir'] ?? "", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _berberKarti(BuildContext context, Map<String, dynamic> berber) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RandevuDetayEkrani(berber: berber, musteriTelefon: musteriTelefon, userName: userName))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(22), 
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                berber['resim'] ?? 'https://images.pexels.com/photos/3993323/pexels-photo-3993323.jpeg', 
                width: 90, height: 90, fit: BoxFit.cover,
                errorBuilder: (c,e,s) => Container(width: 90, height: 90, color: Colors.grey[100], child: const Icon(Icons.image_not_supported)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(berber['isim'] ?? 'İsimsiz Salon', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                        Text(" ${berber['puan'] ?? '0.0'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: theme.primaryColor.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text(berber['sehir']?.split(',')[0] ?? "", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.05), shape: BoxShape.circle),
              child: Icon(Icons.chevron_right_rounded, color: theme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
