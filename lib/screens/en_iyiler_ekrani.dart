import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import 'randevu_detay_ekrani.dart';

class EnIyilerEkrani extends StatefulWidget {
  final String? musteriTelefon;
  final String? userName;

  const EnIyilerEkrani({super.key, this.musteriTelefon, this.userName});

  @override
  State<EnIyilerEkrani> createState() => _EnIyilerEkraniState();
}

class _EnIyilerEkraniState extends State<EnIyilerEkrani> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firebase'den En İyi Salonları ve Ustaları Çekelim
  Future<Map<String, List<Map<String, dynamic>>>> _getEnIyilerFirebase() async {
    try {
      // 1. En İyi Salonları Getir (Puanı 4.5 ve üzeri olanlar)
      final salonlarSnapshot = await _firestore
          .collection('salonlar')
          .where('puan', isGreaterThanOrEqualTo: 4.5)
          .orderBy('puan', descending: true)
          .limit(5)
          .get();

      List<Map<String, dynamic>> enIyiSalonlar = salonlarSnapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // 2. Ustaları Getir (Salonların içindeki ustaları harmanlayalım)
      // Bu örnekte tüm salonlardaki ustaları çekip puanına göre sıralıyoruz
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
            ustaWithSalon['resim'] = ustaWithSalon['resim'] ?? 'https://i.pravatar.cc/150?u=${u['isim']}';
            enIyiUstalar.add(ustaWithSalon);
          }
        }
      }

      // Ustaları puana göre sırala (Eğer puan varsa)
      enIyiUstalar.sort((a, b) => (double.tryParse(b['puan']?.toString() ?? "0") ?? 0)
          .compareTo(double.tryParse(a['puan']?.toString() ?? "0") ?? 0));

      return {
        'salonlar': enIyiSalonlar,
        'ustalar': enIyiUstalar.take(10).toList(),
      };
    } catch (e) {
      debugPrint("Firebase Veri Çekme Hatası: $e");
      return {'salonlar': [], 'ustalar': []};
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: _getEnIyilerFirebase(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? {'salonlar': [], 'ustalar': []};
          final enIyiSalonlar = data['salonlar']!;
          final enIyiUstalar = data['ustalar']!;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120.0,
                floating: true,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text("En İyiler", style: TextStyle(fontWeight: FontWeight.bold)),
                  centerTitle: true,
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [theme.primaryColor.withOpacity(0.05), Colors.white],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Row(
                        children: [
                          Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 28),
                          SizedBox(width: 10),
                          Text("En İyi Salonlar", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 15),
                      if (enIyiSalonlar.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text("Yüksek puanlı salon bulunamadı."),
                        )
                      else
                        SizedBox(
                          height: 240,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: enIyiSalonlar.length,
                            itemBuilder: (context, index) => _salonKarti(context, enIyiSalonlar[index]),
                          ),
                        ),
                      const SizedBox(height: 40),
                      const Row(
                        children: [
                          Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
                          SizedBox(width: 10),
                          Text("En İyi Ustalar", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 15),
                      if (enIyiUstalar.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text("Kayıtlı usta bulunamadı."),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: enIyiUstalar.length,
                          itemBuilder: (context, index) => _ustaKarti(context, enIyiUstalar[index]),
                        ),
                      const SizedBox(height: 40),
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

  Widget _salonKarti(BuildContext context, Map<String, dynamic> s) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(
          builder: (context) => RandevuDetayEkrani(
            berber: s, 
            musteriTelefon: widget.musteriTelefon, 
            userName: widget.userName
          )
        )
      ),
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 16, bottom: 10, top: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  image: DecorationImage(
                    image: NetworkImage(s['resim'] ?? 'https://images.pexels.com/photos/3993323/pexels-photo-3993323.jpeg'), 
                    fit: BoxFit.cover
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(s['isim'] ?? 'Salon', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(s['puan']?.toString() ?? "0.0", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _ustaKarti(BuildContext context, Map<String, dynamic> u) {
    return GestureDetector(
      onTap: () => _ustaBilgiPopup(context, u),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12)],
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35, 
              backgroundImage: NetworkImage(u['resim'] ?? 'https://i.pravatar.cc/150?u=${u['isim']}')
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u['isim'] ?? 'Usta', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 4),
                  Text(u['salon'] ?? 'Salon', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(u['puan']?.toString() ?? "5.0", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _ustaBilgiPopup(BuildContext context, Map<String, dynamic> u) {
    final DatabaseService dbService = DatabaseService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 30),
            CircleAvatar(radius: 55, backgroundImage: NetworkImage(u['resim'] ?? 'https://i.pravatar.cc/150?u=${u['isim']}')),
            const SizedBox(height: 16),
            Text(u['isim'] ?? 'Usta', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(u['salon'] ?? 'Salon', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 40),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Text("Bu ustanın çalıştığı salona giderek randevu alabilirsiniz.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Salon dökümanını Firebase'den çekelim
                  final salonDoc = await _firestore.collection('salonlar').doc(u['salonId']).get();
                  if (salonDoc.exists) {
                    var salonData = salonDoc.data()!;
                    salonData['id'] = salonDoc.id;
                    if (!mounted) return;
                    Navigator.push(context, MaterialPageRoute(builder: (context) => RandevuDetayEkrani(berber: salonData, musteriTelefon: widget.musteriTelefon, userName: widget.userName)));
                  }
                },
                child: const Text("SALONA GİT VE RANDEVU AL"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
