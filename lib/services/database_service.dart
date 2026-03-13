import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- KULLANICI İŞLEMLERİ ---
  
  Future<void> kullaniciKaydet({
    required String adSoyad, 
    required String telefon,
    String? profilResmi,
  }) async {
    String docId = "$adSoyad ($telefon)";
    await _db.collection('users').doc(docId).set({
      'adSoyad': adSoyad,
      'telefon': telefon,
      'profilResmi': profilResmi ?? '',
      'kayitTarihi': FieldValue.serverTimestamp(),
      'rol': 'musteri',
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> kullaniciGetir(String telefon) async {
    var snapshot = await _db.collection('users')
        .where('telefon', isEqualTo: telefon.trim())
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) return snapshot.docs.first.data();
    return null;
  }

  // --- RANDEVU İŞLEMLERİ ---
  
  Future<void> randevuOlustur({
    required String musteriTelefon,
    required String berberIsmi,
    required String ustaIsmi,
    required String tarih,
    required String saat,
    required String kisiTuru,
    required String musteriAd,
  }) async {
    // BURASI ÇALIŞTIĞI AN KOLEKSİYON OTOMATİK OLUŞUR
    await _db.collection('randevular').add({
      'musteriTelefon': musteriTelefon.trim(),
      'musteriAd': musteriAd,
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

  Future<List<Map<String, dynamic>>> musterininRandevulariniGetir(String telefon) async {
    try {
      var snap = await _db.collection('randevular')
          .where('musteriTelefon', isEqualTo: telefon.trim())
          .get();
      
      var liste = snap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
      liste.sort((a, b) {
        var t1 = a['olusturmaTarihi'] as Timestamp?;
        var t2 = b['olusturmaTarihi'] as Timestamp?;
        if (t1 == null || t2 == null) return 0;
        return t2.compareTo(t1);
      });
      return liste;
    } catch (e) {
      return [];
    }
  }

  Future<int> aktifRandevuSayisi(String telefon) async {
    if (telefon.isEmpty) return 0;
    try {
      // Koleksiyon yoksa veya hata oluşursa catch bloğuna düşer ve 0 döner
      var snapshot = await _db.collection('randevular')
          .where('musteriTelefon', isEqualTo: telefon.trim())
          .where('durum', isEqualTo: 'aktif')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0; // Koleksiyon yoksa 0 döndür, böylece kullanıcı randevu alabilsin
    }
  }

  Future<void> randevuyuTamamlaVeOyla(String randevuId) async {
    await _db.collection('randevular').doc(randevuId).update({
      'durum': 'tamamlandi',
      'oylandi': 1,
    });
  }

  // Geriye dönük uyumluluk metodları
  Future<void> musteriKaydet(String ad, String tel) => kullaniciKaydet(adSoyad: ad, telefon: tel);
  Future<Map<String, dynamic>?> musteriGetir(String tel) => kullaniciGetir(tel);

  // --- DİĞER ---
  Future<void> yorumKaydet({required String ustaIsmi, required String salonIsmi, required String musteriAd, required double puan, required String yorumMetni}) async {
    await _db.collection('yorumlar').add({
      'ustaIsmi': ustaIsmi, 'salonIsmi': salonIsmi, 'musteriAd': musteriAd, 'puan': puan, 'yorumMetni': yorumMetni, 'tarih': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> salonGetirByEmail(String email) async {
    var snapshot = await _db.collection('salonlar').where('sahipEmail', isEqualTo: email).limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      var data = snapshot.docs.first.data();
      data['id'] = snapshot.docs.first.id;
      return data;
    }
    return null;
  }

  Stream<List<Map<String, dynamic>>> salonRandevulariniGetir(String salonIsmi) {
    return _db.collection('randevular').where('berberIsmi', isEqualTo: salonIsmi).snapshots().map((snap) => snap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  Future<void> ustaEkle(String salonId, Map<String, dynamic> usta) async {
    await _db.collection('salonlar').doc(salonId).update({'ustalar': FieldValue.arrayUnion([usta])});
  }

  Future<void> hizmetEkle(String salonId, Map<String, dynamic> hizmet) async {
    await _db.collection('salonlar').doc(salonId).update({'hizmetler': FieldValue.arrayUnion([hizmet])});
  }

  Stream<List<Map<String, dynamic>>> salonlariGetir(String sehir) {
    return _db.collection('salonlar').snapshots().map((snap) => snap.docs.map((doc) => {...doc.data(), 'id': doc.id}).where((salon) {
      String sSehir = (salon['sehir'] ?? "").toString().toLowerCase();
      return sSehir.contains(sehir.split(',')[0].toLowerCase().trim());
    }).toList());
  }

  Future<List<Map<String, dynamic>>> ustaYorumlariniGetir(String ustaIsmi) async {
    var snapshot = await _db.collection('yorumlar').where('ustaIsmi', isEqualTo: ustaIsmi).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
