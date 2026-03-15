import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../main.dart';
import 'package:intl/intl.dart';

class UstaDetayEkrani extends StatelessWidget {
  final Map<String, dynamic> usta;
  final String salonIsmi;

  const UstaDetayEkrani({super.key, required this.usta, required this.salonIsmi});

  @override
  Widget build(BuildContext context) {
    final DatabaseService db = DatabaseService();
    final String ustaAdi = usta['isim'] ?? "";

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Usta Profili", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: GradientBackground(
        accentColor: const Color(0xFFE91E63),
        child: SizedBox.expand(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [
                const SizedBox(height: kToolbarHeight + 40),
                _ustaProfilKarti(ustaAdi),
                const SizedBox(height: 40),
                _yorumlarBaslik(),
                const SizedBox(height: 20),
                _yorumlarListesi(db, ustaAdi),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ustaProfilKarti(String ustaAdi) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFF161925),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 65,
            backgroundColor: Colors.white.withOpacity(0.05),
            backgroundImage: NetworkImage(usta['resim'] ?? 'https://i.pravatar.cc/150?u=$ustaAdi'),
          ),
          const SizedBox(height: 20),
          Text(ustaAdi, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(salonIsmi, style: const TextStyle(color: Colors.white38, fontSize: 14)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                Text("${usta['puan']?.toString() ?? '0.0'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.amber)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _yorumlarBaslik() {
    return const Row(
      children: [
        Icon(Icons.comment_rounded, color: Color(0xFFE91E63), size: 20),
        SizedBox(width: 12),
        Text("Usta Hakkında Yorumlar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _yorumlarListesi(DatabaseService db, String ustaAdi) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: db.ustaYorumlariniGetir(ustaAdi),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)));
        
        final allYorumlar = snapshot.data ?? [];
        final yorumlar = allYorumlar.where((y) => y['salonIsmi'] == salonIsmi).toList();

        if (yorumlar.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Henüz yorum yapılmamış.", style: TextStyle(color: Colors.white24))));
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: yorumlar.length,
          itemBuilder: (context, index) {
            final y = yorumlar[index];
            final double puan = double.tryParse(y['ustaPuan']?.toString() ?? '0') ?? 0;
            final String tarih = y['tarih'] != null ? DateFormat('dd MMM yyyy').format(y['tarih'].toDate()) : "";

            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF161925),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(y['musteriAd'] ?? "Misafir", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                      Text(tarih, style: const TextStyle(color: Colors.white24, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(children: List.generate(5, (i) => Icon(Icons.star_rounded, size: 14, color: i < puan.toInt() ? Colors.amber : Colors.white12))),
                  const SizedBox(height: 12),
                  Text(y['ustaYorum'] ?? "", style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.5)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
