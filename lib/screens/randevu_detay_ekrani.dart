import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final DatabaseService _dbService = DatabaseService();

  final List<Map<String, dynamic>> ustalar = [
    {"isim": "Ahmet Yilmaz", "resim": "https://i.pravatar.cc/150?u=1", "puan": "4.9", "doluGunler": {3, 7, 12, 22}, "doluSaatler": {"10:00", "14:00", "17:30"}},
    {"isim": "Mehmet Demir", "resim": "https://i.pravatar.cc/150?u=2", "puan": "4.7", "doluGunler": {5, 8, 11, 20}, "doluSaatler": {"09:30", "11:00", "15:00"}},
    {"isim": "Caner Oz", "resim": "https://i.pravatar.cc/150?u=3", "puan": "4.8", "doluGunler": {2, 9, 16, 25}, "doluSaatler": {"11:30", "13:00", "18:00"}},
  ];

  final List<String> ornekResimler = [
    "https://images.pexels.com/photos/3993323/pexels-photo-3993323.jpeg?auto=compress&cs=tinysrgb&w=600",
    "https://images.pexels.com/photos/3992874/pexels-photo-3992874.jpeg?auto=compress&cs=tinysrgb&w=600",
    "https://images.pexels.com/photos/3993444/pexels-photo-3993444.jpeg?auto=compress&cs=tinysrgb&w=600",
  ];

  final List<Map<String, String>> fiyatListesi = [
    {"hizmet": "Sac Kesimi", "fiyat": "250 TL"},
    {"hizmet": "Sakal Tirasi", "fiyat": "150 TL"},
  ];

  final List<String> saatler = List.generate(25, (i) {
    int hour = 9 + (i ~/ 2);
    int minute = (i % 2) * 30;
    return "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
  });


  void _randevuSureciniBaslat() async {
    if (widget.musteriTelefon == null || widget.userName == null) {
      _misafirBilgiPopup((yeniIsim, yeniTlf) => _devamEt(yeniTlf, yeniIsim));
    } else {
      _devamEt(widget.musteriTelefon!, widget.userName!);
    }
  }

  void _devamEt(String tlf, String isim) async {
    bool varMi = await _dbService.aktifRandevusuVarMi(tlf);
    if (varMi) {
      if (!mounted) return;
      _uyariGoster("Zaten aktif bir randevunuz bulunuyor.");
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
      final enIyi = ustalar.reduce((a, b) => double.parse(a['puan']) > double.parse(b['puan']) ? a : b);
      enIyiUstaIsmi = enIyi['isim'];
    }

    final seciliUstaData = seciliUsta != null ? ustalar.firstWhere((u) => u['isim'] == seciliUsta) : null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(expandedHeight: 250.0, pinned: true, flexibleSpace: FlexibleSpaceBar(title: Text(widget.berber['isim'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 10, color: Colors.black54)])), background: Stack(fit: StackFit.expand, children: [Image.network(widget.berber['resim'], fit: BoxFit.cover), const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black87, Colors.transparent])))]))),
          SliverPadding(
            padding: const EdgeInsets.all(20.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
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
                                AnimatedContainer(duration: const Duration(milliseconds: 300), padding: const EdgeInsets.all(3), decoration: BoxDecoration(shape: BoxShape.circle, border: isSelected ? Border.all(color: colorScheme.primary, width: 3) : (isBest ? Border.all(color: Colors.amber, width: 2) : Border.all(color: Colors.transparent, width: 2))), child: CircleAvatar(radius: 38, backgroundImage: NetworkImage(ustalar[index]['resim']!))),
                                if (isBest) const Positioned(top: -10, left: 0, right: 0, child: Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 32)),
                                Positioned(bottom: 0, left: 0, right: 0, child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white, width: 1.5)), child: Text("⭐ ${ustalar[index]['puan']}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white))))),
                              ]),
                              const SizedBox(height: 10),
                              Text(ustalar[index]['isim']!.split(' ')[0], style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                AnimatedSize(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  child: seciliUstaData != null 
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 35),
                      Row(children: [const Text("Tarih Secin", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const Spacer(), _bilgiIkonu(Colors.green, "Bos"), const SizedBox(width: 10), _bilgiIkonu(Colors.red, "Dolu")]),
                      const SizedBox(height: 15),
                      _ozelTakvim(colorScheme.primary, seciliUstaData['doluGunler'] ?? {}),

                      if (seciliTarih != null) ...[
                        const SizedBox(height: 35),
                        const Text("Saat Secin", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: saatler.map((saatText) {
                            bool isDolu = (seciliUstaData['doluSaatler'] ?? {}).contains(saatText);
                            bool isSelected = seciliSaat == saatText;
                            return GestureDetector(
                              onTap: () {
                                if (isDolu) _uyariGoster("Bu saat dolu.");
                                else setState(() => seciliSaat = saatText);
                              },
                              child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: (MediaQuery.of(context).size.width - 64) / 4, padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: isDolu ? Colors.red.withOpacity(0.05) : (isSelected ? colorScheme.primary : Colors.white), borderRadius: BorderRadius.circular(16), border: Border.all(color: isDolu ? Colors.red.withOpacity(0.2) : (isSelected ? colorScheme.primary : Colors.grey[200]!), width: 1.5), boxShadow: isSelected ? [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : []), child: Center(child: Text(saatText, style: TextStyle(color: isSelected ? Colors.white : (isDolu ? Colors.red[300] : Colors.black87), fontWeight: FontWeight.bold)))),
                            );
                          }).toList(),
                        ),
                      ]
                    ],
                  )
                  : const SizedBox.shrink(),
                ),

                const SizedBox(height: 35),
                const Text("Konum", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage("https://images.pexels.com/photos/1470171/pexels-photo-1470171.jpeg?auto=compress&cs=tinysrgb&w=600"),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                        child: Icon(Icons.location_on, color: colorScheme.primary, size: 32),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(Icons.map_rounded, color: Color(0xFF38BDF8), size: 24),
                    SizedBox(width: 10),
                    Expanded(child: Text("Caferaga Mah. Moda Cad. No:123 Kadikoy / Istanbul", style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w500))),
                  ],
                ),

                const SizedBox(height: 40),
                const Text("Musteri Yorumlari", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                _yorumlarBolumu(),

                const SizedBox(height: 150), 
              ]),
            ),
          ),
        ],
      ),
      bottomSheet: (seciliUsta != null && seciliTarih != null && seciliSaat != null) ? 
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))]),
          child: SafeArea(child: ElevatedButton(onPressed: _randevuSureciniBaslat, child: const Text("RANDEVUYU ONAYLA"))),
        ) : null,
    );
  }

  Widget _yorumlarBolumu() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _dbService.salonYorumlariniGetir(widget.berber['isim']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final salonYorumlari = snapshot.data ?? [];
        if (salonYorumlari.isEmpty) {
          return Container(width: double.infinity, padding: const EdgeInsets.all(30), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(24)), child: const Column(children: [Icon(Icons.rate_review_outlined, size: 40, color: Colors.grey), SizedBox(height: 10), Text("Henuz yorum yapilmamis.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))]));
        }
        return Column(children: salonYorumlari.map((y) => _yorumKarti(y)).toList());
      },
    );
  }

  Widget _yorumKarti(Map<String, dynamic> y) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)], border: Border.all(color: Colors.grey[100]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(y['musteriAd'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), Row(children: List.generate(5, (index) => Icon(Icons.star_rounded, size: 16, color: index < y['puan'] ? Colors.amber : Colors.grey[200])))]),
          const SizedBox(height: 4),
          Text("Usta: ${y['ustaIsmi']}", style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(y['yorumMetni'], style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }

  Widget _ozelTakvim(Color primaryColor, Set<int> doluGunler) {
    final simdi = DateTime.now();
    int gunSayisi = DateTime(simdi.year, simdi.month + 1, 0).day;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20)]),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8),
        itemCount: gunSayisi,
        itemBuilder: (context, index) {
          int gun = index + 1;
          bool isDolu = doluGunler.contains(gun);
          bool isSelected = seciliTarih?.day == gun;
          bool gecmisGun = gun < simdi.day;
          return GestureDetector(
            onTap: () {
              if (gecmisGun) _uyariGoster("Gecmis bir tarih secemezsiniz.");
              else if (isDolu) _uyariGoster("Bu tarih dolu.");
              else setState(() { seciliTarih = DateTime(simdi.year, simdi.month, gun); seciliSaat = null; });
            },
            child: AnimatedContainer(duration: const Duration(milliseconds: 200), decoration: BoxDecoration(color: isSelected ? primaryColor : (isDolu || gecmisGun ? Colors.grey[100] : Colors.green.withOpacity(0.05)), shape: BoxShape.circle, border: Border.all(color: isSelected ? primaryColor : (isDolu || gecmisGun ? Colors.grey[200]! : Colors.green.withOpacity(0.2)), width: 1.5)), child: Center(child: Text(gun.toString(), style: TextStyle(color: isSelected ? Colors.white : (isDolu || gecmisGun ? Colors.grey[400] : Colors.green[700]), fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)))),
          );
        },
      ),
    );
  }

  Widget _bilgiIkonu(Color renk, String metin) {
    return Row(children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: renk, shape: BoxShape.circle)), const SizedBox(width: 6), Text(metin, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold))]);
  }
}
