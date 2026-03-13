import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import 'sms_onay_ekrani.dart';

class RandevuDetayEkrani extends StatefulWidget {
  final Map<String, dynamic> berber;
  final String? musteriTelefon;
  final String? userName;

  const RandevuDetayEkrani({super.key, required this.berber, this.musteriTelefon, this.userName});

  @override
  _RandevuDetayEkraniState createState() => _RandevuDetayEkraniState();
}

class _RandevuDetayEkraniState extends State<RandevuDetayEkrani> {
  DateTime? seciliTarih;
  Map<String, dynamic>? seciliUstaData;
  String? seciliSaat;
  final List<String> seciliHizmetler = [];
  int toplamMaliyet = 0;
  final DatabaseService _dbService = DatabaseService();

  List<Map<String, dynamic>> ustalar = [];
  List<Map<String, dynamic>> fiyatListesi = [];

  @override
  void initState() {
    super.initState();
    _verileriHazirla();
  }

  void _verileriHazirla() {
    try {
      var ustalarVerisi = widget.berber['ustalar'];
      if (ustalarVerisi is List) {
        ustalar = ustalarVerisi.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      var hizmetVerisi = widget.berber['hizmetler'] ?? [];
      if (hizmetVerisi is List) {
        fiyatListesi = hizmetVerisi.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint("Veri hazırlama hatası: $e");
    }
  }

  final List<String> saatler = ["09:00", "09:30", "10:00", "10:30", "11:00", "11:30", "12:00", "13:00", "13:30", "14:00", "14:30", "15:00", "15:30", "16:00", "16:30", "17:00", "17:30", "18:00", "18:30", "19:00"];

  void _hizmetGuncelle(String h, int f) {
    setState(() { 
      if (seciliHizmetler.contains(h)) { 
        seciliHizmetler.remove(h); 
        toplamMaliyet -= f; 
      } else { 
        seciliHizmetler.add(h); 
        toplamMaliyet += f; 
      } 
    });
  }

  void _randevuSureciniBaslat() async {
    if (seciliUstaData == null || seciliTarih == null || seciliSaat == null) { 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen usta, tarih ve saat seçin."))); 
      return; 
    }
    if (widget.musteriTelefon == null || widget.userName == null) { 
      _misafirPopup((n, t) => _onayaGonder(t, n)); 
    } else { 
      _onayaGonder(widget.musteriTelefon!, widget.userName!); 
    }
  }

  void _onayaGonder(String t, String n) async {
    int sayi = await _dbService.aktifRandevuSayisi(t);
    if (sayi >= 5) { 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Çok fazla aktif randevunuz var."))); 
      return; 
    }
    Navigator.push(context, MaterialPageRoute(builder: (c) => SmsOnayEkrani(
      isLogin: false, 
      berberIsmi: widget.berber['isim'] ?? "", 
      ustaIsmi: seciliUstaData!['isim'], 
      tarih: DateFormat('dd.MM.yyyy').format(seciliTarih!), 
      saat: seciliSaat!, 
      musteriTelefon: t, 
      userName: n, 
      kisiTuru: "Yetişkin"
    )));
  }

  void _misafirPopup(Function(String, String) o) {
    final nC = TextEditingController(); 
    final pC = TextEditingController();
    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      builder: (c) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom + 20, left: 25, right: 25, top: 25), 
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            const Text("Randevu Bilgileri", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), 
            const SizedBox(height: 20), 
            TextField(controller: nC, decoration: const InputDecoration(hintText: "Ad Soyad")), 
            TextField(controller: pC, decoration: const InputDecoration(hintText: "Telefon")), 
            const SizedBox(height: 20), 
            ElevatedButton(onPressed: () { Navigator.pop(c); o(nC.text, pC.text); }, child: const Text("DEVAM ET"))
          ]
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    String? enIyiUsta; double enY = -1.0;
    for (var u in ustalar) { 
      double p = double.tryParse(u['puan']?.toString() ?? "0") ?? 0; 
      if (p > enY) { enY = p; enIyiUsta = u['isim']; } 
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.berber['isim'] ?? "Detay")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Usta Seçin", style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: ustalar.length,
                      itemBuilder: (context, index) {
                        final u = ustalar[index]; 
                        bool isS = seciliUstaData?['isim'] == u['isim']; 
                        bool isK = u['isim'] == enIyiUsta && enY > 0;
                        return GestureDetector(
                          onTap: () => setState(() { seciliUstaData = u; seciliTarih = null; seciliSaat = null; }),
                          child: Container(
                            width: 100, 
                            margin: const EdgeInsets.only(right: 20), 
                            child: Column(
                              children: [
                                Stack(
                                  alignment: Alignment.center, 
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 300), 
                                      padding: const EdgeInsets.all(4), 
                                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isS ? const Color(0xFF4E342E) : Colors.grey[300]!, width: isS ? 3 : 1)), 
                                      child: CircleAvatar(radius: 35, backgroundImage: NetworkImage(u['resim'] ?? 'https://i.pravatar.cc/150?u=${u['isim']}'))
                                    ), 
                                    if (isK) const Positioned(top: -5, left: 0, child: Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 24))
                                  ]
                                ), 
                                const SizedBox(height: 10), 
                                Text(u['isim'] ?? "", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: isS ? FontWeight.bold : FontWeight.normal), maxLines: 1)
                              ]
                            )
                          ),
                        );
                      },
                    ),
                  ),
                  if (seciliUstaData != null) ...[const SizedBox(height: 30), _takvimOlustur(), const SizedBox(height: 20), _saatOlustur()],
                  const SizedBox(height: 30),
                  const Text("Hizmetler", style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                  ...fiyatListesi.map((h) => CheckboxListTile(title: Text(h['isim'] ?? ""), subtitle: Text("${h['fiyat']} TL"), value: seciliHizmetler.contains(h['isim']), onChanged: (v) => _hizmetGuncelle(h['isim'], (h['fiyat'] as num).toInt()))),
                  
                  const SizedBox(height: 40),
                  const Divider(),
                  const SizedBox(height: 20),
                  const Text("Müşteri Yorumları", style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 15),
                  _yorumlarListesi(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(padding: const EdgeInsets.all(25), child: ElevatedButton(onPressed: _randevuSureciniBaslat, child: Text("RANDEVUYU TAMAMLA ($toplamMaliyet TL)"))),
    );
  }

  Widget _yorumlarListesi() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _dbService.salonYorumlariniGetir(widget.berber['isim'] ?? ""),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final yorumlar = snapshot.data ?? [];
        if (yorumlar.isEmpty) return const Text("Henüz yorum yapılmamış.", style: TextStyle(color: Colors.grey));
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: yorumlar.length,
          itemBuilder: (context, index) {
            return _YorumKarti(yorum: yorumlar[index]);
          },
        );
      },
    );
  }

  Widget _takvimOlustur() {
    return SizedBox(height: 70, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: 7, itemBuilder: (c, i) {
      DateTime d = DateTime.now().add(Duration(days: i)); bool isS = seciliTarih?.day == d.day;
      return GestureDetector(onTap: () => setState(() { seciliTarih = d; seciliSaat = null; }), child: Container(width: 60, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(color: isS ? const Color(0xFF4E342E) : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[300]!)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(DateFormat('E', 'tr_TR').format(d), style: TextStyle(color: isS ? Colors.white : Colors.grey, fontSize: 10)), Text(d.day.toString(), style: TextStyle(color: isS ? Colors.white : Colors.black, fontWeight: FontWeight.bold))])));
    }));
  }

  Widget _saatOlustur() {
    return Wrap(spacing: 10, runSpacing: 10, children: saatler.map((s) { bool isS = seciliSaat == s; return ChoiceChip(label: Text(s), selected: isS, onSelected: (v) => setState(() => seciliSaat = s)); }).toList());
  }
}

// Trendyol Tarzı Genişleyen Yorum Kartı
class _YorumKarti extends StatefulWidget {
  final Map<String, dynamic> yorum;
  const _YorumKarti({required this.yorum});

  @override
  State<_YorumKarti> createState() => _YorumKartiState();
}

class _YorumKartiState extends State<_YorumKarti> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final y = widget.yorum;
    final double sPuan = double.tryParse(y['salonPuan']?.toString() ?? '0') ?? 0;
    final String tarih = y['tarih'] != null ? DateFormat('dd MMM yyyy').format(y['tarih'].toDate()) : "";

    return GestureDetector(
      onTap: () => setState(() => isExpanded = !isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: isExpanded ? const Color(0xFF4E342E).withOpacity(0.3) : Colors.transparent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(y['musteriAd'] ?? "Gizli Kullanıcı", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (i) => Icon(
                        Icons.star_rounded, 
                        size: 16, 
                        color: i < sPuan.toInt() ? Colors.amber : Colors.grey[300]
                      )),
                    ),
                  ],
                ),
                Text(tarih, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              y['salonYorum'] ?? "",
              maxLines: isExpanded ? null : 2,
              overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.4),
            ),
            if (isExpanded) ...[
              const SizedBox(height: 15),
              const Divider(height: 1),
              const SizedBox(height: 15),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFF4E342E).withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        const Icon(Icons.person_pin_rounded, size: 14, color: Color(0xFF4E342E)),
                        const SizedBox(width: 6),
                        Text("Usta: ${y['ustaIsmi']}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4E342E))),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.verified_user_rounded, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  const Text("Onaylı Deneyim", style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              const Text("Devamını gör...", style: TextStyle(fontSize: 11, color: Color(0xFF4E342E), fontWeight: FontWeight.bold)),
            ]
          ],
        ),
      ),
    );
  }
}
