import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart';

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
      body: isGuest 
      ? _ziyaretciGorunumu(context)
      : RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 200.0,
                pinned: true,
                stretch: true,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  title: const Text("Randevularım", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network('https://images.pexels.com/photos/3993323/pexels-photo-3993323.jpeg', fit: BoxFit.cover),
                      Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87]))),
                    ],
                  ),
                ),
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _dbService.musterininRandevulariniGetir(widget.musteriTelefon!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                  final all = snapshot.data ?? [];
                  if (all.isEmpty) return const SliverFillRemaining(child: Center(child: Text("Henüz randevunuz yok.")));

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
                          const _BolumBasligi(baslik: "Geçmiş Deneyimler", icon: Icons.history, color: Colors.grey),
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
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.lock_person_outlined, size: 100, color: Colors.grey), const SizedBox(height: 20), const Text("Giriş yaparak randevularınızı yönetin."), const SizedBox(height: 30), ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/giris'), child: const Text("GİRİŞ YAP"))]));
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
      direction: DismissDirection.endToStart, // Sadece sola kaydırma
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Randevu İptali"),
            content: const Text("Bu randevuyu iptal etmek istediğinize emin misiniz?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Vazgeç")),
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
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(24)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 30),
        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.delete_sweep, color: Colors.white, size: 30), Text("İptal Et", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))]),
      ),
      child: _RandevuKartiPremium(r: r, isAktif: isAktif, db: db, user: user, onRefresh: onRefresh),
    );
  }
}

class _RandevuKartiPremium extends StatelessWidget {
  final Map<String, dynamic> r;
  final bool isAktif;
  final DatabaseService db;
  final String? user;
  final VoidCallback onRefresh;

  const _RandevuKartiPremium({required this.r, required this.isAktif, required this.db, this.user, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    bool oylandi = (r['oylandi'] ?? 0) == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 6, color: isAktif ? Colors.green : Colors.brown[200]),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(r['berberIsmi'] ?? "Salon", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          if (isAktif) const Icon(Icons.notifications_active_outlined, color: Colors.green, size: 18),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("Usta: ${r['ustaIsmi']}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _Etiket(text: r['tarih'] ?? "", icon: Icons.calendar_today, color: Colors.blue),
                          const SizedBox(width: 10),
                          _Etiket(text: r['saat'] ?? "", icon: Icons.access_time, color: Colors.orange),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: Colors.grey[50]),
                child: Center(
                  child: isAktif 
                  ? IconButton(icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 30), onPressed: () => _trendyolOylamaPopup(context))
                  : IconButton(icon: Icon(oylandi ? Icons.star : Icons.star_border, color: oylandi ? Colors.amber : Colors.grey, size: 30), onPressed: oylandi ? null : () => _trendyolOylamaPopup(context)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _trendyolOylamaPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        int step = 1;
        double sP = 0, uP = 0;
        final sC = TextEditingController(), uC = TextEditingController();

        return StatefulBuilder(
          builder: (context, setS) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: Text(step == 1 ? "Salonu Puanla" : "Ustayı Puanla", textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => IconButton(icon: Icon(i < (step == 1 ? sP : uP) ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 40), onPressed: () => setS(() => step == 1 ? sP = i + 1.0 : uP = i + 1.0)))),
                const SizedBox(height: 15),
                TextField(controller: step == 1 ? sC : uC, maxLines: 2, decoration: InputDecoration(hintText: "Deneyiminiz nasıldı?", filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none))),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(120, 45)),
                onPressed: (step == 1 ? sP : uP) == 0 ? null : () async {
                  if (step == 1) { setS(() => step = 2); }
                  else {
                    await db.yorumKaydet(randevuId: r['id'] ?? "", ustaIsmi: r['ustaIsmi'] ?? "", salonIsmi: r['berberIsmi'] ?? "", musteriAd: user ?? "Müşteri", salonPuan: sP, salonYorum: sC.text, ustaPuan: uP, ustaYorum: uC.text);
                    if (context.mounted) Navigator.pop(context);
                    onRefresh();
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
}

class _BolumBasligi extends StatelessWidget {
  final String baslik;
  final IconData icon;
  final Color color;
  const _BolumBasligi({required this.baslik, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(children: [Icon(icon, size: 20, color: color), const SizedBox(width: 10), Text(baslik, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5))]);
  }
}

class _Etiket extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _Etiket({required this.text, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(icon, size: 12, color: color), const SizedBox(width: 6), Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold))]));
  }
}
