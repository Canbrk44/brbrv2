import 'package:flutter/material.dart';
import 'sms_onay_ekrani.dart';

class RandevuDetayEkrani extends StatefulWidget {
  final Map<String, dynamic> berber;

  RandevuDetayEkrani({required this.berber});

  @override
  _RandevuDetayEkraniState createState() => _RandevuDetayEkraniState();
}

class _RandevuDetayEkraniState extends State<RandevuDetayEkrani> {
  DateTime seciliTarih = DateTime.now();
  String? seciliUsta;
  String? seciliSaat;

  final List<int> doluGunler = [3, 7, 12, 18, 22, 28];

  final List<String> ornekResimler = [
    "https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=500",
    "https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=500",
    "https://images.unsplash.com/photo-1621605815841-2cd6100b895c?w=500",
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

  final List<Map<String, String>> ustalar = [
    {"isim": "Ahmet Yılmaz", "resim": "https://i.pravatar.cc/150?u=1"},
    {"isim": "Mehmet Demir", "resim": "https://i.pravatar.cc/150?u=2"},
    {"isim": "Caner Öz", "resim": "https://i.pravatar.cc/150?u=3"},
  ];

  final List<Map<String, dynamic>> saatler = [
    {"saat": "09:00", "dolu": false},
    {"saat": "10:00", "dolu": true},
    {"saat": "11:00", "dolu": false},
    {"saat": "13:00", "dolu": false},
    {"saat": "14:00", "dolu": true},
    {"saat": "15:00", "dolu": false},
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.berber['isim']),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Galeri Bölümü
            Text("Galeri", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Container(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: ornekResimler.length,
                itemBuilder: (context, index) => Container(
                  margin: EdgeInsets.only(right: 10),
                  width: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    image: DecorationImage(image: NetworkImage(ornekResimler[index]), fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 25),
            // Fiyat Listesi
            Text("Hizmetler ve Fiyatlar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: fiyatListesi.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text(item['hizmet']!), Text(item['fiyat']!, style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor))],
                  ),
                )).toList(),
              ),
            ),

            SizedBox(height: 25),
            // Usta Seçimi
            Text("Usta Seçin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 15),
            Container(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: ustalar.length,
                itemBuilder: (context, index) {
                  bool isSelected = seciliUsta == ustalar[index]['isim'];
                  return GestureDetector(
                    onTap: () => setState(() => seciliUsta = ustalar[index]['isim']),
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.only(right: 15),
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(shape: BoxShape.circle, border: isSelected ? Border.all(color: primaryColor, width: 2) : null),
                          child: CircleAvatar(radius: 35, backgroundImage: NetworkImage(ustalar[index]['resim']!)),
                        ),
                        SizedBox(height: 5),
                        Text(ustalar[index]['isim']!, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      ],
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 25),
            // Takvim
            Row(
              children: [
                Text("Tarih Seçin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Spacer(),
                _bilgiIkonu(Colors.green, "Boş"),
                SizedBox(width: 10),
                _bilgiIkonu(Colors.red, "Dolu"),
              ],
            ),
            SizedBox(height: 15),
            _ozelTakvim(primaryColor),

            SizedBox(height: 25),
            // Saatler
            Text("Saat Seçin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 15),
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
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isDolu ? Colors.red.withOpacity(0.1) : (isSelected ? primaryColor : Colors.green.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDolu ? Colors.red : (isSelected ? primaryColor : Colors.green)),
                    ),
                    child: Center(child: Text(item['saat'], style: TextStyle(color: isSelected ? Colors.white : (isDolu ? Colors.red : Colors.green), fontWeight: FontWeight.bold))),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 25),
            // Harita ve Adres
            Text("Konum", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: NetworkImage("https://maps.googleapis.com/maps/api/staticmap?center=41.0082,28.9784&zoom=15&size=600x300&key=YOUR_API_KEY"), // Statik harita simülasyonu
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(child: Icon(Icons.location_on, color: primaryColor, size: 40)),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.map_outlined, color: primaryColor, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text("Caferağa Mah. Moda Cad. No:123 Kadıköy / İstanbul", style: TextStyle(color: Colors.grey[700], fontSize: 14))),
              ],
            ),

            SizedBox(height: 25),
            // Yorumlar
            Text("Müşteri Yorumları", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ...yorumlar.map((y) => Container(
              margin: EdgeInsets.only(bottom: 10),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text(y['isim']!, style: TextStyle(fontWeight: FontWeight.bold)), Row(children: List.generate(int.parse(y['puan']!), (i) => Icon(Icons.star, color: Colors.amber, size: 14)))],
                  ),
                  SizedBox(height: 5),
                  Text(y['yorum']!, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                ],
              ),
            )).toList(),

            SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                onPressed: (seciliUsta != null && seciliSaat != null)
                    ? () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => SmsOnayEkrani(berberIsmi: widget.berber['isim'], ustaIsmi: seciliUsta!, tarih: "${seciliTarih.day}/${seciliTarih.month}/${seciliTarih.year}", saat: seciliSaat!)));
                      }
                    : null,
                child: Text("Randevuyu Onayla", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _ozelTakvim(Color primaryColor) {
    int gunSayisi = DateTime(seciliTarih.year, seciliTarih.month + 1, 0).day;
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 5, crossAxisSpacing: 5),
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
    return Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: renk, shape: BoxShape.circle)), SizedBox(width: 4), Text(metin, style: TextStyle(fontSize: 12, color: Colors.grey[600]))]);
  }
}
