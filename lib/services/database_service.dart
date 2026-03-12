import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- MÜŞTERİ İŞLEMLERİ ---
  Future<void> musteriKaydet(String adSoyad, String telefon) async {
    await _db.collection('musteriler').doc(telefon).set({
      'adSoyad': adSoyad,
      'telefon': telefon,
      'kayitTarihi': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> musteriGetir(String telefon) async {
    var doc = await _db.collection('musteriler').doc(telefon).get();
    return doc.exists ? doc.data() : null;
  }

  // --- RANDEVU İŞLEMLERİ ---
  Future<void> randevuOlustur({
    required String musteriTelefon,
    required String berberIsmi,
    required String ustaIsmi,
    required String tarih,
    required String saat,
    required String kisiTuru,
  }) async {
    await _db.collection('randevular').add({
      'musteriTelefon': musteriTelefon,
      'berberIsmi': berberIsmi,
      'ustaIsmi': ustaIsmi,
      'tarih': tarih,
      'saat': saat,
      'kisiTuru': kisiTuru,
      'durum': 'aktif',
      'onayDurumu': 'bekliyor',
      'oylandi': 0,
      'olusturmaTarihi': FieldValue.serverTimestamp(),
    });
  }

  // UI'da StreamBuilder yerine FutureBuilder kullanıldığı durumlar için Future versiyonu
  Future<List<Map<String, dynamic>>> musterininRandevulariniGetir(String telefon) async {
    var snapshot = await _db.collection('randevular')
        .where('musteriTelefon', isEqualTo: telefon)
        .orderBy('olusturmaTarihi', descending: true)
        .get();
    
    return snapshot.docs.map((doc) {
      var data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Stream<List<Map<String, dynamic>>> musterininRandevulariniStream(String telefon) {
    return _db.collection('randevular')
        .where('musteriTelefon', isEqualTo: telefon)
        .orderBy('olusturmaTarihi', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  Future<int> aktifRandevuSayisi(String telefon) async {
    var snapshot = await _db.collection('randevular')
        .where('musteriTelefon', isEqualTo: telefon)
        .where('durum', isEqualTo: 'aktif')
        .get();
    return snapshot.docs.length;
  }

  Future<void> randevuyuTamamlaVeOyla(String id) async {
    await _db.collection('randevular').doc(id).update({
      'durum': 'Tamamlandı',
      'oylandi': 1
    });
  }

  // --- YORUM İŞLEMLERİ ---
  Future<void> yorumKaydet({
    required String ustaIsmi,
    required String salonIsmi,
    required String musteriAd,
    required double puan,
    required String yorumMetni,
  }) async {
    await _db.collection('yorumlar').add({
      'ustaIsmi': ustaIsmi,
      'salonIsmi': salonIsmi,
      'musteriAd': musteriAd,
      'puan': puan,
      'yorumMetni': yorumMetni,
      'tarih': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> ustaYorumlariniGetir(String ustaIsmi) async {
    var snapshot = await _db.collection('yorumlar')
        .where('ustaIsmi', isEqualTo: ustaIsmi)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // --- SALON İŞLEMLERİ ---
  Stream<List<Map<String, dynamic>>> salonlariGetir(String sehir) {
    return _db.collection('salonlar')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .where((salon) {
              String sSehir = (salon['sehir'] ?? "").toString().toLowerCase();
              return sSehir.contains(sehir.split(',')[0].toLowerCase().trim());
            })
            .toList());
  }

  Future<Map<String, dynamic>?> oylanmamisGecmisRandevuGetir(String telefon) async {
    var snapshot = await _db.collection('randevular')
        .where('musteriTelefon', isEqualTo: telefon)
        .where('oylandi', isEqualTo: 0)
        .where('durum', isEqualTo: 'aktif')
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      var data = snapshot.docs.first.data();
      data['id'] = snapshot.docs.first.id;
      return data;
    }
    return null;
  }

  Future<Map<String, dynamic>?> yaklasanBugunkuRandevuyuGetir(String telefon) async {
    // Basitleştirilmiş kontrol
    return null;
  }
}
