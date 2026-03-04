import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import 'sms_onay_ekrani.dart';

class RandevularEkrani extends StatefulWidget {
  final String? musteriTelefon;
  const RandevularEkrani({super.key, this.musteriTelefon});

  @override
  State<RandevularEkrani> createState() => _RandevularEkraniState();
}

class _RandevularEkraniState extends State<RandevularEkrani> {
  final DatabaseService _dbService = DatabaseService();
  String? _currentUserName;
  
  // Örnek veriler silindi
  final List<Map<String, dynamic>> _eskiRandevular = [];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  void _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserName = prefs.getString('user_name');
    });
  }

  void _girisPopupGoster(BuildContext context) {
    final nameC = TextEditingController();
    final phoneC = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 25),
              const Text("Giriş Yap / Kayıt Ol", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Randevularınızı görmek için bilgilerinizi girin.", style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 30),
              TextField(
                controller: nameC,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline), hintText: "Adınız Soyadınız"),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: phoneC,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
                decoration: const InputDecoration(prefixIcon: Icon(Icons.phone_outlined), hintText: "05xx xxx xx xx"),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  String name = nameC.text;
                  String phone = phoneC.text;
                  if (name.isNotEmpty && phone.length == 11 && phone.startsWith('0')) {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SmsOnayEkrani(
                          isLogin: true,
                          userName: name,
                          musteriTelefon: phone,
                          berberIsmi: "",
                          ustaIsmi: "",
                          tarih: "",
                          saat: "",
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen bilgileri doğru girin.")));
                  }
                },
                child: const Text("SMS DOĞRULAMASINA GEÇ"),
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isGuest = widget.musteriTelefon == null;

    return Scaffold(
      appBar: AppBar(title: const Text("Randevularım")),
      body: isGuest 
      ? _ziyaretciGorunumu(context)
      : FutureBuilder<List<Map<String, dynamic>>>(
        future: _dbService.musterininRandevulariniGetir(widget.musteriTelefon!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final allRandevular = snapshot.data ?? [];
          final aktifRandevular = allRandevular.where((r) => r['durum'] == 'aktif').toList();
          final gecmisRandevular = allRandevular.where((r) => r['durum'] != 'aktif').toList();

          if (aktifRandevular.isEmpty && gecmisRandevular.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  const Text("Henüz bir randevunuz bulunmuyor.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (aktifRandevular.isNotEmpty) ...[
                const Text("Aktif Randevular", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                ...aktifRandevular.map((r) => _randevuKarti(r, isAktif: true)),
                const SizedBox(height: 30),
              ],
              if (gecmisRandevular.isNotEmpty) ...[
                const Text("Geçmiş Randevular", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                ...gecmisRandevular.map((r) => _randevuKarti(r, isAktif: false)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _ziyaretciGorunumu(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 100, color: Colors.grey[300]),
            const SizedBox(height: 24),
            const Text(
              "Randevularınızı görmek için lütfen giriş yapın.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _girisPopupGoster(context),
              child: const Text("GİRİŞ YAP / KAYIT OL"),
            ),
          ],
        ),
      ),
    );
  }

  void _siraliOyVer(Map<String, dynamic> r) {
    int salonPuani = 0;
    final TextEditingController salonYorumC = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: Text("${r['berberIsmi']} Oylayın"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Salondan memnun kaldınız mı?"),
                const SizedBox(height: 20),
                _yildizSecici((p) => setS(() => salonPuani = p), salonPuani),
                const SizedBox(height: 20),
                TextField(
                  controller: salonYorumC,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Salon hakkındaki deneyiminizi yazın...",
                    fillColor: Colors.grey[100],
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İPTAL")),
            ElevatedButton(
              onPressed: salonPuani == 0 ? null : () {
                Navigator.pop(context);
                _ustaOyVeYorumPopup(r, salonPuani, salonYorumC.text);
              }, 
              child: const Text("SONRAKİ: USTA OYLA")
            ),
          ],
        ),
      ),
    );
  }

  void _ustaOyVeYorumPopup(Map<String, dynamic> r, int salonP, String salonYorum) {
    int ustaPuan = 0;
    final TextEditingController ustaYorumC = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: Text("${r['ustaIsmi']} Oylayın"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Ustanın hizmetinden memnun kaldınız mı?"),
                const SizedBox(height: 20),
                _yildizSecici((p) => setS(() => ustaPuan = p), ustaPuan),
                const SizedBox(height: 20),
                TextField(
                  controller: ustaYorumC,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Usta hakkındaki deneyiminizi yazın...",
                    fillColor: Colors.grey[100],
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: ustaPuan == 0 ? null : () async {
                Navigator.pop(context);
                if (r['id'] > 0) {
                  await _dbService.yorumKaydet(
                    ustaIsmi: r['ustaIsmi'], 
                    salonIsmi: r['berberIsmi'], 
                    musteriAd: _currentUserName ?? "Kullanıcı", 
                    puan: ustaPuan.toDouble(), 
                    yorumMetni: "Salon: $salonYorum\nUsta: ${ustaYorumC.text}"
                  );
                  await _dbService.randevuyuTamamlaVeOyla(r['id']);
                  setState(() {});
                }
              }, 
              child: const Text("OYLAMAYI TAMAMLA")
            ),
          ],
        ),
      ),
    );
  }

  Widget _yildizSecici(Function(int) onSelect, int puan) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) => IconButton(
        icon: Icon(
          index < puan ? Icons.star_rounded : Icons.star_outline_rounded,
          color: Colors.amber,
          size: 32,
        ),
        onPressed: () => onSelect(index + 1),
      )),
    );
  }

  Widget _randevuKarti(Map<String, dynamic> r, {required bool isAktif}) {
    final colorScheme = Theme.of(context).colorScheme;
    bool oylandi = r['oylandi'] == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: isAktif ? colorScheme.primary.withOpacity(0.05) : Colors.grey[50], borderRadius: BorderRadius.circular(16)),
                child: Icon(isAktif ? Icons.event_available : Icons.history, color: isAktif ? colorScheme.primary : Colors.grey[400]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r['berberIsmi'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    Text("Usta: ${r['ustaIsmi']}", style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 12, color: colorScheme.secondary),
                        const SizedBox(width: 4),
                        Text("${r['tarih']} - ${r['saat']}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isAktif)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: oylandi ? const Color(0xFF38BDF8).withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: Text(
                    oylandi ? "Değerlendirildi" : "Tamamlandı",
                    style: TextStyle(color: oylandi ? const Color(0xFF38BDF8) : Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          if (isAktif) ...[
            const Divider(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harita uygulamasına yönlendiriliyorsunuz..."), behavior: SnackBarBehavior.floating));
                },
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text("KONUMA GİT"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary.withOpacity(0.05),
                  foregroundColor: colorScheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          if (!isAktif) ...[
            const Divider(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: oylandi ? null : () => _siraliOyVer(r),
                icon: Icon(oylandi ? Icons.verified_rounded : Icons.star_half_rounded, size: 18),
                label: Text(oylandi ? "DEĞERLENDİRME TAMAMLANDI" : "DEĞERLENDİR VE YORUM YAP"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: oylandi ? Colors.grey[100] : Colors.amber,
                  foregroundColor: oylandi ? Colors.grey[400] : Colors.black87,
                  elevation: oylandi ? 0 : 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
