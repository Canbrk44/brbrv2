import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import 'randevu_detay_ekrani.dart';
import 'usta_detay_ekrani.dart';

class EnIyilerEkrani extends StatefulWidget {
  final String? musteriTelefon;
  final String? userName;

  const EnIyilerEkrani({super.key, this.musteriTelefon, this.userName});

  @override
  State<EnIyilerEkrani> createState() => _EnIyilerEkraniState();
}

class _EnIyilerEkraniState extends State<EnIyilerEkrani> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, List<Map<String, dynamic>>>> _getEnIyilerFirebase() async {
    try {
      final salonlarSnapshot = await _firestore
          .collection('salonlar')
          .where('puan', isGreaterThanOrEqualTo: 4.0)
          .orderBy('puan', descending: true)
          .limit(10)
          .get();

      List<Map<String, dynamic>> enIyiSalonlar = salonlarSnapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      final tumSalonlarSnapshot = await _firestore.collection('salonlar').get();
      List<Map<String, dynamic>> enIyiUstalar = [];

      for (var doc in tumSalonlarSnapshot.docs) {
        var salonData = doc.data();
        List ustalar = salonData['ustalar'] ?? [];
        for (var u in ustalar) {
          if (u is Map) {
            Map<String, dynamic> ustaWithSalon = Map<String, dynamic>.from(u);
            ustaWithSalon['salon'] = salonData['isim'];
            ustaWithSalon['salonId'] = doc.id;
            enIyiUstalar.add(ustaWithSalon);
          }
        }
      }

      enIyiUstalar.sort((a, b) => (double.tryParse(b['puan']?.toString() ?? "0") ?? 0)
          .compareTo(double.tryParse(a['puan']?.toString() ?? "0") ?? 0));

      return {
        'salonlar': enIyiSalonlar,
        'ustalar': enIyiUstalar.take(15).toList(),
      };
    } catch (e) {
      debugPrint("Hata: $e");
      return {'salonlar': [], 'ustalar': []};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: _getEnIyilerFirebase(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? {'salonlar': [], 'ustalar': []};
          final salonlar = data['salonlar']!;
          final ustalar = data['ustalar']!;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 250.0,
                pinned: true,
                backgroundColor: const Color(0xFF4E342E),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: const Text(
                    "En İyiler", 
                    style: TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 10)]
                    )
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        'https://images.pexels.com/photos/1319461/pexels-photo-1319461.jpeg', 
                        fit: BoxFit.cover
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Baslik(yazi: "En İyi Salonlar"),
                      const SizedBox(height: 15),
                      SizedBox(
                        height: 280,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: salonlar.length,
                          itemBuilder: (context, index) => _SalonCard(s: salonlar[index], tel: widget.musteriTelefon, ad: widget.userName),
                        ),
                      ),
                      const SizedBox(height: 40),
                      const _Baslik(yazi: "En İyi Ustalar"),
                      const SizedBox(height: 15),
                      ...ustalar.map((u) => _UstaCard(u: u)),
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

class _Baslik extends StatelessWidget {
  final String yazi;
  const _Baslik({required this.yazi});
  @override
  Widget build(BuildContext context) {
    return Text(yazi, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -1));
  }
}

class _SalonCard extends StatelessWidget {
  final Map<String, dynamic> s;
  final String? tel;
  final String? ad;
  const _SalonCard({required this.s, this.tel, this.ad});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RandevuDetayEkrani(berber: s, musteriTelefon: tel, userName: ad))),
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 20, bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 10))],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: Image.network(
                  s['resim'] ?? 'https://images.pexels.com/photos/3993323/pexels-photo-3993323.jpeg', 
                  fit: BoxFit.cover, 
                  width: double.infinity,
                  errorBuilder: (c, e, s) => Container(color: Colors.grey[200], child: const Icon(Icons.image)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Text(s['isim'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, 
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 18), 
                      Text(" ${s['puan'] ?? '0.0'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))
                    ]
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _UstaCard extends StatelessWidget {
  final Map<String, dynamic> u;
  const _UstaCard({required this.u});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => UstaDetayEkrani(usta: u, salonIsmi: u['salon'] ?? ""))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(22), 
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32, 
              backgroundImage: NetworkImage(u['resim'] ?? 'https://i.pravatar.cc/150?u=${u['isim']}')
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text(u['isim'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), 
                  Text(u['salon'] ?? "", style: TextStyle(color: Colors.grey[500], fontSize: 12))
                ]
              )
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), 
              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), 
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16), 
                  Text(" ${u['puan'] ?? '0.0'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber))
                ]
              )
            ),
          ],
        ),
      ),
    );
  }
}
