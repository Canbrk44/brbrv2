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

  final List<String> saatler = [
    "09:00", "09:30", "10:00", "10:30", "11:00", "11:30", 
    "12:00", "13:00", "13:30", "14:00", "14:30", "15:00", 
    "15:30", "16:00", "16:30", "17:00", "17:30", "18:00", "18:30", "19:00"
  ];

  void _hizmetGuncelle(String hizmet, int fiyat) {
    setState(() {
      if (seciliHizmetler.contains(hizmet)) {
        seciliHizmetler.remove(hizmet);
        toplamMaliyet -= fiyat;
      } else {
        seciliHizmetler.add(hizmet);
        toplamMaliyet += fiyat;
      }
    });
  }

  void _randevuSureciniBaslat() async {
    if (seciliUstaData == null || seciliTarih == null || seciliSaat == null) {
      _uyariGoster("Lütfen usta, tarih ve saat seçin.");
      return;
    }
    if (widget.musteriTelefon == null || widget.userName == null) {
      _misafirBilgiPopup((yeniIsim, yeniTlf) => _onayaGonder(yeniTlf, yeniIsim));
    } else {
      _onayaGonder(widget.musteriTelefon!, widget.userName!);
    }
  }

  void _onayaGonder(String tlf, String isim) async {
    int sayi = await _dbService.aktifRandevuSayisi(tlf);
    if (sayi >= 5) {
      if (!mounted) return;
      _uyariGoster("Çok fazla aktif randevunuz var.");
      return;
    }
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) => SmsOnayEkrani(
      isLogin: false,
      berberIsmi: widget.berber['isim'] ?? "Berber", 
      ustaIsmi: seciliUstaData!['isim'], 
      tarih: DateFormat('dd.MM.yyyy').format(seciliTarih!), 
      saat: seciliSaat!,
      musteriTelefon: tlf,
      userName: isim,
      kisiTuru: "Yetişkin",
    )));
  }

  void _uyariGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj), backgroundColor: const Color(0xFF4E342E)));
  }

  void _misafirBilgiPopup(Function(String, String) onay) {
    final nC = TextEditingController();
    final pC = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 25, right: 25, top: 25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Randevu İçin Bilgileriniz", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: nC, decoration: const InputDecoration(hintText: "Adınız Soyadınız")),
            TextField(controller: pC, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: "Telefon Numaranız")),
            const SizedBox(height: 25),
            ElevatedButton(onPressed: () {
              if (nC.text.isNotEmpty && pC.text.length == 11) { Navigator.pop(context); onay(nC.text, pC.text); }
              else { _uyariGoster("Bilgileri kontrol edin."); }
            }, child: const Text("DEVAM ET")),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String? enIyiUstaIsmi;
    double enYuksekPuan = -1.0;
    for (var u in ustalar) {
      double p = double.tryParse(u['puan']?.toString() ?? "0") ?? 0;
      if (p > enYuksekPuan) { enYuksekPuan = p; enIyiUstaIsmi = u['isim']; }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCFB),
      appBar: AppBar(title: Text(widget.berber['isim'] ?? "Detay"), backgroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Usta Seçin", style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: ustalar.length,
                itemBuilder: (context, index) {
                  final u = ustalar[index];
                  bool isSelected = seciliUstaData?['isim'] == u['isim'];
                  bool isKing = u['isim'] == enIyiUstaIsmi && enYuksekPuan > 0;
                  double puan = double.tryParse(u['puan']?.toString() ?? "0") ?? 0;

                  return GestureDetector(
                    onTap: () => setState(() { seciliUstaData = u; seciliTarih = null; seciliSaat = null; }),
                    child: Container(
                      width: 110,
                      margin: const EdgeInsets.only(right: 20),
                      child: Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              // Modern Double Ring Çerçeve
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: isSelected ? const LinearGradient(
                                    colors: [Color(0xFF8D6E63), Color(0xFF4E342E)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ) : null,
                                  border: isSelected ? null : Border.all(color: Colors.grey.withOpacity(0.2), width: 1.5),
                                  boxShadow: isSelected ? [
                                    BoxShadow(color: const Color(0xFF4E342E).withOpacity(0.25), blurRadius: 15, offset: const Offset(0, 8))
                                  ] : [],
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  child: CircleAvatar(
                                    radius: 38,
                                    backgroundImage: NetworkImage(u['resim'] ?? 'https://i.pravatar.cc/150?u=${u['isim']}'),
                                  ),
                                ),
                              ),
                              // Modern Rating Badge (Sağ Alt)
                              Positioned(
                                bottom: -2,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                      const SizedBox(width: 2),
                                      Text(puan.toStringAsFixed(1), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF4E342E))),
                                    ],
                                  ),
                                ),
                              ),
                              // Estetik "🏆 Pro" Rozeti (En İyisi İçin Sol Üst)
                              if (isKing)
                                Positioned(
                                  top: -8,
                                  left: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(color: Color(0xFF4E342E), shape: BoxShape.circle),
                                    child: const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 16),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            u['isim'] ?? "Usta",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                              color: isSelected ? const Color(0xFF4E342E) : Colors.black54,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (seciliUstaData != null) ...[
              const SizedBox(height: 30),
              const Text("Tarih Seçin", style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 15),
              _takvimOlustur(theme),
            ],
            if (seciliTarih != null) ...[
              const SizedBox(height: 30),
              const Text("Saat Seçin", style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 15),
              Wrap(
                spacing: 12, runSpacing: 12,
                children: saatler.map((s) {
                  bool isSelected = seciliSaat == s;
                  return GestureDetector(
                    onTap: () => setState(() => seciliSaat = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF4E342E) : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: isSelected ? const Color(0xFF4E342E) : Colors.grey.withOpacity(0.2)),
                        boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF4E342E).withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))] : [],
                      ),
                      child: Text(s, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 40),
            const Text("Hizmetler", style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 10),
            ...fiyatListesi.map((h) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.withOpacity(0.1))),
              child: CheckboxListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                title: Text(h['isim'] ?? "Hizmet", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                subtitle: Text("${h['fiyat']} TL", style: const TextStyle(color: Color(0xFF8D6E63), fontWeight: FontWeight.w600)),
                activeColor: const Color(0xFF4E342E),
                checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                value: seciliHizmetler.contains(h['isim']),
                onChanged: (val) => _hizmetGuncelle(h['isim'], h['fiyat']),
              ),
            )),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomSheet: Container(
        height: 110,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Toplam Ödeme", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
                  Text("$toplamMaliyet TL", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF4E342E))),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4E342E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                onPressed: _randevuSureciniBaslat,
                child: const Text("ONAYLA VE DEVAM ET", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _takvimOlustur(ThemeData theme) {
    return SizedBox(
      height: 85,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: 14,
        itemBuilder: (context, index) {
          DateTime date = DateTime.now().add(Duration(days: index));
          bool isSelected = seciliTarih?.day == date.day;
          return GestureDetector(
            onTap: () => setState(() { seciliTarih = date; seciliSaat = null; }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 70, margin: const EdgeInsets.only(right: 15),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF4E342E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? const Color(0xFF4E342E) : Colors.grey.withOpacity(0.2)),
                boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF4E342E).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))] : [],
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(DateFormat('E', 'tr_TR').format(date).toUpperCase(), style: TextStyle(color: isSelected ? Colors.white70 : Colors.grey, fontSize: 10, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(date.day.toString(), style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 18)),
              ]),
            ),
          );
        },
      ),
    );
  }
}
