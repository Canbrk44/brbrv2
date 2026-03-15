import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart';
import '../main.dart'; 

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
      backgroundColor: Colors.transparent, 
      body: isGuest 
      ? _ziyaretciGorunumu(context)
      : RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text("Randevularım", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1)),
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _dbService.musterininRandevulariniGetir(widget.musteriTelefon!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF9C27B0))));
                  final all = snapshot.data ?? [];
                  if (all.isEmpty) return const SliverFillRemaining(child: Center(child: Text("Henüz randevunuz yok.", style: TextStyle(color: Colors.white38))));

                  final aktif = all.where((r) => (r['durum'] ?? 'aktif') == 'aktif').toList();
                  final gecmis = all.where((r) => (r['durum'] ?? 'aktif') != 'aktif').toList();

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (aktif.isNotEmpty) ...[
                          const _BolumBasligi(baslik: "Aktif Randevular", icon: Icons.bolt, color: Colors.green),
                          const SizedBox(height: 15),
                          ...aktif.map((r) => _RandevuKaydirma(r: r, isAktif: true, db: _dbService, user: _currentUserName, onRefresh: () => setState(() {}))),
                        ],
                        if (gecmis.isNotEmpty) ...[
                          const SizedBox(height: 30),
                          const _BolumBasligi(baslik: "Geçmiş Deneyimler", icon: Icons.history, color: Colors.white38),
                          const SizedBox(height: 15),
                          ...gecmis.map((r) => _RandevuKaydirma(r: r, isAktif: false, db: _dbService, user: _currentUserName, onRefresh: () => setState(() {}))),
                        ],
                      ]),
                    ),
                  );
                },
              ),
            ],
          ),
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
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), shape: BoxShape.circle),
              child: const Icon(Icons.lock_person_rounded, size: 80, color: Color(0xFF9C27B0)),
            ),
            const SizedBox(height: 30),
            const Text("Randevularını Gör", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Randevularını yönetmek ve deneyimlerini puanlamak için giriş yapmalısın.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 14)),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0),
                foregroundColor: Colors.white, // YAZI RENGİ BEYAZ YAPILDI
                minimumSize: const Size(200, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 10,
                shadowColor: const Color(0xFF9C27B0).withOpacity(0.3),
              ), 
              onPressed: () => Navigator.pushNamed(context, '/giris'), 
              child: const Text("GİRİŞ YAP", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1))
            )
          ]
        ),
      ),
    );
  }
}

class _RandevuKaydirma extends StatelessWidget {
  final Map<String, dynamic> r;
  final bool isAktif;
  final DatabaseService db;
  final String? user;
  final VoidCallback onRefresh;

  const _RandevuKaydirma({required this.r, required this.isAktif, required this.db, this.user, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(r['id']),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF161925),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
              side: const BorderSide(color: Colors.white10, width: 0.5)
            ),
            title: const Text("Randevu İptali", style: TextStyle(color: Colors.white)),
            content: const Text("Bu randevuyu iptal etmek istediğinize emin misiniz?", style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Vazgeç", style: TextStyle(color: Colors.white38))),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Evet, İptal Et", style: TextStyle(color: Colors.red))),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        await db.randevuSil(r['id']);
        onRefresh();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Randevu iptal edildi.")));
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.red.withOpacity(0.5))),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 30),
        child: const Icon(Icons.delete_sweep, color: Colors.red, size: 30),
      ),
      child: _RandevuKartiModern(r: r, isAktif: isAktif, db: db, user: user, onRefresh: onRefresh),
    );
  }
}

class _RandevuKartiModern extends StatelessWidget {
  final Map<String, dynamic> r;
  final bool isAktif;
  final DatabaseService db;
  final String? user;
  final VoidCallback onRefresh;

  const _RandevuKartiModern({required this.r, required this.isAktif, required this.db, this.user, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    bool oylandi = (r['oylandi'] ?? 0) == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161925), 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 5, color: isAktif ? Colors.green : Colors.white10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(r['berberIsmi'] ?? "Salon", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          if (isAktif) const Icon(Icons.notifications_active_outlined, color: Colors.green, size: 16),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text("Usta: ${r['ustaIsmi']}", style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          _Etiket(text: r['tarih'] ?? "", icon: Icons.calendar_today, color: const Color(0xFF9C27B0)),
                          const SizedBox(width: 10),
                          _Etiket(text: r['saat'] ?? "", icon: Icons.access_time, color: Colors.orange),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (!isAktif) 
                Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: IconButton(
                    icon: Icon(oylandi ? Icons.star_rounded : Icons.star_border_rounded, color: oylandi ? Colors.amber : Colors.white12, size: 28),
                    onPressed: oylandi ? null : () => _puanlamaPopup(context),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _puanlamaPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        int step = 1;
        double sP = 0, uP = 0;
        final sC = TextEditingController(), uC = TextEditingController();

        return StatefulBuilder(
          builder: (context, setS) => AlertDialog(
            backgroundColor: const Color(0xFF1A1C2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28), 
              side: const BorderSide(color: Colors.white10, width: 0.5)
            ),
            title: Text(step == 1 ? "Salonu Puanla" : "Ustayı Puanla", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => IconButton(icon: Icon(i < (step == 1 ? sP : uP) ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 40), onPressed: () => setS(() => step == 1 ? sP = i + 1.0 : uP = i + 1.0)))),
                const SizedBox(height: 15),
                TextField(controller: step == 1 ? sC : uC, maxLines: 2, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "Deneyiminiz nasıldı?", hintStyle: const TextStyle(color: Colors.white24), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none))),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç", style: TextStyle(color: Colors.white38))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9C27B0), minimumSize: const Size(120, 45)),
                onPressed: (step == 1 ? sP : uP) == 0 ? null : () async {
                  if (step == 1) { setS(() => step = 2); }
                  else {
                    await db.yorumKaydet(randevuId: r['id'] ?? "", ustaIsmi: r['ustaIsmi'] ?? "", salonIsmi: r['berberIsmi'] ?? "", musteriAd: user ?? "Müşteri", salonPuan: sP, salonYorum: sC.text, ustaPuan: uP, ustaYorum: uC.text);
                    if (context.mounted) Navigator.pop(context);
                    onRefresh();
                  }
                },
                child: Text(step == 1 ? "SONRAKİ" : "GÖNDER", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BolumBasligi extends StatelessWidget {
  final String baslik;
  final IconData icon;
  final Color color;
  const _BolumBasligi({required this.baslik, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(children: [Icon(icon, size: 18, color: color), const SizedBox(width: 10), Text(baslik, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.8)))]);
  }
}

class _Etiket extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _Etiket({required this.text, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))), child: Row(children: [Icon(icon, size: 12, color: color), const SizedBox(width: 6), Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))]));
  }
}
