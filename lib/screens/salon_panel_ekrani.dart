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

class _SalonPanelEkraniState extends State<SalonPanelEkrani> with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  Map<String, dynamic>? _salon;
  bool _yukleniyor = true;
  DateTime _seciliTarih = DateTime.now();
  bool _takvimAcik = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {}); 
    });
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
    if (_yukleniyor) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_salon == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text("Salon bulunamadı.")));

    return Scaffold(
      appBar: AppBar(
        title: Text(_salon!['isim'] ?? "Salon Paneli"),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.analytics_outlined), text: "İstatistik"),
            Tab(icon: Icon(Icons.people_alt_outlined), text: "Müşteriler"),
            Tab(icon: Icon(Icons.person_outline), text: "Ustalar"),
            Tab(icon: Icon(Icons.list_alt_outlined), text: "Hizmetler"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _istatistikSekmesi(),
          _musterilerSekmesi(),
          _ustalarSekmesi(),
          _hizmetlerSekmesi(),
        ],
      ),
      floatingActionButton: (_tabController.index == 2 || _tabController.index == 3)
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF4E342E),
              foregroundColor: Colors.white,
              onPressed: () => _eklemeDialogGoster(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  // --- İSTATİSTİK SEKMESİ ---
  Widget _istatistikSekmesi() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.salonRandevulariniGetir(_salon!['isim']),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final tumRandevular = snapshot.data!;
        final formatliSeciliTarih = DateFormat('dd.MM.yyyy').format(_seciliTarih);
        final gunlukRandevular = tumRandevular.where((r) => r['tarih'] == formatliSeciliTarih).toList();
        
        double toplamGelir = tumRandevular.length * 200.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.calendar_month, color: Color(0xFF4E342E)),
                      title: Text(formatliSeciliTarih, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Icon(_takvimAcik ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
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
              const Text("Günlük Randevular", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (gunlukRandevular.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text("Randevu yok.")))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: gunlukRandevular.length,
                  itemBuilder: (context, index) {
                    final r = gunlukRandevular[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: const Color(0xFF4E342E), child: Text(r['saat'] ?? "", style: const TextStyle(color: Colors.white, fontSize: 10))),
                        title: Text(r['musteriAd'] ?? "Müşteri"),
                        subtitle: Text(r['ustaIsmi'] ?? ""),
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
      decoration: BoxDecoration(color: renk.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [Text(baslik, style: TextStyle(color: renk, fontSize: 12)), Text(deger, style: TextStyle(color: renk, fontSize: 18, fontWeight: FontWeight.bold))]),
    );
  }

  // --- MÜŞTERİLER SEKMESİ ---
  Widget _musterilerSekmesi() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('randevular').where('berberIsmi', isEqualTo: _salon!['isim']).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        Map<String, int> musteriler = {};
        for (var doc in snapshot.data!.docs) {
          final ad = doc['musteriAd'] ?? "Bilinmiyor";
          musteriler[ad] = (musteriler[ad] ?? 0) + 1;
        }
        final liste = musteriler.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        return ListView.builder(
          itemCount: liste.length,
          itemBuilder: (context, index) => ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(liste[index].key),
            trailing: Chip(label: Text("${liste[index].value} Randevu")),
          ),
        );
      },
    );
  }

  // --- USTALAR SEKMESİ ---
  Widget _ustalarSekmesi() {
    final List ustalar = _salon!['ustalar'] ?? [];
    if (ustalar.isEmpty) return const Center(child: Text("Henüz usta eklenmemiş."));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ustalar.length,
      itemBuilder: (context, index) => Card(
        child: ListTile(
          leading: CircleAvatar(backgroundImage: NetworkImage(ustalar[index]['resim'] ?? 'https://i.pravatar.cc/150?u=${ustalar[index]['isim']}')),
          title: Text(ustalar[index]['isim'], style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(ustalar[index]['uzmanlik'] ?? "Berber"),
          trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _silmeOnayi(index, true)),
        ),
      ),
    );
  }

  // --- HİZMETLER SEKMESİ ---
  Widget _hizmetlerSekmesi() {
    final List hizmetler = _salon!['hizmetler'] ?? [];
    if (hizmetler.isEmpty) return const Center(child: Text("Henüz hizmet eklenmemiş."));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: hizmetler.length,
      itemBuilder: (context, index) => Card(
        child: ListTile(
          leading: const Icon(Icons.content_cut, color: Color(0xFF4E342E)),
          title: Text(hizmetler[index]['isim'], style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("${hizmetler[index]['fiyat']} TL", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _silmeOnayi(index, false)),
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
        title: const Text("Emin misiniz?"),
        content: Text("Bu ${isUsta ? 'ustayı' : 'hizmeti'} silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          TextButton(
            onPressed: () async {
              List liste = List.from(isUsta ? _salon!['ustalar'] : _salon!['hizmetler']);
              liste.removeAt(index);
              await FirebaseFirestore.instance.collection('salonlar').doc(_salon!['id']).update({
                isUsta ? 'ustalar' : 'hizmetler': liste
              });
              Navigator.pop(context);
              _salonBilgileriniGetir();
            }, 
            child: const Text("Sil", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  void _eklemeDialogGoster(BuildContext context) {
    final isUstaSecili = _tabController.index == 2;
    final controller1 = TextEditingController();
    final controller2 = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isUstaSecili ? "Yeni Usta Ekle" : "Yeni Hizmet Ekle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller1, 
              // Herhangi bir filtreleme koymadık, Türkçe karakterleri otomatik kabul eder.
              keyboardType: TextInputType.text,
              decoration: InputDecoration(labelText: isUstaSecili ? "Usta Adı Soyadı" : "Hizmet Adı")
            ),
            TextField(
              controller: controller2, 
              decoration: InputDecoration(labelText: isUstaSecili ? "Uzmanlık (Örn: Saç & Sakal)" : "Fiyat (TL)"),
              keyboardType: isUstaSecili ? TextInputType.text : TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              if (controller1.text.isEmpty || controller2.text.isEmpty) return;

              if (isUstaSecili) {
                final yeniUsta = {
                  'isim': controller1.text,
                  'uzmanlik': controller2.text,
                  'resim': 'https://i.pravatar.cc/150?u=${controller1.text}',
                  'puan': 5.0,
                  'doluSaatler': []
                };
                await _db.ustaEkle(_salon!['id'], yeniUsta);
              } else {
                final yeniHizmet = {
                  'isim': controller1.text,
                  'fiyat': int.tryParse(controller2.text) ?? 0
                };
                await _db.hizmetEkle(_salon!['id'], yeniHizmet);
              }
              
              if (mounted) {
                Navigator.pop(context);
                _salonBilgileriniGetir(); 
              }
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }
}
