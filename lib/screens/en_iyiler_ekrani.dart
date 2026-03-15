import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'randevu_detay_ekrani.dart';
import 'usta_detay_ekrani.dart';

class EnIyilerEkrani extends StatefulWidget {
  final String? musteriTelefon;
  final String? userName;

  const EnIyilerEkrani({super.key, this.musteriTelefon, this.userName});

  @override
  State<EnIyilerEkrani> createState() => _EnIyilerEkraniState();
}

class _EnIyilerEkraniState extends State<EnIyilerEkrani> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<Map<String, List<Map<String, dynamic>>>> _getEnIyilerFirebase() async {
    try {
      final salonlarSnapshot = await _firestore.collection('salonlar').orderBy('puan', descending: true).limit(10).get();
      List<Map<String, dynamic>> enIyiSalonlar = salonlarSnapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();

      final tumSalonlarSnapshot = await _firestore.collection('salonlar').get();
      List<Map<String, dynamic>> ustalar = [];
      for (var doc in tumSalonlarSnapshot.docs) {
        var salonData = doc.data();
        List uList = salonData['ustalar'] ?? [];
        for (var u in uList) {
          if (u is Map) {
            Map<String, dynamic> uData = Map<String, dynamic>.from(u);
            uData['salon'] = salonData['isim'];
            uData['salonId'] = doc.id;
            // Sadece 3.5 puan ve üzerini alıyoruz
            if ((double.tryParse(uData['puan']?.toString() ?? '0') ?? 0) >= 3.5) {
              ustalar.add(uData);
            }
          }
        }
      }
      ustalar.sort((a, b) => (double.tryParse(b['puan']?.toString() ?? '0') ?? 0).compareTo(double.tryParse(a['puan']?.toString() ?? '0') ?? 0));

      return {'salonlar': enIyiSalonlar, 'ustalar': ustalar};
    } catch (e) { return {'salonlar': [], 'ustalar': []}; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: _getEnIyilerFirebase(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF2196F3)));
          final data = snapshot.data ?? {'salonlar': [], 'ustalar': []};
          final salonlar = data['salonlar']!;
          final ustalar = data['ustalar']!;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                title: Text("Yıldızlar Geçidi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 30),
                      _Baslik(yazi: "Lider Salonlar", renk: const Color(0xFF2196F3)),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 220,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: salonlar.length,
                          itemBuilder: (context, index) => _SalonKarti(s: salonlar[index], tel: widget.musteriTelefon, ad: widget.userName),
                        ),
                      ),
                      const SizedBox(height: 40),
                      _Baslik(yazi: "Usta Eller", renk: const Color(0xFF2196F3)),
                      const SizedBox(height: 20),
                      ...List.generate(ustalar.length, (index) => _UstaKartiMedal(u: ustalar[index], rank: index + 1, glow: _glowController)),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _UstaKartiMedal extends StatelessWidget {
  final Map<String, dynamic> u;
  final int rank;
  final AnimationController glow;

  const _UstaKartiMedal({required this.u, required this.rank, required this.glow});

  @override
  Widget build(BuildContext context) {
    Color medalColor;
    IconData medalIcon = Icons.emoji_events;
    if (rank == 1) medalColor = Colors.amber;
    else if (rank == 2) medalColor = const Color(0xFFC0C0C0);
    else if (rank == 3) medalColor = const Color(0xFFCD7F32);
    else { medalColor = Colors.transparent; medalIcon = Icons.star_border; }

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => UstaDetayEkrani(usta: u, salonIsmi: u['salon'] ?? ""))),
      child: AnimatedBuilder(
        animation: glow,
        builder: (context, child) => Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF161925),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: rank == 1 ? medalColor.withOpacity(0.5 + 0.5 * glow.value) : Colors.white10, width: rank == 1 ? 2 : 1),
            boxShadow: rank == 1 ? [BoxShadow(color: medalColor.withOpacity(0.2 * glow.value), blurRadius: 10)] : null,
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(radius: 30, backgroundImage: NetworkImage(u['resim'] ?? 'https://i.pravatar.cc/150')),
                  if (rank <= 3) 
                    Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: medalColor, shape: BoxShape.circle), child: Icon(medalIcon, color: Colors.white, size: 12)),
                ],
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u['isim'] ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(u['salon'] ?? "", style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
              Text("${u['puan']}", style: TextStyle(color: medalColor != Colors.transparent ? medalColor : Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Baslik extends StatelessWidget {
  final String yazi;
  final Color renk;
  const _Baslik({required this.yazi, required this.renk});
  @override
  Widget build(BuildContext context) {
    return Row(children: [Container(width: 4, height: 20, decoration: BoxDecoration(color: renk, borderRadius: BorderRadius.circular(10))), const SizedBox(width: 10), Text(yazi, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))]);
  }
}

class _SalonKarti extends StatelessWidget {
  final Map<String, dynamic> s;
  final String? tel;
  final String? ad;
  const _SalonKarti({required this.s, this.tel, this.ad});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RandevuDetayEkrani(berber: s, musteriTelefon: tel, userName: ad))),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 15, bottom: 5),
        decoration: BoxDecoration(color: const Color(0xFF161925), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white10)),
        child: Column(
          children: [
            Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(25)), child: Image.network(s['resim'] ?? "https://i.pravatar.cc/300", fit: BoxFit.cover, width: double.infinity))),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(s['isim'] ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.star_rounded, color: Colors.amber, size: 14), Text(" ${s['puan'] ?? '0.0'}", style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11))]),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
