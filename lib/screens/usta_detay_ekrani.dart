import 'package:flutter/material.dart';
import '../services/database_service.dart';

class UstaDetayEkrani extends StatelessWidget {
  final Map<String, dynamic> usta;
  final String salonIsmi;

  const UstaDetayEkrani({super.key, required this.usta, required this.salonIsmi});

  @override
  Widget build(BuildContext context) {
    final DatabaseService db = DatabaseService();
    final String ustaAdi = usta['isim'] ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E6),
      appBar: AppBar(title: Text(ustaAdi), elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(usta['resim'] ?? 'https://i.pravatar.cc/150?u=$ustaAdi'),
                  ),
                  const SizedBox(height: 15),
                  Text(ustaAdi, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(salonIsmi, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                        Text(" ${usta['puan']?.toString() ?? '0.0'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Usta Hakkındaki Yorumlar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: db.ustaYorumlariniGetir(ustaAdi),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      
                      final allYorumlar = snapshot.data ?? [];
                      // Sadece bu salondaki bu ustaya ait yorumları süzüyoruz (garanti olsun diye)
                      final yorumlar = allYorumlar.where((y) => y['salonIsmi'] == salonIsmi).toList();

                      if (yorumlar.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Henüz bu usta için yorum yapılmamış.", textAlign: TextAlign.center)));
                      
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: yorumlar.length,
                        itemBuilder: (context, index) {
                          final y = yorumlar[index];
                          // Yıldız sayısını güvenli bir şekilde alalım
                          final double puan = double.tryParse(y['ustaPuan']?.toString() ?? '0') ?? 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(y['musteriAd'] ?? "Misafir", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Row(children: List.generate(5, (i) => Icon(
                                      Icons.star_rounded, 
                                      size: 16, 
                                      color: i < puan.toInt() ? Colors.amber : Colors.grey[300]
                                    ))),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(y['ustaYorum'] ?? "Yorum belirtilmedi.", style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                const SizedBox(height: 5),
                                Text(y['tarih'] != null ? "Tarih: ${y['tarih'].toDate().toString().split(' ')[0]}" : "", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
