import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import 'sms_onay_ekrani.dart';

class RandevularEkrani extends StatefulWidget {
  final String? musteriTelefon;
  const RandevularEkrani({super.key, this.musteriTelefon});

  @override
  State<RandevularEkrani> createState() => _RandevularEkraniState();
}

class _RandevularEkraniState extends State<RandevularEkrani> {
  final DatabaseService _dbService = DatabaseService();
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  void _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserName = prefs.getString('user_name');
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isGuest = widget.musteriTelefon == null || widget.musteriTelefon!.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E6),
      appBar: AppBar(title: const Text("Randevularım"), elevation: 0),
      body: isGuest 
      ? _ziyaretciGorunumu(context)
      : RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _dbService.musterininRandevulariniGetir(widget.musteriTelefon!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return const Center(child: Text("Veriler yüklenirken bir hata oluştu."));

              final all = snapshot.data ?? [];
              if (all.isEmpty) return const Center(child: Text("Henüz randevunuz yok."));

              final aktif = all.where((r) => (r['durum'] ?? 'aktif') == 'aktif').toList();
              final gecmis = all.where((r) => (r['durum'] ?? 'aktif') != 'aktif').toList();

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (aktif.isNotEmpty) ...[
                    const Text("Aktif Randevular", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ...aktif.map((r) => _randevuKarti(r, true)),
                  ],
                  if (gecmis.isNotEmpty) ...[
                    const SizedBox(height: 25),
                    const Text("Geçmiş Randevular", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 10),
                    ...gecmis.map((r) => _randevuKarti(r, false)),
                  ],
                ],
              );
            },
          ),
        ),
    );
  }

  Widget _randevuKarti(Map<String, dynamic> r, bool isAktif) {
    bool oylandi = (r['oylandi'] ?? 0) == 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        title: Text(r['berberIsmi'] ?? "Salon", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${r['ustaIsmi'] ?? 'Usta'}\n${r['tarih'] ?? ''} - ${r['saat'] ?? ''}"),
        trailing: isAktif 
          ? ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700], 
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(70, 35),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _trendyolOylamaPopup(r),
              child: const Text("TAMAMLA", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            )
          : ElevatedButton(
              onPressed: oylandi ? null : () => _trendyolOylamaPopup(r),
              style: ElevatedButton.styleFrom(
                backgroundColor: oylandi ? Colors.grey[300] : const Color(0xFF4E342E), 
                foregroundColor: oylandi ? Colors.grey[600] : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(70, 35),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(oylandi ? "OYLANDI" : "OYLA", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
      ),
    );
  }

  void _trendyolOylamaPopup(Map<String, dynamic> r) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        int step = 1;
        double sP = 0, uP = 0;
        final sC = TextEditingController(), uC = TextEditingController();

        return StatefulBuilder(
          builder: (context, setS) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(step == 1 ? "Salonu Puanla" : "Ustayı Puanla", textAlign: TextAlign.center),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(step == 1 ? "${r['berberIsmi']} hizmeti?" : "${r['ustaIsmi']} becerisi?", style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) => IconButton(
                      icon: Icon(i < (step == 1 ? sP : uP) ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 35),
                      onPressed: () => setS(() => step == 1 ? sP = i + 1.0 : uP = i + 1.0),
                    )),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: step == 1 ? sC : uC,
                    maxLines: 2,
                    decoration: InputDecoration(hintText: "Yorumunuz...", filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
              ElevatedButton(
                onPressed: (step == 1 ? sP : uP) == 0 ? null : () async {
                  if (step == 1) {
                    setS(() => step = 2);
                  } else {
                    await _dbService.yorumKaydet(
                      randevuId: r['id'] ?? "",
                      ustaIsmi: r['ustaIsmi'] ?? "",
                      salonIsmi: r['berberIsmi'] ?? "",
                      musteriAd: _currentUserName ?? "Müşteri",
                      salonPuan: sP,
                      salonYorum: sC.text,
                      ustaPuan: uP,
                      ustaYorum: uC.text,
                    );
                    if (context.mounted) Navigator.pop(context);
                    setState(() {});
                  }
                },
                child: Text(step == 1 ? "SONRAKİ" : "GÖNDER"),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _ziyaretciGorunumu(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.lock_person_outlined, size: 80, color: Colors.grey), const SizedBox(height: 20), const Text("Randevularınızı görmek için giriş yapın."), const SizedBox(height: 30), ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/giris'), child: const Text("GİRİŞ YAP"))]));
  }
}
