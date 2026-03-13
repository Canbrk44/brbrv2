import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart';

class SalonPanelEkrani extends StatefulWidget {
  final String ownerEmail;
  const SalonPanelEkrani({super.key, required this.ownerEmail});

  @override
  State<SalonPanelEkrani> createState() => _SalonPanelEkraniState();
}

class _SalonPanelEkraniState extends State<SalonPanelEkrani> {
  final DatabaseService _db = DatabaseService();
  Map<String, dynamic>? _salon;
  bool _yukleniyor = true;
  DateTime _seciliTarih = DateTime.now();
  bool _takvimAcik = false;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _salonBilgileriniGetir();
  }

  Future<void> _salonBilgileriniGetir() async {
    final data = await _db.salonGetirByEmail(widget.ownerEmail);
    setState(() {
      _salon = data;
      _yukleniyor = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_yukleniyor) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_salon == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text("Salon bulunamadı.")));

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_salon!['isim'] ?? "Salon Paneli"),
          bottom: TabBar(
            isScrollable: true,
            onTap: (index) {
              setState(() {
                _currentTabIndex = index;
              });
            },
            tabs: const [
              Tab(icon: Icon(Icons.analytics_outlined), text: "İstatistik"),
              Tab(icon: Icon(Icons.people_alt_outlined), text: "Müşteriler"),
              Tab(icon: Icon(Icons.person_outline), text: "Ustalar"),
              Tab(icon: Icon(Icons.list_alt_outlined), text: "Hizmetler"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _istatistikSekmesi(),
            _musterilerSekmesi(),
            _ustalarSekmesi(),
            _hizmetlerSekmesi(),
          ],
        ),
        floatingActionButton: (_currentTabIndex == 2 || _currentTabIndex == 3)
            ? FloatingActionButton(
                onPressed: () => _eklemeDialogGoster(context),
                child: const Icon(Icons.add),
              )
            : null,
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
        
        double toplamGelir = 0;
        for (var r in tumRandevular) {
          toplamGelir += 150; // Örnek sabit fiyat, normalde hizmet fiyatından gelmeli
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst Özet Kartları
              Row(
                children: [
                  Expanded(child: _miniOzetKarti("Toplam", "${tumRandevular.length}", Colors.blue)),
                  const SizedBox(width: 12),
                  Expanded(child: _miniOzetKarti("Bugün", "${tumRandevular.where((r) => r['tarih'] == DateFormat('dd.MM.yyyy').format(DateTime.now())).length}", Colors.orange)),
                  const SizedBox(width: 12),
                  Expanded(child: _miniOzetKarti("Kazanç", "${toplamGelir.toInt()}₺", Colors.green)),
                ],
              ),
              const SizedBox(height: 20),

              // Genişleyebilir Takvim Alanı
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.calendar_month, color: Color(0xFF0F172A)),
                      title: Text(
                        _seciliTarih.year == DateTime.now().year && _seciliTarih.month == DateTime.now().month && _seciliTarih.day == DateTime.now().day
                            ? "Bugünkü Randevular"
                            : "$formatliSeciliTarih Randevuları",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: IconButton(
                        icon: Icon(_takvimAcik ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                        onPressed: () => setState(() => _takvimAcik = !_takvimAcik),
                      ),
                      onTap: () => setState(() => _takvimAcik = !_takvimAcik),
                    ),
                    if (_takvimAcik) 
                      CalendarDatePicker(
                        initialDate: _seciliTarih,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        onDateChanged: (date) {
                          setState(() {
                            _seciliTarih = date;
                            _takvimAcik = false;
                          });
                        },
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              const Text("Randevu Listesi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              if (gunlukRandevular.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text("Bu tarihte randevu bulunmuyor.", style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: gunlukRandevular.length,
                  itemBuilder: (context, index) {
                    final r = gunlukRandevular[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFF0F172A).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(r['saat'] ?? "--:--", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        ),
                        title: Text(r['musteriAd'] ?? "İsimsiz Müşteri"),
                        subtitle: Text("${r['ustaIsmi']} - ${r['kisiTuru']}"),
                        trailing: Icon(
                          r['durum'] == 'aktif' ? Icons.check_circle_outline : Icons.history,
                          color: r['durum'] == 'aktif' ? Colors.green : Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _miniOzetKarti(String baslik, String deger, Color renk) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: renk.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: renk.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(baslik, style: TextStyle(color: renk, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(deger, style: TextStyle(color: renk, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _musterilerSekmesi() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('randevular').where('berberIsmi', isEqualTo: _salon!['isim']).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        // Müşteri bazlı gruplama
        Map<String, int> musteriRandevuSayilari = {};
        Map<String, String> musteriTelefonlari = {};

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final ad = data['musteriAd'] ?? "Bilinmiyor";
          final tel = data['musteriTelefon'] ?? "-";
          
          musteriRandevuSayilari[ad] = (musteriRandevuSayilari[ad] ?? 0) + 1;
          musteriTelefonlari[ad] = tel;
        }

        final siraliMusteriler = musteriRandevuSayilari.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: siraliMusteriler.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final entry = siraliMusteriler[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF0F172A),
                child: Text(entry.key[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
              ),
              title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(musteriTelefonlari[entry.key] ?? ""),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text("${entry.value} Randevu", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _ustalarSekmesi() {
    final List ustalar = _salon!['ustalar'] ?? [];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ustalar.length,
      itemBuilder: (context, index) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(ustalar[index]['isim'], style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(ustalar[index]['uzmanlik'] ?? "Berber"),
          trailing: IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () {}),
        ),
      ),
    );
  }

  Widget _hizmetlerSekmesi() {
    final List hizmetler = _salon!['hizmetler'] ?? [];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: hizmetler.length,
      itemBuilder: (context, index) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: const Icon(Icons.content_cut, color: Color(0xFF0F172A)),
          title: Text(hizmetler[index]['isim'], style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: Text("${hizmetler[index]['fiyat']} TL", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        ),
      ),
    );
  }

  void _eklemeDialogGoster(BuildContext context) {
    final tabIndex = _currentTabIndex;
    if (tabIndex != 2 && tabIndex != 3) return;

    final controller1 = TextEditingController();
    final controller2 = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tabIndex == 2 ? "Yeni Usta Ekle" : "Yeni Hizmet Ekle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: controller1, decoration: InputDecoration(labelText: tabIndex == 2 ? "Usta Adı Soyadı" : "Hizmet Adı")),
            TextField(
              controller: controller2, 
              decoration: InputDecoration(labelText: tabIndex == 2 ? "Uzmanlık Alanı" : "Fiyat (TL)"),
              keyboardType: tabIndex == 3 ? TextInputType.number : TextInputType.text,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              if (tabIndex == 2) {
                await _db.ustaEkle(_salon!['id'], {'isim': controller1.text, 'uzmanlik': controller2.text});
              } else {
                await _db.hizmetEkle(_salon!['id'], {'isim': controller1.text, 'fiyat': controller2.text});
              }
              Navigator.pop(context);
              _salonBilgileriniGetir();
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }
}
