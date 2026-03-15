import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart';
import '../main.dart'; // GradientBackground için

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

  @override
  Widget build(BuildContext context) {
    if (_yukleniyor) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFE91E63))));
    if (_salon == null) return Scaffold(backgroundColor: const Color(0xFF0F111A), body: const Center(child: Text("Salon bulunamadı.", style: TextStyle(color: Colors.white24))));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(_salon!['isim'] ?? "Yönetim Paneli", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _salonBilgileriniGetir)
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFFE91E63),
          labelColor: const Color(0xFFE91E63),
          unselectedLabelColor: Colors.white24,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(icon: Icon(Icons.analytics_rounded, size: 20), text: "Analiz"),
            Tab(icon: Icon(Icons.photo_library_rounded, size: 20), text: "Galeri"),
            Tab(icon: Icon(Icons.people_alt_rounded, size: 20), text: "Müşteriler"),
            Tab(icon: Icon(Icons.person_pin_rounded, size: 20), text: "Ustalar"),
            Tab(icon: Icon(Icons.content_cut_rounded, size: 20), text: "Hizmetler"),
          ],
        ),
      ),
      body: GradientBackground(
        accentColor: const Color(0xFFE91E63),
        child: TabBarView(
          controller: _tabController,
          children: [
            _istatistikSekmesi(),
            _galeriSekmesi(),
            _musterilerSekmesi(),
            _ustalarSekmesi(),
            _hizmetlerSekmesi(),
          ],
        ),
      ),
      floatingActionButton: (_tabController.index == 1 || _tabController.index == 3 || _tabController.index == 4)
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFFE91E63),
              foregroundColor: Colors.white,
              onPressed: () {
                if (_tabController.index == 1) _resimSecVeYukle();
                else _eklemeDialogGoster(context);
              },
              label: Text(_tabController.index == 1 ? "Fotoğraf" : (_tabController.index == 3 ? "Usta" : "Hizmet")),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _istatistikSekmesi() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.salonRandevulariniGetir(_salon!['isim']),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)));
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
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _analizKarti("Toplam", "${tumRandevular.length}", Icons.all_inclusive, Colors.blue)),
                  const SizedBox(width: 12),
                  Expanded(child: _analizKarti("Bugün", "${gunlukRandevular.length}", Icons.calendar_today, Colors.orange)),
                  const SizedBox(width: 12),
                  Expanded(child: _analizKarti("Ciro", "${gunlukCiro.toInt()}₺", Icons.payments_rounded, Colors.green)),
                ],
              ),
              const SizedBox(height: 30),
              _tarihSeciciModern(formatliSeciliTarih),
              const SizedBox(height: 40),
              _bolumBasligi("USTA PERFORMANSI", Icons.auto_graph_rounded),
              const SizedBox(height: 15),
              if (ustaRandevuSayisi.isEmpty)
                _bosVeriPanel("Bugün henüz işlem kaydı bulunmuyor.")
              else
                ...ustaRandevuSayisi.entries.map((entry) => _ustaPerformansKarti(entry.key, entry.value, ustaKazanci[entry.key] ?? 0)),
              const SizedBox(height: 40),
              _bolumBasligi("İŞLEM DETAYLARI", Icons.list_alt_rounded),
              const SizedBox(height: 15),
              _islemListesiModern(gunlukRandevular),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _analizKarti(String baslik, String deger, IconData icon, Color renk) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF161925),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: renk, size: 22),
          const SizedBox(height: 10),
          Text(baslik, style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(deger, style: TextStyle(color: renk, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _tarihSeciciModern(String tarih) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161925),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.event_note_rounded, color: Color(0xFFE91E63)),
            title: Text("Tarih: $tarih", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            trailing: Icon(_takvimAcik ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: Colors.white24),
            onTap: () => setState(() => _takvimAcik = !_takvimAcik),
          ),
          if (_takvimAcik)
            Theme(
              data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFFE91E63), onPrimary: Colors.white, surface: Color(0xFF161925))),
              child: CalendarDatePicker(
                initialDate: _seciliTarih,
                firstDate: DateTime(2023),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                onDateChanged: (date) => setState(() { _seciliTarih = date; _takvimAcik = false; }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ustaPerformansKarti(String isim, int adet, double kazanc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF161925),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.white.withOpacity(0.05), child: Text(isim[0], style: const TextStyle(color: Colors.white70))),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(isim, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text("$adet Randevu", style: const TextStyle(color: Colors.white38, fontSize: 12))])),
          Text("${kazanc.toInt()}₺", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _islemListesiModern(List<Map<String, dynamic>> randevular) {
    if (randevular.isEmpty) return _bosVeriPanel("Seçili tarihte işlem bulunmuyor.");
    return Column(
      children: randevular.map((r) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF161925),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.03)),
        ),
        child: ListTile(
          leading: Text(r['saat'] ?? "--:--", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE91E63))),
          title: Text(r['musteriAd'] ?? "İsimsiz", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text("Usta: ${r['ustaIsmi']}", style: const TextStyle(color: Colors.white38, fontSize: 12)),
          trailing: Text("${r['fiyat'] ?? 0}₺", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        ),
      )).toList(),
    );
  }

  Widget _bolumBasligi(String yazi, IconData icon) {
    return Row(children: [Icon(icon, size: 16, color: const Color(0xFFE91E63).withOpacity(0.7)), const SizedBox(width: 10), Text(yazi, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5))]);
  }

  Widget _bosVeriPanel(String mesaj) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05), style: BorderStyle.none)),
      child: Text(mesaj, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white24, fontSize: 13)),
    );
  }

  // --- Diğer Sekmeler (Modernize Edildi) ---

  Widget _galeriSekmesi() {
    final List galeri = _salon!['galeri'] ?? [];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: galeri.isEmpty 
      ? _bosVeriPanel("Henüz fotoğraf eklenmemiş.")
      : GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: galeri.length,
          itemBuilder: (context, index) => Stack(
            children: [
              ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(galeri[index], fit: BoxFit.cover, width: double.infinity, height: double.infinity)),
              Positioned(top: 5, right: 5, child: GestureDetector(onTap: () async { await _db.fotografSil(_salon!['id'], galeri[index]); _salonBilgileriniGetir(); }, child: const CircleAvatar(backgroundColor: Colors.red, radius: 12, child: Icon(Icons.close, color: Colors.white, size: 14)))),
            ],
          ),
        ),
    );
  }

  Widget _musterilerSekmesi() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('randevular').where('berberIsmi', isEqualTo: _salon!['isim']).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)));
        Map<String, int> musteriler = {};
        for (var doc in snapshot.data!.docs) {
          final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          final String ad = data['musteriAd'] ?? "Bilinmiyor";
          musteriler[ad] = (musteriler[ad] ?? 0) + 1;
        }
        final liste = musteriler.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        if (liste.isEmpty) return _bosVeriPanel("Henüz kayıtlı müşteri yok.");
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: liste.length,
          itemBuilder: (context, index) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: const Color(0xFF161925), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.03))),
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFF1A1C2E), child: Icon(Icons.person, color: Colors.white38)),
              title: Text(liste[index].key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Text("${liste[index].value} Randevu", style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold))),
            ),
          ),
        );
      },
    );
  }

  Widget _ustalarSekmesi() {
    final List ustalar = _salon!['ustalar'] ?? [];
    if (ustalar.isEmpty) return _bosVeriPanel("Henüz usta eklenmemiş.");
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: ustalar.length,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: const Color(0xFF161925), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.03))),
        child: ListTile(
          leading: CircleAvatar(radius: 25, backgroundImage: NetworkImage(ustalar[index]['resim'] ?? 'https://i.pravatar.cc/150?u=${ustalar[index]['isim']}')),
          title: Text(ustalar[index]['isim'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text(ustalar[index]['uzmanlik'] ?? "Berber", style: const TextStyle(color: Colors.white38, fontSize: 12)),
          trailing: IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent), onPressed: () => _silmeOnayi(index, true)),
        ),
      ),
    );
  }

  Widget _hizmetlerSekmesi() {
    final List hizmetler = _salon!['hizmetler'] ?? [];
    if (hizmetler.isEmpty) return _bosVeriPanel("Henüz hizmet eklenmemiş.");
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: hizmetler.length,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: const Color(0xFF161925), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.03))),
        child: ListTile(
          leading: const Icon(Icons.cut_rounded, color: Color(0xFFE91E63), size: 20),
          title: Text(hizmetler[index]['isim'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("${hizmetler[index]['fiyat']}₺", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 10),
              IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent), onPressed: () => _silmeOnayi(index, false)),
            ],
          ),
        ),
      ),
    );
  }

  // --- Yardımcı Metotlar ---

  Future<void> _resimSecVeYukle() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator(color: Color(0xFFE91E63))));
      String? url = await _db.fotografYukle(File(image.path), _salon!['id']);
      if (mounted) { Navigator.pop(context); if (url != null) { _salonBilgileriniGetir(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fotoğraf başarıyla eklendi."))); } }
    }
  }

  void _silmeOnayi(int index, bool isUsta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161925),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25), side: const BorderSide(color: Colors.white10)),
        title: const Text("Silme Onayı", style: TextStyle(color: Colors.white)),
        content: Text("Bu ${isUsta ? 'ustayı' : 'hizmeti'} kalıcı olarak silmek istediğinize emin misiniz?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(color: Colors.white24))),
          TextButton(onPressed: () async {
            List liste = List.from(isUsta ? _salon!['ustalar'] : _salon!['hizmetler']);
            liste.removeAt(index);
            await FirebaseFirestore.instance.collection('salonlar').doc(_salon!['id']).update({isUsta ? 'ustalar' : 'hizmetler': liste});
            if (mounted) { Navigator.pop(context); _salonBilgileriniGetir(); }
          }, child: const Text("Evet, Sil", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _eklemeDialogGoster(BuildContext context) {
    final isUstaSecili = _tabController.index == 3;
    final c1 = TextEditingController(); final c2 = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161925),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25), side: const BorderSide(color: Colors.white10)),
        title: Text(isUstaSecili ? "Yeni Usta" : "Yeni Hizmet", style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: c1, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: isUstaSecili ? "Ad Soyad" : "Hizmet İsmi", labelStyle: const TextStyle(color: Colors.white24))),
            const SizedBox(height: 10),
            TextField(controller: c2, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: isUstaSecili ? "Uzmanlık" : "Fiyat (₺)", labelStyle: const TextStyle(color: Colors.white24)), keyboardType: isUstaSecili ? TextInputType.text : TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(color: Colors.white24))),
          ElevatedButton(onPressed: () async {
            if (c1.text.isEmpty || c2.text.isEmpty) return;
            bool res = false;
            if (isUstaSecili) res = await _db.ustaEkle(_salon!['id'], {'isim': c1.text, 'uzmanlik': c2.text, 'resim': 'https://i.pravatar.cc/150?u=${c1.text}', 'puan': 2.0, 'doluSaatler': []});
            else res = await _db.hizmetEkle(_salon!['id'], {'isim': c1.text, 'fiyat': int.tryParse(c2.text) ?? 0});
            if (mounted) { Navigator.pop(context); if (res) _salonBilgileriniGetir(); }
          }, child: const Text("Kaydet")),
        ],
      ),
    );
  }
}
