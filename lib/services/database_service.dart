import 'cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Yeni Müşteri Kaydı
  Future<void> musteriKaydet(String adSoyad, String telefon) async {
    try {
      await _db.collection('musteriler').doc(telefon).set({
        'adSoyad': adSoyad,
        'telefon': telefon,
        'kayitTarihi': FieldValue.serverTimestamp(),
      });
      print("Müşteri başarıyla kaydedildi.");
    } catch (e) {
      print("Müşteri kaydında hata: $e");
    }
  }

  // Randevu Al
  Future<void> randevuOlustur({
    required String musteriTelefon,
    required String berberIsmi,
    required String ustaIsmi,
    required String tarih,
    required String saat,
  }) async {
    try {
      await _db.collection('randevular').add({
        'musteriTelefon': musteriTelefon,
        'berberIsmi': berberIsmi,
        'ustaIsmi': ustaIsmi,
        'tarih': tarih,
        'saat': saat,
        'olusturulmaTarihi': FieldValue.serverTimestamp(),
        'durum': 'aktif',
      });
      print("Randevu başarıyla oluşturuldu.");
    } catch (e) {
      print("Randevu oluşturulurken hata: $e");
    }
  }

  // Müşterinin Randevularını Getir
  Stream<QuerySnapshot> musterininRandevulariniGetir(String telefon) {
    return _db
        .collection('randevular')
        .where('musteriTelefon', isEqualTo: telefon)
        .orderBy('olusturulmaTarihi', descending: true)
        .snapshots();
  }
}
