import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart';

class SalonPanelEkrani extends StatefulWidget {
  final String ownerEmail;
  const SalonPanelEkrani({super.key, required this.ownerEmail});

  @override
  State<SalonPanelEkrani> createState() => _SalonPanelEkraniState();
}

class _SalonPanelEkraniState extends State<SalonPanelEkrani> with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  Map<String, dynamic>? _salon;
  bool _yukleniyor = true;
  DateTime _seciliTarih = DateTime.now();
  bool _takvimAcik = false;
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _salonBilgileriniGetir();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _salonBilgileriniGetir() async {
    final data = await _db.salonGetirByEmail(widget.ownerEmail);
    if (mounted) {
      setState(() {
        _salon = data;
        _yukleniyor = false;
      });
    }
  }

  Future<void> _resimSecVeYukle() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
      String? url = await _db.fotografYukle(File(image.path), _salon!['id']);
      if (mounted) {
        Navigator.pop(context);
        if (url != null) {
          _salonBilgileriniGetir();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fotoğraf başarıyla eklendi.")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_yukleniyor) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_salon == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text("Salon bulunamadı.")));

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(_salon!['isim'] ?? "Yönetim Paneli", style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _salonBilgileriniGetir)
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.analytics_rounded), text: "Analiz"),
            Tab(icon: Icon(Icons.photo_library_rounded), text: "Galeri"),
            Tab(icon: Icon(Icons.people_alt_rounded), text: "Müşteriler"),
            Tab(icon: Icon(Icons.person_pin_rounded), text: "Ustalar"),
            Tab(icon: Icon(Icons.content_cut_rounded), text: "Hizmetler"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _istatistikSekmesi(),
          _galeriSekmesi(),
          _musterilerSekmesi(),
          _ustalarSekmesi(),
          _hizmetlerSekmesi(),
        ],
      ),
      floatingActionButton: (_tabController.index == 1 || _tabController.index == 3 || _tabController.index == 4)
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF4E342E),
              foregroundColor: Colors.white,
              onPressed: () {
                if (_tabController.index == 1) _resimSecVeYukle();
                else _eklemeDialogGoster(context);
              },
              label: Text(_tabController.index == 1 ? "Fotoğraf Ekle" : (_tabController.index == 3 ? "Usta Ekle" : "Hizmet Ekle")),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _galeriSekmesi() {
    final List galeri = _salon!['galeri'] ?? [];
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: galeri.isEmpty 
      ? const Center(child: Text("Henüz fotoğraf eklenmemiş.\nSağ alttaki butondan ekleyebilirsiniz.", textAlign: TextAlign.center))
      : GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
          itemCount: galeri.length,
          itemBuilder: (context, index) => Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(galeri[index], fit: BoxFit.cover, width: double.infinity, height: double.infinity),
              ),
              Positioned(
                top: 0, right: 0,
                child: IconButton(
                  icon: const CircleAvatar(backgroundColor: Colors.red, radius: 12, child: Icon(Icons.close, color: Colors.white, size: 14)),
                  onPressed: () async {
                    await _db.fotografSil(_salon!['id'], galeri[index]);
                    _salonBilgileriniGetir();
                  },
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _istatistikSekmesi() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.salonRandevulariniGetir(_salon!['isim']),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final tumRandevular = snapshot.data!;
        final formatliSeciliTarih = DateFormat('dd.MM.yyyy').format(_seciliTarih);
        final gunlukRandevular = tumRandevular.where((r) => r['tarih'] == formatliSeciliTarih).toList();
        double gunlukCiro = 0;
        for (var r in gunlukRandevular) gunlukCiro += (r['fiyat'] ?? 100).toDouble();
        Map<String, int> ustaRandevuSayisi = {};
        Map<String, double> ustaKazanci = {};
        for (var r in gunlukRandevular) {
          String usta = r['ustaIsmi'] ?? "Bilinmeyen";
          ustaRandevuSayisi[usta] = (ustaRandevuSayisi[usta] ?? 0) + 1;
          ustaKazanci[usta] = (ustaKazanci[usta] ?? 0) + (r['fiyat'] ?? 100).toDouble();
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _analizKarti("Toplam", "${tumRandevular.length}", Icons.all_inclusive, Colors.blue)),
                  const SizedBox(width: 12),
                  Expanded(child: _analizKarti("Giriş", "${gunlukRandevular.length}", Icons.calendar_today, Colors.orange)),
                  const SizedBox(width: 12),
                  Expanded(child: _analizKarti("Ciro", "${gunlukCiro.toInt()}₺", Icons.payments_rounded, Colors.green)),
                ],
              ),
              const SizedBox(height: 25),
              _tarihSeciciBolumu(formatliSeciliTarih),
              const SizedBox(height: 30),
              const Text("Usta Performansı (Seçili Gün)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              if (ustaRandevuSayisi.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Bugün işlem yapılmadı.")))
              else
                ...ustaRandevuSayisi.entries.map((entry) => _ustaPerformansSatiri(entry.key, entry.value, ustaKazanci[entry.key] ?? 0)),
              const SizedBox(height: 30),
              const Text("Günlük İşlem Detayları", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _gunlukIslemListesi(gunlukRandevular),
              const SizedBox(height: 50),
            ],
          ),
        );
      },
    );
  }

  Widget _analizKarti(String baslik, String deger, IconData icon, Color renk) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(
        children: [
          Icon(icon, color: renk, size: 20),
          const SizedBox(height: 8),
          Text(baslik, style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(deger, style: TextStyle(color: renk, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _tarihSeciciBolumu(String tarih) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.event_note_rounded, color: Color(0xFF4E342E)),
            title: Text("Tarih Değiştir: $tarih", style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Icon(_takvimAcik ? Icons.expand_less_rounded : Icons.expand_more_rounded),
            onTap: () => setState(() => _takvimAcik = !_takvimAcik),
          ),
          if (_takvimAcik)
            CalendarDatePicker(
              initialDate: _seciliTarih,
              firstDate: DateTime(2023),
              lastDate: DateTime.now().add(const Duration(days: 30)),
              onDateChanged: (date) => setState(() { _seciliTarih = date; _takvimAcik = false; }),
            ),
        ],
      ),
    );
  }

  Widget _ustaPerformansSatiri(String isim, int adet, double kazanc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: const Color(0xFF4E342E).withOpacity(0.1), child: Text(isim[0], style: const TextStyle(color: Color(0xFF4E342E)))),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(isim, style: const TextStyle(fontWeight: FontWeight.bold)), Text("$adet Randevu", style: TextStyle(color: Colors.grey[600], fontSize: 12))])),
          Text("${kazanc.toInt()}₺", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _gunlukIslemListesi(List<Map<String, dynamic>> randevular) {
    if (randevular.isEmpty) return const Center(child: Text("Randevu kaydı yok."));
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: randevular.length,
      itemBuilder: (context, index) {
        final r = randevular[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: Text(r['saat'] ?? "--:--", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4E342E))),
            title: Text(r['musteriAd'] ?? "İsimsiz", style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text("Usta: ${r['ustaIsmi']}"),
            trailing: Text("${r['fiyat'] ?? 0}₺", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          ),
        );
      },
    );
  }

  Widget _musterilerSekmesi() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('randevular').where('berberIsmi', isEqualTo: _salon!['isim']).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        Map<String, int> musteriler = {};
        for (var doc in snapshot.data!.docs) {
          final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          final String ad = data.containsKey('musteriAd') ? data['musteriAd'] : "Bilinmiyor";
          musteriler[ad] = (musteriler[ad] ?? 0) + 1;
        }
        final liste = musteriler.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        if (liste.isEmpty) return const Center(child: Text("Henüz kayıtlı müşteri yok."));
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: liste.length,
          itemBuilder: (context, index) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.1), child: const Icon(Icons.person, color: Colors.blue)),
              title: Text(liste[index].key, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text("${liste[index].value} Randevu", style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _ustalarSekmesi() {
    final List ustalar = _salon!['ustalar'] ?? [];
    if (ustalar.isEmpty) return const Center(child: Text("Henüz usta eklenmemiş."));
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: ustalar.length,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: ListTile(
          leading: CircleAvatar(radius: 25, backgroundImage: NetworkImage(ustalar[index]['resim'] ?? 'https://i.pravatar.cc/150?u=${ustalar[index]['isim']}')),
          title: Text(ustalar[index]['isim'], style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(ustalar[index]['uzmanlik'] ?? "Berber"),
          trailing: IconButton(icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red), onPressed: () => _silmeOnayi(index, true)),
        ),
      ),
    );
  }

  Widget _hizmetlerSekmesi() {
    final List hizmetler = _salon!['hizmetler'] ?? [];
    if (hizmetler.isEmpty) return const Center(child: Text("Henüz hizmet eklenmemiş."));
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: hizmetler.length,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: ListTile(
          leading: const Icon(Icons.cut_rounded, color: Color(0xFF4E342E)),
          title: Text(hizmetler[index]['isim'], style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("${hizmetler[index]['fiyat']}₺", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
              const SizedBox(width: 10),
              IconButton(icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red), onPressed: () => _silmeOnayi(index, false)),
            ],
          ),
        ),
      ),
    );
  }

  void _silmeOnayi(int index, bool isUsta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Silme Onayı"),
        content: Text("Bu ${isUsta ? 'ustayı' : 'hizmeti'} listeden kalıcı olarak silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç")),
          TextButton(
            onPressed: () async {
              List liste = List.from(isUsta ? _salon!['ustalar'] : _salon!['hizmetler']);
              liste.removeAt(index);
              
              // SİLME İŞLEMİ DE ARTIK GÜVENLİ OLMASI İÇİN FIRESTORE ÜZERİNDEN GÜNCELLENİYOR
              await FirebaseFirestore.instance.collection('salonlar').doc(_salon!['id']).update({
                isUsta ? 'ustalar' : 'hizmetler': liste
              });
              
              if (mounted) {
                Navigator.pop(context);
                _salonBilgileriniGetir();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Başarıyla silindi.")));
              }
            }, 
            child: const Text("Evet, Sil", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  void _eklemeDialogGoster(BuildContext context) {
    final isUstaSecili = _tabController.index == 3;
    final controller1 = TextEditingController();
    final controller2 = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isUstaSecili ? "Yeni Usta" : "Yeni Hizmet"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: controller1, decoration: InputDecoration(labelText: isUstaSecili ? "Usta Adı Soyadı" : "Hizmet Adı")),
            const SizedBox(height: 10),
            TextField(controller: controller2, decoration: InputDecoration(labelText: isUstaSecili ? "Uzmanlık Alanı" : "Fiyat (₺)"), keyboardType: isUstaSecili ? TextInputType.text : TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              if (controller1.text.isEmpty || controller2.text.isEmpty) return;
              
              bool basarili = false;
              if (isUstaSecili) {
                final yeniUsta = {
                  'isim': controller1.text, 
                  'uzmanlik': controller2.text, 
                  'resim': 'https://i.pravatar.cc/150?u=${controller1.text}', 
                  'puan': 2.0, 
                  'doluSaatler': []
                };
                basarili = await _db.ustaEkle(_salon!['id'], yeniUsta);
              } else {
                final yeniHizmet = {
                  'isim': controller1.text, 
                  'fiyat': int.tryParse(controller2.text) ?? 0
                };
                basarili = await _db.hizmetEkle(_salon!['id'], yeniHizmet);
              }

              if (mounted) { 
                Navigator.pop(context); 
                if (basarili) {
                  _salonBilgileriniGetir();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İşlem başarıyla tamamlandı.")));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bir hata oluştu. Lütfen tekrar deneyin."), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }
}
