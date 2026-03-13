import 'package:flutter/material.dart';
import 'profil_ekrani.dart';
import 'randevular_ekrani.dart';
import 'randevu_detay_ekrani.dart';
import 'en_iyiler_ekrani.dart';
import 'salon_giris_ekrani.dart';
import 'usta_detay_ekrani.dart';
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
        onCityTap: _sehirSecimiGoster,
      ),
      EnIyilerEkrani(musteriTelefon: widget.phoneNumber, userName: widget.userName),
      RandevularEkrani(musteriTelefon: widget.phoneNumber),
      ProfilEkrani(isGuest: widget.isGuest, phoneNumber: widget.phoneNumber, userName: widget.userName),
    ];
  }

  void _sehirSecimiGoster() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF0F2F5),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text("Şehir Seçin", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF4E342E)),
        title: Text(sehir, style: const TextStyle(fontWeight: FontWeight.w500)),
        onTap: () {
          setState(() {
            _seciliSehir = sehir;
            _guncelleSayfalar();
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: IndexedStack(
        index: _seciliIndex,
        children: _sayfalar,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30)],
        ),
        child: BottomNavigationBar(
          currentIndex: _seciliIndex,
          onTap: (index) => setState(() => _seciliIndex = index),
          selectedItemColor: const Color(0xFF4E342E),
          unselectedItemColor: Colors.grey[400],
          showSelectedLabels: true,
          elevation: 0,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
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
}

class AnaSayfaIcerik extends StatefulWidget {
  final String? musteriTelefon;
  final String? userName;
  final String seciliSehir;
  final VoidCallback onCityTap;

  const AnaSayfaIcerik({
    super.key, 
    this.musteriTelefon, 
    this.userName, 
    required this.seciliSehir,
    required this.onCityTap
  });

  @override
  State<AnaSayfaIcerik> createState() => _AnaSayfaIcerikState();
}

class _AnaSayfaIcerikState extends State<AnaSayfaIcerik> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  static const String defaultSalonImg = "https://images.pexels.com/photos/1319461/pexels-photo-1319461.jpeg";

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DatabaseService db = DatabaseService();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: db.salonlariGetir(widget.seciliSehir),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final berberler = snapshot.data ?? [];
        final topBerberler = berberler.where((b) => (double.tryParse(b['puan']?.toString() ?? '0') ?? 0) >= 4.0).toList();
        
        List<Map<String, dynamic>> ustalar = [];
        for (var b in berberler) {
          List uList = b['ustalar'] ?? [];
          for (var u in uList) {
            if (u is Map) {
              Map<String, dynamic> uData = Map<String, dynamic>.from(u);
              uData['salon'] = b['isim'];
              ustalar.add(uData);
            }
          }
        }
        ustalar.sort((a, b) => (double.tryParse(b['puan']?.toString() ?? '0') ?? 0).compareTo(double.tryParse(a['puan']?.toString() ?? '0') ?? 0));
        final topUstalar = ustalar.take(10).toList();

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: const Color(0xFFF0F2F5),
              elevation: 0,
              toolbarHeight: 100,
              title: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Merhaba, ${widget.userName?.split(' ')[0] ?? 'Misafir'} 👋", 
                      style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w400)),
                    const Text("Bugün tarzını yenile!", 
                      style: TextStyle(color: Color(0xFF4E342E), fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(top: 20, right: 10),
                  child: IconButton(
                    icon: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.storefront, color: Color(0xFF4E342E), size: 18)),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SalonGirisEkrani())),
                  ),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                child: GestureDetector(
                  onTap: widget.onCityTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFF4E342E), size: 20),
                        const SizedBox(width: 12),
                        Text(widget.seciliSehir, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const Spacer(),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            if (topBerberler.isNotEmpty) ...[
              const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(25, 30, 25, 15), child: Text("Öne Çıkan Salonlar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 250,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    scrollDirection: Axis.horizontal,
                    itemCount: topBerberler.length,
                    itemBuilder: (context, index) => _TopSalonKarti(berber: topBerberler[index], tel: widget.musteriTelefon, ad: widget.userName),
                  ),
                ),
              ),
            ],

            if (topUstalar.isNotEmpty) ...[
              const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(25, 35, 25, 10), child: Text("Yıldız Ustalar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 120,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    scrollDirection: Axis.horizontal,
                    itemCount: topUstalar.length,
                    itemBuilder: (context, index) => _UstaAvatarKarti(
                      usta: topUstalar[index], 
                      isTop: index == 0,
                      glowAnimation: _glowController,
                    ),
                  ),
                ),
              ),
            ],

            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(25, 35, 25, 15), child: Text("Yakındaki Tüm Salonlar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _NormalSalonKarti(berber: berberler[index], tel: widget.musteriTelefon, ad: widget.userName),
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

  static Widget _resimKontrol(String? url) {
    if (url == null || url.isEmpty || !url.startsWith('http')) url = defaultSalonImg;
    return Image.network(url, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Image.network(defaultSalonImg, fit: BoxFit.cover));
  }
}

class _UstaAvatarKarti extends StatelessWidget {
  final Map<String, dynamic> usta;
  final bool isTop;
  final Animation<double>? glowAnimation;

  const _UstaAvatarKarti({required this.usta, this.isTop = false, this.glowAnimation});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => UstaDetayEkrani(usta: usta, salonIsmi: usta['salon'] ?? ""))),
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                if (isTop) 
                  AnimatedBuilder(
                    animation: glowAnimation!,
                    builder: (context, child) => Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.6 * glowAnimation!.value),
                            blurRadius: 10 * glowAnimation!.value,
                            spreadRadius: 2 * glowAnimation!.value,
                          )
                        ],
                        border: Border.all(color: Colors.amber, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundImage: NetworkImage(usta['resim'] ?? 'https://i.pravatar.cc/150?u=${usta['isim']}'),
                      ),
                    ),
                  )
                else
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: NetworkImage(usta['resim'] ?? 'https://i.pravatar.cc/150?u=${usta['isim']}'),
                  ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(isTop ? Icons.emoji_events_rounded : Icons.star_rounded, color: Colors.amber, size: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(usta['isim']?.split(' ')[0] ?? "", style: TextStyle(fontSize: 12, fontWeight: isTop ? FontWeight.bold : FontWeight.normal), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
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
        width: 260,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10))]),
        child: Column(
          children: [
            Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), child: _AnaSayfaIcerikState._resimKontrol(berber['resim']))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(berber['isim'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                      Text(" ${berber['puan'] ?? '0.0'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(berber['sehir'] ?? "", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
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
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]),
        child: Row(
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(15), child: SizedBox(width: 80, height: 80, child: _AnaSayfaIcerikState._resimKontrol(berber['resim']))),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(berber['isim'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                      Text(" ${berber['puan'] ?? '0.0'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(width: 10),
                      Text(berber['sehir']?.split(',')[0] ?? "", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[300], size: 16),
          ],
        ),
      ),
    );
  }
}
