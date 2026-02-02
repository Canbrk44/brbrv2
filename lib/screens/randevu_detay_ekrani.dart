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
  DateTime seciliTarih = DateTime.now();
  String? seciliUsta;
  String? seciliSaat;
  final DatabaseService _dbService = DatabaseService();

  final List<int> doluGunler = [3, 7, 12, 18, 22, 28];

  final List<String> ornekResimler = [
    "https://images.pexels.com/photos/3993323/pexels-photo-3993323.jpeg?auto=compress&cs=tinysrgb&w=400",
    "https://images.pexels.com/photos/3992874/pexels-photo-3992874.jpeg?auto=compress&cs=tinysrgb&w=400",
    "https://images.pexels.com/photos/3993444/pexels-photo-3993444.jpeg?auto=compress&cs=tinysrgb&w=400",
  ];

  final List<Map<String, String>> fiyatListesi = [
    {"hizmet": "Saç Kesimi", "fiyat": "250 TL"},
    {"hizmet": "Sakal Tıraşı", "fiyat": "150 TL"},
    {"hizmet": "Cilt Bakımı", "fiyat": "300 TL"},
    {"hizmet": "Saç & Sakal Kombin", "fiyat": "350 TL"},
  ];

  final List<Map<String, String>> yorumlar = [
    {"isim": "Murat K.", "yorum": "Ustalık konuşuyor, ellerine sağlık.", "puan": "5"},
    {"isim": "Emre Y.", "yorum": "Mekan çok temiz, servis harika.", "puan": "4"},
  ];

  final List<Map<String, dynamic>> ustalar = [
    {"isim": "Ahmet Yılmaz", "resim": "https://i.pravatar.cc/150?u=1", "puan": "4.9"},
    {"isim": "Mehmet Demir", "resim": "https://i.pravatar.cc/150?u=2", "puan": "4.7"},
    {"isim": "Caner Öz", "resim": "https://i.pravatar.cc/150?u=3", "puan": "4.8"},
  ];

  final List<Map<String, dynamic>> saatler = [
    {"saat": "09:00", "dolu": false},
    {"saat": "10:00", "dolu": true},
    {"saat": "11:00", "dolu": false},
    {"saat": "13:00", "dolu": false},
    {"saat": "14:00", "dolu": true},
    {"saat": "15:00", "dolu": false},
  ];

  void _randevuSureciniBaslat() async {
    String? tlf = widget.musteriTelefon;
    String? isim = widget.userName;

    if (tlf == null || isim == null) {
      _misafirBilgiPopup((yeniIsim, yeniTlf) async {
        _devamEt(yeniTlf, yeniIsim);
      });
    } else {
      _devamEt(tlf, isim);
    }
  }

  void _devamEt(String tlf, String isim) async {
    bool varMi = await _dbService.aktifRandevusuVarMi(tlf);
    if (varMi) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Zaten aktif bir randevunuz bulunuyor. Sadece 1 aktif randevu alabilirsiniz.")),
      );
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => SmsOnayEkrani(
          berberIsmi: widget.berber['isim'], 
          ustaIsmi: seciliUsta!, 
          tarih: "${seciliTarih.day}/${seciliTarih.month}/${seciliTarih.year}", 
          saat: seciliSaat!,
          musteriTelefon: tlf,
          userName: isim,
        )
      )
    );
  }

  void _misafirBilgiPopup(Function(String, String) Onay) {
    final TextEditingController nC = TextEditingController();
    final TextEditingController pC = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 25, right: 25, top: 25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Randevu İçin Bilgileriniz", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: nC, decoration: const InputDecoration(hintText: "Adınız Soyadınız", prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 15),
            TextField(
              controller: pC, 
              keyboardType: TextInputType.phone, 
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
              decoration: const InputDecoration(hintText: "Telefon Numaranız (05...)", prefixIcon: Icon(Icons.phone))
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () {
                if (nC.text.isNotEmpty && pC.text.length == 11 && pC.text.startsWith('0')) {
                  Navigator.pop(context);
                  Onay(nC.text, pC.text);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen bilgileri doğru girin.")));
                }
              }, 
              child: const Text("DEVAM ET")
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.berber['isim'])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Galeri", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: ornekResimler.length,
                itemBuilder: (context, index) => Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    image: DecorationImage(image: NetworkImage(ornekResimler[index]), fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text("Hizmetler ve Fiyatlar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
              child: Column(
                children: fiyatListesi.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text(item['hizmet']!), Text(item['fiyat']!, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.secondary))],
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 30),
            const Text("Usta Seçin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: ustalar.length,
                itemBuilder: (context, index) {
                  bool isSelected = seciliUsta == ustalar[index]['isim'];
                  return GestureDetector(
                    onTap: () => setState(() => seciliUsta = ustalar[index]['isim']),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 15),
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(shape: BoxShape.circle, border: isSelected ? Border.all(color: colorScheme.secondary, width: 2) : null),
                              child: CircleAvatar(radius: 35, backgroundImage: NetworkImage(ustalar[index]['resim']!)),
                            ),
                            Positioned(
                              right: 15,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(10)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star_rounded, size: 12, color: Colors.white),
                                    Text(ustalar[index]['puan'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(ustalar[index]['isim']!, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                const Text("Tarih Seçin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                _bilgiIkonu(Colors.green, "Boş"),
                const SizedBox(width: 10),
                _bilgiIkonu(Colors.red, "Dolu"),
              ],
            ),
            const SizedBox(height: 15),
            _ozelTakvim(colorScheme.primary),
            const SizedBox(height: 30),
            const Text("Saat Seçin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: saatler.map((item) {
                bool isDolu = item['dolu'];
                bool isSelected = seciliSaat == item['saat'];
                return GestureDetector(
                  onTap: isDolu ? null : () => setState(() => seciliSaat = item['saat']),
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 60) / 4,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isDolu ? Colors.red.withOpacity(0.1) : (isSelected ? colorScheme.primary : Colors.green.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDolu ? Colors.red : (isSelected ? colorScheme.primary : Colors.green)),
                    ),
                    child: Center(child: Text(item['saat'], style: TextStyle(color: isSelected ? Colors.white : (isDolu ? Colors.red : Colors.green), fontWeight: FontWeight.bold))),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            const Text("Konum", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(
                  image: NetworkImage("https://images.pexels.com/photos/1470171/pexels-photo-1470171.jpeg?auto=compress&cs=tinysrgb&w=600"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(child: Icon(Icons.location_on, color: colorScheme.primary, size: 40)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.map_outlined, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text("Caferağa Mah. Moda Cad. No:123 Kadıköy / İstanbul", style: TextStyle(color: Colors.grey[700], fontSize: 14))),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: (seciliUsta != null && seciliSaat != null) ? _randevuSureciniBaslat : null,
              child: const Text("Randevuyu Onayla"),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _ozelTakvim(Color primaryColor) {
    int gunSayisi = DateTime(seciliTarih.year, seciliTarih.month + 1, 0).day;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 5, crossAxisSpacing: 5),
        itemCount: gunSayisi,
        itemBuilder: (context, index) {
          int gun = index + 1;
          bool isDolu = doluGunler.contains(gun);
          bool isSelected = seciliTarih.day == gun;
          return GestureDetector(
            onTap: isDolu ? null : () => setState(() { seciliTarih = DateTime(seciliTarih.year, seciliTarih.month, gun); seciliSaat = null; }),
            child: Container(
              decoration: BoxDecoration(color: isSelected ? primaryColor : (isDolu ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1)), shape: BoxShape.circle, border: Border.all(color: isSelected ? primaryColor : (isDolu ? Colors.red : Colors.green))),
              child: Center(child: Text(gun.toString(), style: TextStyle(color: isSelected ? Colors.white : (isDolu ? Colors.red : Colors.green)))),
            ),
          );
        },
      ),
    );
  }

  Widget _bilgiIkonu(Color renk, String metin) {
    return Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: renk, shape: BoxShape.circle)), const SizedBox(width: 4), Text(metin, style: TextStyle(fontSize: 12, color: Colors.grey[600]))]);
  }
}
