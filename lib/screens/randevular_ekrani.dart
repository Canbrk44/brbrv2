import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';

class RandevularEkrani extends StatefulWidget {
  final String? musteriTelefon;
  const RandevularEkrani({super.key, this.musteriTelefon});

  @override
  State<RandevularEkrani> createState() => _RandevularEkraniState();
}

class _RandevularEkraniState extends State<RandevularEkrani> {
  final DatabaseService _dbService = DatabaseService();
  String? _currentUserName;
  
  // Örnek eski randevular (Misafir değilse gösterilecek)
  final List<Map<String, dynamic>> _eskiRandevular = [
    {'id': -1, 'berberIsmi': 'Ahmet Usta', 'ustaIsmi': 'Ahmet Yilmaz', 'tarih': '15/10/2023', 'saat': '10:00', 'durum': 'Tamamlandi', 'oylandi': 0},
    {'id': -2, 'berberIsmi': 'Makas Show', 'ustaIsmi': 'Mehmet Demir', 'tarih': '02/11/2023', 'saat': '14:30', 'durum': 'Tamamlandi', 'oylandi': 1},
  ];

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
    final colorScheme = Theme.of(context).colorScheme;
    final bool isGuest = widget.musteriTelefon == null;

    return Scaffold(
      appBar: AppBar(title: const Text("Randevularim")),
      body: isGuest 
      ? _ziyaretciGorunumu(context)
      : FutureBuilder<List<Map<String, dynamic>>>(
        future: _dbService.musterininRandevulariniGetir(widget.musteriTelefon!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final aktifRandevular = snapshot.data ?? [];

          if (aktifRandevular.isEmpty && _eskiRandevular.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  const Text("Henuz bir randevunuz bulunmuyor.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                ],
              ),
            );
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
              const Text("Gecmis Randevular", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              ..._eskiRandevular.map((r) => _randevuKarti(r, isAktif: false)),
            ],
          );
        },
      ),
    );
  }

  Widget _ziyaretciGorunumu(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 100, color: Colors.grey[300]),
            const SizedBox(height: 24),
            const Text(
              "Randevularinizi gormek icin lutfen giris yapin.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Profil sekmesine yonlendirilebilir veya giris ekrani acilabilir
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lutfen Profil sekmesinden giris yapin.")));
              },
              child: const Text("GIRIS YAP / KAYIT OL"),
            ),
          ],
        ),
      ),
    );
  }

  void _siraliOyVer(Map<String, dynamic> r) {
    int salonPuani = 0;
    final TextEditingController salonYorumC = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: Text("${r['berberIsmi']} Oylayin"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Salondan memnun kaldiniz mi?"),
                const SizedBox(height: 20),
                _yildizSecici((p) => setS(() => salonPuani = p), salonPuani),
                const SizedBox(height: 20),
                TextField(
                  controller: salonYorumC,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Deneyiminizi anlatin...",
                    fillColor: Colors.grey[100],
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("IPTAL")),
            ElevatedButton(
              onPressed: salonPuani == 0 ? null : () {
                Navigator.pop(context);
                _ustaOyVeYorumPopup(r, salonPuani, salonYorumC.text);
              }, 
              child: const Text("SONRAKI")
            ),
          ],
        ),
      ),
    );
  }

  void _ustaOyVeYorumPopup(Map<String, dynamic> r, int salonP, String salonYorum) {
    int ustaPuan = 0;
    final TextEditingController ustaYorumC = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: Text("${r['ustaIsmi']} Oylayin"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Ustanin hizmetinden memnun kaldiniz mi?"),
                const SizedBox(height: 20),
                _yildizSecici((p) => setS(() => ustaPuan = p), ustaPuan),
                const SizedBox(height: 20),
                TextField(
                  controller: ustaYorumC,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Usta hakkinda yorumunuz...",
                    fillColor: Colors.grey[100],
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: ustaPuan == 0 ? null : () async {
                Navigator.pop(context);
                if (r['id'] > 0) {
                  await _dbService.yorumKaydet(
                    ustaIsmi: r['ustaIsmi'], 
                    salonIsmi: r['berberIsmi'], 
                    musteriAd: _currentUserName ?? "Kullanici", 
                    puan: ustaPuan.toDouble(), 
                    yorumMetni: "Salon: $salonYorum\nUsta: ${ustaYorumC.text}"
                  );
                  await _dbService.randevuyuTamamlaVeOyla(r['id']);
                  setState(() {});
                }
              }, 
              child: const Text("TAMAMLA")
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
        icon: Icon(index < puan ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 32),
        onPressed: () => onSelect(index + 1),
      )),
    );
  }

  Widget _randevuKarti(Map<String, dynamic> r, {required bool isAktif}) {
    final colorScheme = Theme.of(context).colorScheme;
    bool oylandi = r['oylandi'] == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: isAktif ? colorScheme.primary.withOpacity(0.05) : Colors.grey[50], borderRadius: BorderRadius.circular(16)),
                child: Icon(isAktif ? Icons.event_available : Icons.history, color: isAktif ? colorScheme.primary : Colors.grey[400]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r['berberIsmi'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    Text("Usta: ${r['ustaIsmi']}", style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 12, color: colorScheme.secondary),
                        const SizedBox(width: 4),
                        Text("${r['tarih']} - ${r['saat']}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isAktif)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: oylandi ? const Color(0xFF38BDF8).withOpacity(0.1) : Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(oylandi ? "Degerlendirildi" : "Tamamlandi", style: TextStyle(color: oylandi ? const Color(0xFF38BDF8) : Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          if (isAktif) ...[
            const Divider(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harita uygulamasina yonlendiriliyorsunuz...")));
                },
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text("KONUMA GIT"),
                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary.withOpacity(0.05), foregroundColor: colorScheme.primary, elevation: 0),
              ),
            ),
          ],
          if (!isAktif) ...[
            const Divider(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: oylandi ? null : () => _siraliOyVer(r),
                icon: Icon(oylandi ? Icons.verified_rounded : Icons.star_half_rounded, size: 18),
                label: Text(oylandi ? "DEGERLENDIRME TAMAMLANDI" : "DEGERLENDIR"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: oylandi ? Colors.grey[100] : Colors.amber,
                  foregroundColor: oylandi ? Colors.grey[400] : Colors.black87,
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
