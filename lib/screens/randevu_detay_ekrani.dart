import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import 'sms_onay_ekrani.dart';
import 'usta_detay_ekrani.dart'; 
import '../main.dart'; 

class RandevuDetayEkrani extends StatefulWidget {
  final Map<String, dynamic> berber;
  final String? musteriTelefon;
  final String? userName;

  const RandevuDetayEkrani({super.key, required this.berber, this.musteriTelefon, this.userName});

  @override
  _RandevuDetayEkraniState createState() => _RandevuDetayEkraniState();
}

class _RandevuDetayEkraniState extends State<RandevuDetayEkrani> with TickerProviderStateMixin {
  DateTime? seciliTarih;
  Map<String, dynamic>? seciliUstaData;
  String? seciliSaat;
  final List<String> seciliHizmetler = [];
  int toplamMaliyet = 0;
  final DatabaseService _dbService = DatabaseService();

  List<Map<String, dynamic>> ustalar = [];
  List<Map<String, dynamic>> fiyatListesi = [];
  List<String> doluSaatler = [];
  Map<String, int> gunlukRandevuSayilari = {};
  
  late AnimationController _pulseController;

  final List<String> saatler = ["09:00", "09:30", "10:00", "10:30", "11:00", "11:30", "12:00", "13:00", "13:30", "14:00", "14:30", "15:00", "15:30", "16:00", "16:30", "17:00", "17:30", "18:00", "18:30", "19:00"];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _verileriHazirla();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _verileriHazirla() {
    try {
      var ustalarVerisi = widget.berber['ustalar'];
      if (ustalarVerisi is List) {
        ustalar = ustalarVerisi.map((e) => Map<String, dynamic>.from(e)).toList();
        ustalar.sort((a, b) => (double.tryParse(b['puan']?.toString() ?? "0") ?? 0).compareTo(double.tryParse(a['puan']?.toString() ?? "0") ?? 0));
      }
      var hizmetVerisi = widget.berber['hizmetler'] ?? [];
      if (hizmetVerisi is List) {
        fiyatListesi = hizmetVerisi.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {}
  }

  Future<void> _dolulukBilgileriniGuncelle() async {
    if (seciliUstaData == null) return;
    final oranlar = await _dbService.dolulukOranlariniGetir(widget.berber['isim'], seciliUstaData!['isim']);
    setState(() { gunlukRandevuSayilari = oranlar; });
    if (seciliTarih != null) {
      String tStr = DateFormat('dd.MM.yyyy').format(seciliTarih!);
      final dolu = await _dbService.doluSaatleriGetir(widget.berber['isim'], seciliUstaData!['isim'], tStr);
      setState(() { doluSaatler = dolu; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      body: GradientBackground(
        accentColor: const Color(0xFFE91E63),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(25, 20, 25, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 35),
                    _Baslik(yazi: "Usta Seçimi"),
                    const SizedBox(height: 15),
                    _buildUstaList(),
                    if (seciliUstaData != null) ...[
                      const SizedBox(height: 35),
                      _Baslik(yazi: "Randevu Tarihi"),
                      const SizedBox(height: 15),
                      _buildTakvim(),
                      if (seciliTarih != null) ...[
                        const SizedBox(height: 35),
                        _Baslik(yazi: "Randevu Saati"),
                        const SizedBox(height: 15),
                        _buildSaatler(),
                      ],
                    ],
                    const SizedBox(height: 35),
                    _Baslik(yazi: "Hizmetler"),
                    const SizedBox(height: 15),
                    _buildHizmetler(),
                    const SizedBox(height: 35),
                    _Baslik(yazi: "Müşteri Deneyimleri"),
                    const SizedBox(height: 15),
                    _buildYorumlar(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomBar(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const CircleAvatar(backgroundColor: Colors.black38, child: Icon(Icons.arrow_back, color: Colors.white, size: 20)),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        title: Text(widget.berber['isim'] ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(widget.berber['resim'] ?? "https://i.pravatar.cc/500", fit: BoxFit.cover),
            const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xFF0F111A)]))),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF161925), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("KONUM", style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(widget.berber['sehir'] ?? "Belirtilmemiş", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.amber.withOpacity(0.2))),
            child: Row(children: [const Icon(Icons.star_rounded, color: Colors.amber, size: 18), const SizedBox(width: 4), Text("${widget.berber['puan'] ?? '0.0'}", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))]),
          ),
        ],
      ),
    );
  }

  Widget _buildUstaList() {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: ustalar.length,
        itemBuilder: (context, index) {
          final u = ustalar[index];
          bool isS = seciliUstaData?['isim'] == u['isim'];
          return GestureDetector(
            onTap: () { setState(() { seciliUstaData = u; seciliTarih = null; seciliSaat = null; }); _dolulukBilgileriniGuncelle(); },
            child: Container(
              width: 90,
              margin: const EdgeInsets.only(right: 15),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isS ? const Color(0xFFE91E63) : Colors.white10, width: 2)),
                    child: CircleAvatar(radius: 32, backgroundImage: NetworkImage(u['resim'] ?? "https://i.pravatar.cc/150")),
                  ),
                  const SizedBox(height: 10),
                  Text(u['isim']?.split(' ')[0] ?? "", style: TextStyle(color: isS ? Colors.white : Colors.white38, fontSize: 12, fontWeight: isS ? FontWeight.bold : FontWeight.normal), maxLines: 1),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTakvim() {
    return SizedBox(
      height: 85,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        itemBuilder: (context, i) {
          DateTime d = DateTime.now().add(Duration(days: i));
          String dStr = DateFormat('dd.MM.yyyy').format(d);
          bool isS = seciliTarih?.day == d.day;
          int count = gunlukRandevuSayilari[dStr] ?? 0;
          double doluluk = count / saatler.length;
          Color status = doluluk >= 1.0 ? Colors.red : (doluluk >= 0.5 ? Colors.orange : Colors.green);

          return GestureDetector(
            onTap: doluluk >= 1.0 ? null : () { setState(() { seciliTarih = d; seciliSaat = null; }); _dolulukBilgileriniGuncelle(); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isS ? const Color(0xFFE91E63) : const Color(0xFF161925),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isS ? Colors.transparent : Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('E', 'tr_TR').format(d), style: TextStyle(color: isS ? Colors.white70 : Colors.white24, fontSize: 11)),
                  const SizedBox(height: 5),
                  Text(d.day.toString(), style: TextStyle(color: isS ? Colors.white : Colors.white70, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 5),
                  Container(width: 4, height: 4, decoration: BoxDecoration(color: isS ? Colors.white54 : status, shape: BoxShape.circle)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSaatler() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: saatler.map((s) {
        bool isS = seciliSaat == s;
        bool isD = doluSaatler.contains(s);
        return GestureDetector(
          onTap: isD ? null : () => setState(() => seciliSaat = s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isD ? Colors.white.withOpacity(0.02) : (isS ? const Color(0xFFE91E63) : const Color(0xFF161925)),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isD ? Colors.transparent : (isS ? Colors.transparent : Colors.white.withOpacity(0.05))),
            ),
            child: Text(s, style: TextStyle(color: isD ? Colors.white10 : (isS ? Colors.white : Colors.white70), fontWeight: isS ? FontWeight.bold : FontWeight.normal, decoration: isD ? TextDecoration.lineThrough : null)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHizmetler() {
    return Column(
      children: fiyatListesi.map((h) {
        bool isS = seciliHizmetler.contains(h['isim']);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: const Color(0xFF161925), borderRadius: BorderRadius.circular(20), border: Border.all(color: isS ? const Color(0xFFE91E63).withOpacity(0.5) : Colors.white.withOpacity(0.05))),
          child: CheckboxListTile(
            activeColor: const Color(0xFFE91E63),
            checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            title: Text(h['isim'] ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: Text("${h['fiyat']} TL", style: const TextStyle(color: Color(0xFFE91E63), fontWeight: FontWeight.bold)),
            value: isS,
            onChanged: (v) {
              setState(() {
                if (isS) { seciliHizmetler.remove(h['isim']); toplamMaliyet -= (h['fiyat'] as num).toInt(); }
                else { seciliHizmetler.add(h['isim']); toplamMaliyet += (h['fiyat'] as num).toInt(); }
              });
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildYorumlar() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _dbService.salonYorumlariniGetir(widget.berber['isim'] ?? ""),
      builder: (context, snapshot) {
        final yorumlar = snapshot.data ?? [];
        if (yorumlar.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Henüz deneyim paylaşılmamış.", style: TextStyle(color: Colors.white24, fontSize: 13))));
        
        return Column(
          children: yorumlar.map((y) => _YorumKartiDetayli(y: y, ustalar: ustalar, salonIsmi: widget.berber['isim'] ?? "")).toList(),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 40),
      decoration: BoxDecoration(
        color: const Color(0xFF161925),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("TOPLAM TUTAR", style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                Text("${toplamMaliyet} TL", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 10,
              shadowColor: const Color(0xFFE91E63).withOpacity(0.3),
            ),
            onPressed: _randevuSureciniBaslat,
            child: const Text("RANDEVU AL", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  void _randevuSureciniBaslat() async {
    if (seciliUstaData == null || seciliTarih == null || seciliSaat == null || seciliHizmetler.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen usta, tarih, saat ve hizmet seçin."), backgroundColor: Color(0xFFE91E63)));
      return;
    }
    _onayaGonder(widget.musteriTelefon ?? "", widget.userName ?? "Misafir");
  }

  void _onayaGonder(String t, String n) {
    Navigator.push(context, MaterialPageRoute(builder: (c) => SmsOnayEkrani(
      isLogin: false, 
      salonId: widget.berber['id'],
      berberIsmi: widget.berber['isim'] ?? "", 
      ustaIsmi: seciliUstaData!['isim'], 
      tarih: DateFormat('dd.MM.yyyy').format(seciliTarih!), 
      saat: seciliSaat!, 
      musteriTelefon: t, 
      userName: n, 
      kisiTuru: "Yetişkin",
      fiyat: toplamMaliyet.toDouble(),
      hizmetAdi: seciliHizmetler.join(', '),
    )));
  }
}

class _YorumKartiDetayli extends StatelessWidget {
  final Map<String, dynamic> y;
  final List<Map<String, dynamic>> ustalar;
  final String salonIsmi;
  const _YorumKartiDetayli({required this.y, required this.ustalar, required this.salonIsmi});

  @override
  Widget build(BuildContext context) {
    final double salonPuan = double.tryParse(y['salonPuan']?.toString() ?? '0') ?? 0;
    final double ustaPuan = double.tryParse(y['ustaPuan']?.toString() ?? '0') ?? 0;

    String tarihText = "Belirtilmedi";
    if (y['tarih'] != null) {
      if (y['tarih'] is Timestamp) {
        tarihText = DateFormat('dd.MM.yyyy').format((y['tarih'] as Timestamp).toDate());
      } else {
        tarihText = y['tarih'].toString();
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161925), 
        borderRadius: BorderRadius.circular(25), 
        border: Border.all(color: Colors.white.withOpacity(0.03))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(y['musteriAd'] ?? "Misafir", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const Icon(Icons.verified_user_rounded, color: Colors.green, size: 16),
            ],
          ),
          const Divider(height: 30, color: Colors.white10),
          _yorumBolumu("SALON DENEYİMİ", salonPuan, y['salonYorum'] ?? "", const Color(0xFFE91E63)),
          const SizedBox(height: 20),
          _yorumBolumu("USTA DENEYİMİ", ustaPuan, y['ustaYorum'] ?? "", Colors.amber),
          
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Tarih: $tarihText", style: const TextStyle(color: Colors.white12, fontSize: 10)),
              InkWell(
                onTap: () {
                  final ustaAdi = y['ustaIsmi'];
                  final ustaVerisi = ustalar.firstWhere((u) => u['isim'] == ustaAdi, orElse: () => {});
                  if (ustaVerisi.isNotEmpty) {
                    Navigator.push(context, MaterialPageRoute(builder: (c) => UstaDetayEkrani(usta: ustaVerisi, salonIsmi: salonIsmi)));
                  }
                },
                borderRadius: BorderRadius.circular(5),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  child: Text(
                    "(Usta: ${y['ustaIsmi'] ?? 'Bilinmiyor'})", 
                    style: const TextStyle(color: Color(0xFFE91E63), fontSize: 10, fontStyle: FontStyle.italic, decoration: TextDecoration.underline),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _yorumBolumu(String baslik, double puan, String yorum, Color renk) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(baslik, style: TextStyle(color: renk.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            Row(children: List.generate(5, (i) => Icon(Icons.star_rounded, size: 12, color: i < puan.toInt() ? renk : Colors.white10))),
          ],
        ),
        const SizedBox(height: 8),
        Text(yorum, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5)),
      ],
    );
  }
}

class _Baslik extends StatelessWidget {
  final String yazi;
  const _Baslik({required this.yazi});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: const Color(0xFFE91E63), borderRadius: BorderRadius.circular(10))),
        const SizedBox(width: 12),
        Text(yazi, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
      ],
    );
  }
}
