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
    {'id': -1, 'berberIsmi': 'Ahmet Usta', 'ustaIsmi': 'Ahmet Yılmaz', 'tarih': '15/10/2023', 'saat': '10:00', 'durum': 'Tamamlandı', 'oylandi': 0},
    {'id': -2, 'berberIsmi': 'Makas Show', 'ustaIsmi': 'Mehmet Demir', 'tarih': '02/11/2023', 'saat': '14:30', 'durum': 'Tamamlandı', 'oylandi': 1},
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

  void _siraliOyVer(Map<String, dynamic> r) {
    int salonPuani = 0;
    int ustaPuani = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("${r['berberIsmi']} Oylayın"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Salondan memnun kaldınız mı?"),
              const SizedBox(height: 20),
              _yildizSecici((p) => setS(() => salonPuani = p), salonPuani),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İPTAL")),
            ElevatedButton(
              onPressed: salonPuani == 0 ? null : () {
                Navigator.pop(context);
                _ustaOyPopup(r, (p) async {
                  ustaPuani = p;
                  // Veritabanında oylandı olarak işaretle
                  if (r['id'] > 0) {
                    await _dbService.randevuyuTamamlaVeOyla(r['id']);
                    setState(() {}); // Ekranı güncelle
                  } else {
                    // Örnek veri için basit bildirim
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Değerlendirmeniz kaydedildi. Teşekkürler!"))
                    );
                  }
                });
              }, 
              child: const Text("SONRAKİ: USTA OYLA")
            ),
          ],
        ),
      ),
    );
  }

  void _ustaOyPopup(Map<String, dynamic> r, Function(int) onFinish) {
    int puan = 0;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("${r['ustaIsmi']} Oylayın"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Ustanın hizmetinden memnun kaldınız mı?"),
              const SizedBox(height: 20),
              _yildizSecici((p) => setS(() => puan = p), puan),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: puan == 0 ? null : () {
                Navigator.pop(context);
                onFinish(puan);
              }, 
              child: const Text("OYLAMAYI TAMAMLA")
            ),
          ],
        ),
      ),
    );
  }

  Widget _yildizSecici(Function(int) onSelect, int puan) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) => IconButton(
        icon: Icon(
          index < puan ? Icons.star_rounded : Icons.star_outline_rounded,
          color: Colors.amber,
          size: 32,
        ),
        onPressed: () => onSelect(index + 1),
      )),
    );
  }

  Widget _randevuKarti(Map<String, dynamic> r, {required bool isAktif}) {
    final colorScheme = Theme.of(context).colorScheme;
    bool oylandi = r['oylandi'] == 1;

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
                  decoration: BoxDecoration(
                    color: oylandi ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Text(
                    oylandi ? "Değerlendirildi" : "Bitti",
                    style: TextStyle(color: oylandi ? Colors.blue : Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          if (isAktif) ...[
            const Divider(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
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
          ],
          if (!isAktif) ...[
            const Divider(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: oylandi ? null : () => _siraliOyVer(r),
                icon: Icon(oylandi ? Icons.check_circle_outline : Icons.star_half_rounded, size: 18),
                label: Text(oylandi ? "TEŞEKKÜRLER" : "DEĞERLENDİR"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: oylandi ? Colors.grey[200] : Colors.amber,
                  foregroundColor: oylandi ? Colors.grey : Colors.black87,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: oylandi ? 0 : 2,
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
