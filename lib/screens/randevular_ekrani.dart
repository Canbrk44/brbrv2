import 'package:flutter/material.dart';
import '../services/database_service.dart';

class RandevularEkrani extends StatefulWidget {
  final String? musteriTelefon;
  const RandevularEkrani({super.key, this.musteriTelefon});

  @override
  State<RandevularEkrani> createState() => _RandevularEkraniState();
}

class _RandevularEkraniState extends State<RandevularEkrani> {
  final DatabaseService _dbService = DatabaseService();
  
  final List<Map<String, dynamic>> _eskiRandevular = [
    {'berberIsmi': 'Ahmet Usta', 'ustaIsmi': 'Ahmet Yılmaz', 'tarih': '15/10/2023', 'saat': '10:00', 'durum': 'Tamamlandı'},
    {'berberIsmi': 'Makas Show', 'ustaIsmi': 'Mehmet Demir', 'tarih': '02/11/2023', 'saat': '14:30', 'durum': 'Tamamlandı'},
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Randevularım")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _dbService.musterininRandevulariniGetir(widget.musteriTelefon ?? "Misafir"),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final aktifRandevular = snapshot.data ?? [];

          if (aktifRandevular.isEmpty && _eskiRandevular.isEmpty) {
            return const Center(child: Text("Henüz bir randevunuz bulunmuyor."));
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (aktifRandevular.isNotEmpty) ...[
                const Text("Aktif Randevular", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                ...aktifRandevular.map((r) => _randevuKarti(r, isAktif: true)),
                const SizedBox(height: 30),
              ],
              const Text("Geçmiş Randevular", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              ..._eskiRandevular.map((r) => _randevuKarti(r, isAktif: false)),
            ],
          );
        },
      ),
    );
  }

  Widget _randevuKarti(Map<String, dynamic> r, {required bool isAktif}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: isAktif ? colorScheme.primary.withOpacity(0.05) : Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                child: Icon(isAktif ? Icons.event_available : Icons.history, color: isAktif ? colorScheme.primary : Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r['berberIsmi'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("Usta: ${r['ustaIsmi']}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    const SizedBox(height: 4),
                    Text("${r['tarih']} - ${r['saat']}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              if (!isAktif)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text("Bitti", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          if (isAktif) ...[
            const Divider(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Harita uygulamasına yönlendirme simülasyonu
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harita uygulamasına yönlendiriliyorsunuz...")));
                },
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text("KONUMA GİT"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(color: colorScheme.primary.withOpacity(0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
