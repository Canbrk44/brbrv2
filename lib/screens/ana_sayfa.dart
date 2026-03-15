import 'package:flutter/material.dart';
import 'profil_ekrani.dart';
import 'randevular_ekrani.dart';
import 'en_iyiler_ekrani.dart';
import 'salon_giris_ekrani.dart';
import 'usta_detay_ekrani.dart';
import 'randevu_detay_ekrani.dart';
import '../services/database_service.dart';
import '../main.dart'; 

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
  String _seciliSehir = "Ankara, Çankaya"; 

  final List<Color> _sekmeRenkleri = [
    const Color(0xFFE91E63),
    const Color(0xFF2196F3),
    const Color(0xFF9C27B0),
    const Color(0xFFFF9800),
  ];

  @override
  void initState() {
    super.initState();
    _seciliIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        accentColor: _sekmeRenkleri[_seciliIndex],
        child: IndexedStack(
          index: _seciliIndex,
          children: [
            AnaSayfaIcerik(musteriTelefon: widget.phoneNumber, userName: widget.userName, seciliSehir: _seciliSehir, onCityTap: _sehirSecimiGoster),
            EnIyilerEkrani(musteriTelefon: widget.phoneNumber, userName: widget.userName),
            RandevularEkrani(musteriTelefon: widget.phoneNumber),
            ProfilEkrani(isGuest: widget.isGuest, phoneNumber: widget.phoneNumber, userName: widget.userName),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05), width: 0.5))),
        child: BottomNavigationBar(
          currentIndex: _seciliIndex,
          onTap: (index) => setState(() => _seciliIndex = index),
          selectedItemColor: _sekmeRenkleri[_seciliIndex],
          unselectedItemColor: Colors.white24,
          backgroundColor: const Color(0xFF0F111A),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: "Keşfet"),
            BottomNavigationBarItem(icon: Icon(Icons.stars_outlined), activeIcon: Icon(Icons.stars), label: "En İyiler"),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), activeIcon: Icon(Icons.calendar_month), label: "Randevular"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person), label: "Profil"),
          ],
        ),
      ),
    );
  }

  void _sehirSecimiGoster() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161925),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text("Şehir Seçin", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            _sehirSatiri("İstanbul, Kadıköy", Icons.location_city),
            _sehirSatiri("Ankara, Çankaya", Icons.account_balance),
            _sehirSatiri("İzmir, Konak", Icons.beach_access),
          ],
        ),
      ),
    );
  }

  Widget _sehirSatiri(String sehir, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: _sekmeRenkleri[_seciliIndex]),
        title: Text(sehir, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
        onTap: () {
          setState(() => _seciliSehir = sehir);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class AnaSayfaIcerik extends StatelessWidget {
  final String? musteriTelefon;
  final String? userName;
  final String seciliSehir;
  final VoidCallback onCityTap;

  const AnaSayfaIcerik({super.key, this.musteriTelefon, this.userName, required this.seciliSehir, required this.onCityTap});

  @override
  Widget build(BuildContext context) {
    final DatabaseService db = DatabaseService();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: db.salonlariGetir(seciliSehir),
      builder: (context, snapshot) {
        final berberler = snapshot.data ?? [];
        final topBerberler = berberler.where((b) => (double.tryParse(b['puan']?.toString() ?? '0') ?? 0) >= 4.0).toList();
        
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              toolbarHeight: 100,
              leading: Padding(
                padding: const EdgeInsets.only(top: 20, left: 10),
                child: IconButton(
                  icon: const CircleAvatar(backgroundColor: Color(0xFF161925), child: Icon(Icons.storefront, color: Colors.white70, size: 18)),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SalonGirisEkrani())),
                ),
              ),
              title: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Merhaba, ${userName?.split(' ')[0] ?? 'Misafir'} 👋", style: const TextStyle(color: Colors.white54, fontSize: 14)),
                    const Text("Stilini Belirle", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(top: 20, right: 15),
                  child: IconButton(
                    icon: const CircleAvatar(backgroundColor: Color(0xFF161925), child: Icon(Icons.search, color: Colors.white70, size: 20)),
                    onPressed: () {
                      showSearch(context: context, delegate: BerberUstaArama(berberler: berberler, tel: musteriTelefon, ad: userName));
                    },
                  ),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                child: GestureDetector(
                  onTap: onCityTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFFE91E63), size: 18),
                        const SizedBox(width: 12),
                        Text(seciliSehir, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        const Spacer(),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white24),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            if (topBerberler.isNotEmpty) ...[
              const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(25, 30, 25, 15), child: Text("Popüler Salonlar", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 230,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    scrollDirection: Axis.horizontal,
                    itemCount: topBerberler.length,
                    itemBuilder: (context, index) => _TopSalonKarti(berber: topBerberler[index], tel: musteriTelefon, ad: userName),
                  ),
                ),
              ),
            ],

            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(25, 35, 25, 15), child: Text("Tüm Salonlar", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _NormalSalonKarti(berber: berberler[index], tel: musteriTelefon, ad: userName),
                  childCount: berberler.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }
}

class BerberUstaArama extends SearchDelegate {
  final List<Map<String, dynamic>> berberler;
  final String? tel;
  final String? ad;
  BerberUstaArama({required this.berberler, this.tel, this.ad});

  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = "")];
  @override
  Widget? buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  @override
  Widget buildResults(BuildContext context) => _sonuclar();
  @override
  Widget buildSuggestions(BuildContext context) => _sonuclar();

  Widget _sonuclar() {
    final list = berberler.where((b) => (b['isim'] ?? "").toLowerCase().contains(query.toLowerCase())).toList();
    return Container(
      color: const Color(0xFF0F111A),
      child: ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, index) => _NormalSalonKarti(berber: list[index], tel: tel, ad: ad),
      ),
    );
  }
}

class _TopSalonKarti extends StatelessWidget {
  final Map<String, dynamic> berber;
  final String? tel;
  final String? ad;
  const _TopSalonKarti({required this.berber, this.tel, this.ad});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RandevuDetayEkrani(berber: berber, musteriTelefon: tel, userName: ad))),
      child: Container(
        width: 240,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: const Color(0xFF161925), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white10)),
        child: Column(
          children: [
            Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), child: Image.network(berber['resim'] ?? "https://i.pravatar.cc/300", fit: BoxFit.cover, width: double.infinity))),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(berber['isim'] ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1),
                  const SizedBox(height: 5),
                  Row(children: [const Icon(Icons.star_rounded, color: Colors.amber, size: 16), Text(" ${berber['puan'] ?? '0.0'}", style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))]),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _NormalSalonKarti extends StatelessWidget {
  final Map<String, dynamic> berber;
  final String? tel;
  final String? ad;
  const _NormalSalonKarti({required this.berber, this.tel, this.ad});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RandevuDetayEkrani(berber: berber, musteriTelefon: tel, userName: ad))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF161925), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
        child: Row(
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(berber['resim'] ?? "https://i.pravatar.cc/300", width: 60, height: 60, fit: BoxFit.cover)),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(berber['isim'] ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text("${berber['puan'] ?? '0.0'}", style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      Text(berber['sehir'] ?? "", style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 14),
          ],
        ),
      ),
    );
  }
}
