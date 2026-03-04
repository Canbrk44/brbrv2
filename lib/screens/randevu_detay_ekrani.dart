import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
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
  String? seciliUsta;
  String? seciliSaat;
  final List<String> seciliKisiTurleri = ["Yetişkin"]; // Varsayılan Yetişkin seçili
  final List<String> seciliHizmetler = [];
  int toplamMaliyet = 0;
  final DatabaseService _dbService = DatabaseService();

  late List<Map<String, dynamic>> ustalar;
  late List<Map<String, dynamic>> fiyatListesi;
  late List<String> galeri;

  @override
  void initState() {
    super.initState();
    // API'den gelen verileri kullanıyoruz. Eğer yoksa boş liste atıyoruz.
    ustalar = List<Map<String, dynamic>>.from(widget.berber['ustalar'] ?? []);
    fiyatListesi = List<Map<String, dynamic>>.from(widget.berber['fiyatListesi'] ?? []);
    galeri = List<String>.from(widget.berber['galeri'] ?? []);
  }

  final List<String> saatler = List.generate(25, (i) {
    int hour = 9 + (i ~/ 2);
    int minute = (i % 2) * 30;
    return "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
  });

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

  void _kisiTuruGuncelle(String turu) {
    setState(() {
      if (seciliKisiTurleri.contains(turu)) {
        if (seciliKisiTurleri.length > 1) { // En az biri seçili kalmalı
          seciliKisiTurleri.remove(turu);
        }
      } else {
        if (seciliKisiTurleri.length < 2) { // Maksimum 2 seçim
          seciliKisiTurleri.add(turu);
        } else {
          _uyariGoster("En fazla 2 kişi seçebilirsiniz.");
        }
      }
    });
  }

  Future<void> _haritadaGoster() async {
    // Koordinatlar berber verisinden gelebilir veya varsayılan kalabilir
    final double lat = widget.berber['lat'] ?? 40.9882;
    final double lng = widget.berber['lng'] ?? 29.0284;
    final Uri googleMapsUrl = Uri.parse("google.navigation:q=$lat,$lng&mode=d");
    final Uri appleMapsUrl = Uri.parse("https://maps.apple.com/?q=$lat,$lng");

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl);
      } else if (await canLaunchUrl(appleMapsUrl)) {
        await launchUrl(appleMapsUrl);
      } else {
        _uyariGoster("Navigasyon uygulamasi bulunamadi.");
      }
    } catch (e) {
      _uyariGoster("Harita acilirken bir hata olustu.");
    }
  }

  void _randevuSureciniBaslat() async {
    if (widget.musteriTelefon == null || widget.userName == null) {
      _misafirBilgiPopup((yeniIsim, yeniTlf) => _devamEt(yeniTlf, yeniIsim));
    } else {
      _devamEt(widget.musteriTelefon!, widget.userName!);
    }
  }

  void _devamEt(String tlf, String isim) async {
    int sayi = await _dbService.aktifRandevuSayisi(tlf);
    if (sayi >= 2) {
      if (!mounted) return;
      _uyariGoster("Zaten 2 aktif randevunuz bulunuyor. Sinir doldu.");
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => SmsOnayEkrani(
          berberIsmi: widget.berber['isim'], 
          ustaIsmi: seciliUsta!, 
          tarih: "${seciliTarih!.day}/${seciliTarih!.month}/${seciliTarih!.year}", 
          saat: seciliSaat!,
          musteriTelefon: tlf,
          userName: isim,
          kisiTuru: seciliKisiTurleri.join(" + "),
        )
      )
    );
  }

  void _uyariGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFF0F172A),
      ),
    );
  }

  void _misafirBilgiPopup(Function(String, String) Onay) {
    final nC = TextEditingController();
    final pC = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 25, right: 25, top: 25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text("Randevu Icin Bilgileriniz", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: nC, decoration: const InputDecoration(hintText: "Adiniz Soyadiniz", prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 15),
            TextField(controller: pC, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)], decoration: const InputDecoration(hintText: "Telefon Numaraniz (05...)", prefixIcon: Icon(Icons.phone))),
            const SizedBox(height: 25),
            ElevatedButton(onPressed: () {
              if (nC.text.isNotEmpty && pC.text.length == 11 && pC.text.startsWith('0')) {
                Navigator.pop(context);
                Onay(nC.text, pC.text);
              } else {
                _uyariGoster("Lutfen bilgileri dogru girin.");
              }
            }, child: const Text("DEVAM ET")),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    String enIyiUstaIsmi = "";
    if (ustalar.isNotEmpty) {
      final enIyi = ustalar.reduce((a, b) => 
          double.parse(a['puan']?.toString() ?? "0") > double.parse(b['puan']?.toString() ?? "0") ? a : b);
      enIyiUstaIsmi = enIyi['isim'] ?? "";
    }

    final seciliUstaData = seciliUsta != null ? ustalar.firstWhere((u) => u['isim'] == seciliUsta) : null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0, 
            pinned: true, 
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.berber['isim'] ?? 'Salon Detay', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 10, color: Colors.black54)])), 
              background: Stack(
                fit: StackFit.expand, 
                children: [
                  Image.network(
                    widget.berber['resim'] ?? 'https://images.pexels.com/photos/3993323/pexels-photo-3993323.jpeg', 
                    fit: BoxFit.cover, 
                    errorBuilder: (c,e,s) => Container(color: Colors.grey[200])
                  ), 
                  const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black87, Colors.transparent])))
                ]
              )
            )
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (galeri.isNotEmpty) ...[
                  const Text("Galeri", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: galeri.length,
                      itemBuilder: (context, index) => Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 240,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(image: NetworkImage(galeri[index]), fit: BoxFit.cover),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 35),
                ],
                
                if (fiyatListesi.isNotEmpty) ...[
                  const Text("Hizmet Secin", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20)],
                    ),
                    child: Column(
                      children: fiyatListesi.map((item) {
                        final isSelected = seciliHizmetler.contains(item['hizmet']);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (bool? value) => _hizmetGuncelle(item['hizmet'], (item['fiyat'] as num).toInt()),
                          title: Text(item['hizmet'], style: const TextStyle(fontWeight: FontWeight.w500)),
                          secondary: Text("${item['fiyat']} TL", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.secondary)),
                          activeColor: colorScheme.primary,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                          checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 35),
                ],

                if (ustalar.isNotEmpty) ...[
                  const Text("Usta Secin", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: ustalar.length,
                      itemBuilder: (context, index) {
                        bool isSelected = seciliUsta == ustalar[index]['isim'];
                        bool isBest = ustalar[index]['isim'] == enIyiUstaIsmi;
                        return GestureDetector(
                          onTap: () => setState(() {
                            seciliUsta = ustalar[index]['isim'];
                            seciliTarih = null;
                            seciliSaat = null;
                          }),
                          child: Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 15),
                            child: Column(
                              children: [
                                Stack(clipBehavior: Clip.none, children: [
                                  AnimatedContainer(duration: const Duration(milliseconds: 300), padding: const EdgeInsets.all(3), decoration: BoxDecoration(shape: BoxShape.circle, border: isSelected ? Border.all(color: colorScheme.primary, width: 3) : (isBest ? Border.all(color: Colors.amber, width: 2) : Border.all(color: Colors.transparent, width: 2))), child: CircleAvatar(radius: 38, backgroundImage: NetworkImage(ustalar[index]['resim'] ?? 'https://i.pravatar.cc/150?u=1'))),
                                  if (isBest) const Positioned(top: -10, left: 0, right: 0, child: Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 32)),
                                  Positioned(bottom: 0, left: 0, right: 0, child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white, width: 1.5)), child: Text("⭐ ${ustalar[index]['puan']}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))))),
                                ]),
                                const SizedBox(height: 10),
                                Text(ustalar[index]['isim']?.split(' ')[0] ?? 'Usta', style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ] else const Text("Bu salonda henüz kayıtlı usta bulunmuyor."),

                // Usta seçildikten sonra gelecek kısımlar
                AnimatedSize(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  child: seciliUsta != null 
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 35),
                      const Text("Kim icin randevu aliniyor?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          {"turu": "Yetişkin", "icon": Icons.person},
                          {"turu": "Çocuk", "icon": Icons.child_care}
                        ].map((item) {
                          String turu = item['turu'] as String;
                          IconData icon = item['icon'] as IconData;
                          bool isSelected = seciliKisiTurleri.contains(turu);
                          return Padding(
                            padding: const EdgeInsets.only(right: 15),
                            child: FilterChip(
                              avatar: Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.black54),
                              label: Text(turu),
                              selected: isSelected,
                              onSelected: (val) => _kisiTuruGuncelle(turu),
                              selectedColor: colorScheme.primary,
                              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 35),
                      Row(children: [const Text("Tarih Secin", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const Spacer(), _bilgiIkonu(Colors.green, "Bos"), const SizedBox(width: 10), _bilgiIkonu(Colors.red, "Dolu")]),
                      const SizedBox(height: 15),
                      _ozelTakvim(colorScheme.primary, Set<int>.from(seciliUstaData!['doluGunler'] ?? [])),

                      if (seciliTarih != null) ...[
                        const SizedBox(height: 35),
                        const Text("Saat Secin", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: saatler.map((saatText) {
                            bool isDolu = (seciliUstaData['doluSaatler'] ?? []).contains(saatText);
                            bool isSelected = seciliSaat == saatText;
                            return GestureDetector(
                              onTap: () {
                                if (isDolu) _uyariGoster("Bu saat dolu.");
                                else setState(() => seciliSaat = saatText);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200), 
                                width: (MediaQuery.of(context).size.width - 64) / 4, 
                                padding: const EdgeInsets.symmetric(vertical: 14), 
                                decoration: BoxDecoration(
                                  color: isDolu ? Colors.red.withOpacity(0.05) : (isSelected ? colorScheme.primary : Colors.white), 
                                  borderRadius: BorderRadius.circular(16), 
                                  border: Border.all(color: isDolu ? Colors.red.withOpacity(0.2) : (isSelected ? colorScheme.primary : Colors.grey[200]!), width: 1.5), 
                                  boxShadow: isSelected ? [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : []
                                ), 
                                child: Center(child: Text(saatText, style: TextStyle(color: isSelected ? Colors.white : (isDolu ? Colors.red : Colors.black87), fontWeight: FontWeight.bold)))
                              ),
                            );
                          }).toList(),
                        ),
                      ]
                    ],
                  ) : const SizedBox.shrink(),
                ),
                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
      bottomSheet: seciliSaat != null ? Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))]),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Toplam Tutar", style: TextStyle(color: Colors.grey, fontSize: 13)),
                Text("$toplamMaliyet TL", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(child: ElevatedButton(onPressed: _randevuSureciniBaslat, child: const Text("RANDEVU AL"))),
          ],
        ),
      ) : null,
    );
  }

  Widget _bilgiIkonu(Color color, String text) {
    return Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 4), Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey))]);
  }

  Widget _ozelTakvim(Color primary, Set<int> doluGunler) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey[100]!)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Ocak 2025", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Row(children: [const Icon(Icons.chevron_left, color: Colors.grey), const SizedBox(width: 10), const Icon(Icons.chevron_right, color: Colors.grey)]),
            ],
          ),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"].map((d) => SizedBox(width: 35, child: Center(child: Text(d, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold))))).toList()),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 5, crossAxisSpacing: 5),
            itemCount: 31,
            itemBuilder: (context, index) {
              int gun = index + 1;
              bool isDolu = doluGunler.contains(gun);
              bool isSelected = seciliTarih?.day == gun;
              return GestureDetector(
                onTap: () {
                  if (isDolu) _uyariGoster("Bu gün dolu.");
                  else setState(() { seciliTarih = DateTime(2025, 1, gun); seciliSaat = null; });
                },
                child: Container(
                  decoration: BoxDecoration(color: isSelected ? primary : (isDolu ? Colors.red.withOpacity(0.1) : Colors.transparent), shape: BoxShape.circle),
                  child: Center(child: Text("$gun", style: TextStyle(color: isSelected ? Colors.white : (isDolu ? Colors.red : Colors.black87), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
