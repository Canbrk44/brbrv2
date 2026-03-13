import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
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
  List<String> galeri = [];

  @override
  void initState() {
    super.initState();
    _verileriHazirla();
  }

  void _verileriHazirla() {
    try {
      // Ustaları güvenli bir şekilde çekelim
      var ustalarVerisi = widget.berber['ustalar'];
      if (ustalarVerisi is List) {
        ustalar = ustalarVerisi.map((e) {
          if (e is Map) return Map<String, dynamic>.from(e);
          return {"isim": e.toString(), "resim": null}; // Eğer yanlışlıkla düz yazı girildiyse objeye çevir
        }).toList();
      }

      // Hizmetleri güvenli bir şekilde çekelim
      var hizmetVerisi = widget.berber['hizmetler'] ?? widget.berber['fiyatListesi'];
      if (hizmetVerisi is List) {
        fiyatListesi = hizmetVerisi.map((e) {
          if (e is Map) return Map<String, dynamic>.from(e);
          return {"isim": e.toString(), "fiyat": 0};
        }).toList();
      }

      // Galeriyi güvenli çekelim
      var galeriVerisi = widget.berber['galeri'];
      if (galeriVerisi is List) {
        galeri = List<String>.from(galeriVerisi);
      }
    } catch (e) {
      debugPrint("Veri dönüştürme hatası: $e");
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
      _misafirBilgiPopup((yeniIsim, yeniTlf) => _devamEt(yeniTlf, yeniIsim));
    } else {
      _devamEt(widget.musteriTelefon!, widget.userName!);
    }
  }

  void _devamEt(String tlf, String isim) async {
    int sayi = await _dbService.aktifRandevuSayisi(tlf);
    if (sayi >= 3) {
      if (!mounted) return;
      _uyariGoster("En fazla 3 aktif randevunuz olabilir.");
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => SmsOnayEkrani(
          berberIsmi: widget.berber['isim'], 
          ustaIsmi: seciliUstaData!['isim'], 
          tarih: DateFormat('dd.MM.yyyy').format(seciliTarih!), 
          saat: seciliSaat!,
          musteriTelefon: tlf,
          userName: isim,
          kisiTuru: "Yetişkin",
        )
      )
    );
  }

  void _uyariGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF4E342E),
      ),
    );
  }

  void _misafirBilgiPopup(Function(String, String) onay) {
    final nC = TextEditingController();
    final pC = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 25, right: 25, top: 25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Randevu İçin Bilgileriniz", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: nC, decoration: const InputDecoration(hintText: "Adınız Soyadınız", prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 15),
            TextField(controller: pC, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)], decoration: const InputDecoration(hintText: "Telefon Numaranız (05...)", prefixIcon: Icon(Icons.phone))),
            const SizedBox(height: 25),
            ElevatedButton(onPressed: () {
              if (nC.text.isNotEmpty && pC.text.length == 11) {
                Navigator.pop(context);
                onay(nC.text, pC.text);
              } else {
                _uyariGoster("Lütfen bilgileri doğru girin.");
              }
            }, child: const Text("DEVAM ET")),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280.0, 
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand, 
                children: [
                  Image.network(
                    widget.berber['resim'] ?? 'https://images.pexels.com/photos/3993323/pexels-photo-3993323.jpeg', 
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(color: Colors.grey[300]),
                  ), 
                  const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black87, Colors.transparent])))
                ]
              )
            )
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.berber['isim'] ?? 'İsimsiz Salon', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(widget.berber['sehir'] ?? "", style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber),
                            Text(" ${widget.berber['puan'] ?? '0.0'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  if (galeri.isNotEmpty) ...[
                    const Text("Salon Galerisi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: galeri.length,
                        itemBuilder: (context, index) => Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            image: DecorationImage(image: NetworkImage(galeri[index]), fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],

                  const Text("Hizmet Seçin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[200]!)),
                    child: fiyatListesi.isEmpty 
                      ? const Padding(padding: EdgeInsets.all(20), child: Text("Hizmet listesi boş."))
                      : Column(
                          children: fiyatListesi.map((item) {
                            final name = item['isim'] ?? item['hizmet'] ?? "İsimsiz Hizmet";
                            final isSelected = seciliHizmetler.contains(name);
                            final price = (item['fiyat'] as num?)?.toInt() ?? 0;
                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (val) => _hizmetGuncelle(name, price),
                              title: Text(name),
                              secondary: Text("$price TL", style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor)),
                              activeColor: theme.primaryColor,
                              checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                            );
                          }).toList(),
                        ),
                  ),

                  const SizedBox(height: 30),

                  const Text("Usta Seçin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  ustalar.isEmpty 
                    ? const Text("Kayıtlı usta bulunamadı.")
                    : SizedBox(
                        height: 130,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: ustalar.length,
                          itemBuilder: (context, index) {
                            final usta = ustalar[index];
                            bool isSelected = seciliUstaData?['isim'] == usta['isim'];
                            return GestureDetector(
                              onTap: () => setState(() {
                                seciliUstaData = usta;
                                seciliTarih = null;
                                seciliSaat = null;
                              }),
                              child: Container(
                                width: 90,
                                margin: const EdgeInsets.only(right: 15),
                                child: Column(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: isSelected ? theme.primaryColor : Colors.transparent, width: 3),
                                      ),
                                      child: CircleAvatar(
                                        radius: 35,
                                        backgroundImage: NetworkImage(usta['resim'] ?? 'https://i.pravatar.cc/150?u=${usta['isim']}'),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(usta['isim']?.split(' ')[0] ?? 'Usta', 
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
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
                    const SizedBox(height: 20),
                    const Text("Tarih Seçin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    _takvimOlustur(theme),
                  ],

                  if (seciliTarih != null) ...[
                    const SizedBox(height: 30),
                    const Text("Saat Seçin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: saatler.map((saat) {
                        bool isDolu = (seciliUstaData!['doluSaatler'] ?? []).contains(saat);
                        bool isSelected = seciliSaat == saat;
                        return GestureDetector(
                          onTap: () {
                            if (isDolu) _uyariGoster("Bu saat dolu.");
                            else setState(() => seciliSaat = saat);
                          },
                          child: Container(
                            width: (MediaQuery.of(context).size.width - 70) / 4,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? theme.primaryColor : (isDolu ? Colors.grey[200] : Colors.white),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? theme.primaryColor : Colors.grey[300]!),
                            ),
                            child: Center(
                              child: Text(saat, style: TextStyle(
                                color: isSelected ? Colors.white : (isDolu ? Colors.grey : Colors.black87),
                                fontWeight: FontWeight.bold, fontSize: 13
                              )),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: seciliSaat != null ? Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Toplam", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text("$toplamMaliyet TL", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _randevuSureciniBaslat,
                child: const Text("RANDEVUYU TAMAMLA"),
              ),
            ),
          ],
        ),
      ) : null,
    );
  }

  Widget _takvimOlustur(ThemeData theme) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14, 
        itemBuilder: (context, index) {
          DateTime date = DateTime.now().add(Duration(days: index));
          bool isSelected = seciliTarih?.day == date.day && seciliTarih?.month == date.month;
          bool isWeekend = date.weekday == DateTime.sunday;

          return GestureDetector(
            onTap: () {
              if (isWeekend) {
                _uyariGoster("Pazar günleri kapalıyız.");
              } else {
                setState(() {
                  seciliTarih = date;
                  seciliSaat = null;
                });
              }
            },
            child: Container(
              width: 65,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSelected ? theme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: isSelected ? theme.primaryColor : Colors.grey[200]!),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('E', 'tr_TR').format(date), style: TextStyle(color: isSelected ? Colors.white70 : Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(date.day.toString(), style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
