import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  Future<Map<String, List<Map<String, dynamic>>>> _getEnIyiler() async {
    try {
      final salonlarRes = await http.get(Uri.parse('http://10.0.2.2:3000/api/salonlar'));
      final ustalarRes = await http.get(Uri.parse('http://10.0.2.2:3000/api/ustalar'));

      if (salonlarRes.statusCode == 200 && ustalarRes.statusCode == 200) {
        List<Map<String, dynamic>> salonlar = List<Map<String, dynamic>>.from(json.decode(salonlarRes.body));
        List<Map<String, dynamic>> ustalar = List<Map<String, dynamic>>.from(json.decode(ustalarRes.body));

        // Puanlara göre sıralayıp en iyileri alalım (Örnek mantık)
        salonlar.sort((a, b) => (double.tryParse(b['puan']?.toString() ?? "0") ?? 0)
            .compareTo(double.tryParse(a['puan']?.toString() ?? "0") ?? 0));
        
        ustalar.sort((a, b) => (double.tryParse(b['puan']?.toString() ?? "0") ?? 0)
            .compareTo(double.tryParse(a['puan']?.toString() ?? "0") ?? 0));

        return {
          'salonlar': salonlar.take(5).toList(),
          'ustalar': ustalar.take(10).toList(),
        };
      }
    } catch (e) {
      debugPrint("API Baglanti Hatasi: $e");
    }
    return {'salonlar': [], 'ustalar': []};
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: _getEnIyiler(),
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
                        colors: [colorScheme.primary.withOpacity(0.05), Colors.white],
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
                          child: Text("Henüz kayıtlı salon bulunmuyor."),
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
                          Icon(Icons.stars_rounded, color: Color(0xFF38BDF8), size: 28),
                          SizedBox(width: 10),
                          Text("En İyi Ustalar", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 15),
                      if (enIyiUstalar.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text("Henüz kayıtlı usta bulunmuyor."),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: enIyiUstalar.length,
                          itemBuilder: (context, index) => _ustaKarti(context, enIyiUstalar[index], enIyiSalonlar),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
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
                    Text(s['isim'] ?? 'Salon', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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

  Widget _ustaKarti(BuildContext context, Map<String, dynamic> u, List<Map<String, dynamic>> enIyiSalonlar) {
    return GestureDetector(
      onTap: () => _ustaBilgiPopup(context, u, enIyiSalonlar),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 35, 
                  backgroundImage: NetworkImage(u['resim'] ?? 'https://i.pravatar.cc/150?u=1')
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                    child: const Icon(Icons.workspace_premium_rounded, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u['isim'] ?? 'Usta', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 4),
                  Text(u['salon'] ?? 'Salon', style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500)),
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
                  Text(u['puan']?.toString() ?? "0.0", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _ustaBilgiPopup(BuildContext context, Map<String, dynamic> u, List<Map<String, dynamic>> allSalonlar) {
    final DatabaseService dbService = DatabaseService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 30),
            CircleAvatar(radius: 55, backgroundImage: NetworkImage(u['resim'] ?? 'https://i.pravatar.cc/150?u=1')),
            const SizedBox(height: 16),
            Text(u['isim'] ?? 'Usta', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(u['salon'] ?? 'Salon', style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                double p = double.tryParse(u['puan']?.toString() ?? "0") ?? 0;
                return Icon(
                  Icons.star_rounded, 
                  color: i < p.floor() ? Colors.amber : Colors.grey[300], 
                  size: 28
                );
              }),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Müşteri Deneyimleri", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: dbService.ustaYorumlariniGetir(u['isim'] ?? ""),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                          
                          final yorumlar = snapshot.data ?? [];
                          
                          if (yorumlar.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[300]),
                                  const SizedBox(height: 12),
                                  Text("Henüz yorum yapılmamış.", style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500)),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: yorumlar.length,
                            itemBuilder: (context, index) {
                              final y = yorumlar[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50], 
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.grey[100]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(y['musteriAd'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        Row(
                                          children: List.generate(5, (i) => Icon(
                                            Icons.star_rounded, 
                                            color: i < y['puan'] ? Colors.amber : Colors.grey[300], 
                                            size: 14
                                          )),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(y['yorumMetni'], style: const TextStyle(color: Colors.black87, height: 1.4)),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Salon bilgisini bulmaya çalış
                  final salon = allSalonlar.firstWhere(
                    (s) => s['isim'] == u['salon'], 
                    orElse: () => {
                      'id': u['salonId'],
                      'isim': u['salon'], 
                      'puan': u['puan'], 
                      'resim': 'https://images.pexels.com/photos/1319460/pexels-photo-1319460.jpeg?auto=compress&cs=tinysrgb&w=400'
                    }
                  );
                  Navigator.push(context, MaterialPageRoute(builder: (context) => RandevuDetayEkrani(berber: salon, musteriTelefon: widget.musteriTelefon, userName: widget.userName)));
                },
                child: const Text("USTADAN RANDEVU AL"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
