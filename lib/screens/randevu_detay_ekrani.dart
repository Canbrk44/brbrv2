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
    // Sınır kontrolü (Gerekirse artırılabilir veya kaldırılabilir)
    int sayi = await _dbService.aktifRandevuSayisi(tlf);
    if (sayi >= 5) { // Sınırı 5'e çıkardım test kolaylığı için
      if (!mounted) return;
      _uyariGoster("Çok fazla aktif randevunuz var.");
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => SmsOnayEkrani(
          isLogin: false, // RANDEVU MODU
          berberIsmi: widget.berber['isim'] ?? "Berber", 
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
            TextField(controller: pC, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)], decoration: const InputDecoration(hintText: "Telefon Numaranız")),
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.berber['isim'] ?? "Detay")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Usta Seçin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: ustalar.length,
                itemBuilder: (context, index) {
                  final u = ustalar[index];
                  bool isSelected = seciliUstaData?['isim'] == u['isim'];
                  return GestureDetector(
                    onTap: () => setState(() { seciliUstaData = u; seciliTarih = null; seciliSaat = null; }),
                    child: Container(
                      margin: const EdgeInsets.only(right: 15),
                      child: Column(
                        children: [
                          CircleAvatar(radius: 30, backgroundColor: isSelected ? theme.primaryColor : Colors.grey[300], child: CircleAvatar(radius: 27, backgroundImage: NetworkImage(u['resim'] ?? 'https://i.pravatar.cc/150?u=${u['isim']}'))),
                          Text(u['isim'] ?? "Usta", style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
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
              const SizedBox(height: 10),
              _takvimOlustur(theme),
            ],
            if (seciliTarih != null) ...[
              const SizedBox(height: 20),
              const Text("Saat Seçin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10, runSpacing: 10,
                children: saatler.map((s) {
                  bool isSelected = seciliSaat == s;
                  return ChoiceChip(
                    label: Text(s), selected: isSelected,
                    onSelected: (val) => setState(() => seciliSaat = s),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 30),
            const Text("Hizmetler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...fiyatListesi.map((h) => CheckboxListTile(
              title: Text(h['isim'] ?? "Hizmet"),
              subtitle: Text("${h['fiyat']} TL"),
              value: seciliHizmetler.contains(h['isim']),
              onChanged: (val) => _hizmetGuncelle(h['isim'], h['fiyat']),
            )),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: _randevuSureciniBaslat,
          child: Text("RANDEVUYU TAMAMLA (${toplamMaliyet} TL)"),
        ),
      ),
    );
  }

  Widget _takvimOlustur(ThemeData theme) {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          DateTime date = DateTime.now().add(Duration(days: index));
          bool isSelected = seciliTarih?.day == date.day;
          return GestureDetector(
            onTap: () => setState(() { seciliTarih = date; seciliSaat = null; }),
            child: Container(
              width: 60, margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(color: isSelected ? theme.primaryColor : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[300]!)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(DateFormat('E', 'tr_TR').format(date), style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 10)),
                Text(date.day.toString(), style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
              ]),
            ),
          );
        },
      ),
    );
  }
}
