import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- YORUM VE PUANLAMA SİSTEMİ (TRENDYOL STİLİ) ---
  Future<void> yorumKaydet({
    required String randevuId,
    required String ustaIsmi,
    required String salonIsmi,
    required String musteriAd,
    required double salonPuan,
    required String salonYorum,
    required double ustaPuan,
    required String ustaYorum,
  }) async {
    try {
      await _db.collection('yorumlar').add({
        'randevuId': randevuId,
        'ustaIsmi': ustaIsmi,
        'salonIsmi': salonIsmi,
        'musteriAd': musteriAd,
        'salonPuan': salonPuan,
        'salonYorum': salonYorum,
        'ustaPuan': ustaPuan,
        'ustaYorum': ustaYorum,
        'tarih': FieldValue.serverTimestamp(),
      });
      await _db.collection('randevular').doc(randevuId).update({'oylandi': 1, 'durum': 'tamamlandi'});
      await _puanlariHesaplaVeGuncelle(salonIsmi, ustaIsmi);
    } catch (e) {
      debugPrint("Yorum hatası: $e");
    }
  }

  Future<void> _puanlariHesaplaVeGuncelle(String salonIsmi, String ustaIsmi) async {
    var tumYorumlar = await _db.collection('yorumlar').where('salonIsmi', isEqualTo: salonIsmi).get();
    if (tumYorumlar.docs.isEmpty) return;

    double sTop = 0;
    for (var d in tumYorumlar.docs) sTop += (d['salonPuan'] as num).toDouble();
    double sYeni = double.parse((sTop / tumYorumlar.docs.length).toStringAsFixed(1));

    var uYorumlar = tumYorumlar.docs.where((d) => d['ustaIsmi'] == ustaIsmi).toList();
    double uYeni = 5.0;
    if (uYorumlar.isNotEmpty) {
      double uTop = 0;
      for (var d in uYorumlar) uTop += (d['ustaPuan'] as num).toDouble();
      uYeni = double.parse((uTop / uYorumlar.length).toStringAsFixed(1));
    }

    var sSnap = await _db.collection('salonlar').where('isim', isEqualTo: salonIsmi).limit(1).get();
    if (sSnap.docs.isNotEmpty) {
      var sData = sSnap.docs.first.data();
      List ustalar = List.from(sData['ustalar'] ?? []);
      for (var i = 0; i < ustalar.length; i++) {
        if (ustalar[i]['isim'] == ustaIsmi) ustalar[i]['puan'] = uYeni;
      }
      await _db.collection('salonlar').doc(sSnap.docs.first.id).update({'puan': sYeni, 'ustalar': ustalar});
    }
  }

  // SIRALAMAYI BELLEKTE YAPIYORUZ (İndeks hatasını önlemek için)
  Stream<List<Map<String, dynamic>>> salonYorumlariniGetir(String salonIsmi) {
    return _db.collection('yorumlar')
        .where('salonIsmi', isEqualTo: salonIsmi)
        .snapshots()
        .map((sn) {
          var list = sn.docs.map((d) => d.data()).toList();
          list.sort((a, b) => ((b['tarih'] as Timestamp?) ?? Timestamp.now()).compareTo((a['tarih'] as Timestamp?) ?? Timestamp.now()));
          return list;
        });
  }

  Stream<List<Map<String, dynamic>>> ustaYorumlariniGetir(String ustaIsmi) {
    return _db.collection('yorumlar')
        .where('ustaIsmi', isEqualTo: ustaIsmi)
        .snapshots()
        .map((sn) {
          var list = sn.docs.map((d) => d.data()).toList();
          list.sort((a, b) => ((b['tarih'] as Timestamp?) ?? Timestamp.now()).compareTo((a['tarih'] as Timestamp?) ?? Timestamp.now()));
          return list;
        });
  }

  // --- DİĞER METODLAR ---
  Future<void> kullaniciKaydet({required String adSoyad, required String telefon, String? profilResmi}) async {
    await _db.collection('users').doc("$adSoyad ($telefon)").set({'adSoyad': adSoyad, 'telefon': telefon.trim(), 'profilResmi': profilResmi ?? '', 'kayitTarihi': FieldValue.serverTimestamp(), 'rol': 'musteri'}, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> kullaniciGetir(String t) async {
    var s = await _db.collection('users').where('telefon', isEqualTo: t.trim()).limit(1).get();
    return s.docs.isNotEmpty ? s.docs.first.data() : null;
  }

  Future<void> randevuOlustur({required String musteriTelefon, required String berberIsmi, required String ustaIsmi, required String tarih, required String saat, required String kisiTuru, required String musteriAd}) async {
    await _db.collection('randevular').add({'musteriTelefon': musteriTelefon.trim(), 'musteriAd': musteriAd, 'berberIsmi': berberIsmi, 'ustaIsmi': ustaIsmi, 'tarih': tarih, 'saat': saat, 'kisiTuru': kisiTuru, 'durum': 'aktif', 'onayDurumu': 'bekliyor', 'oylandi': 0, 'olusturmaTarihi': FieldValue.serverTimestamp()});
  }

  Future<List<Map<String, dynamic>>> musterininRandevulariniGetir(String t) async {
    var s = await _db.collection('randevular').where('musteriTelefon', isEqualTo: t.trim()).get();
    var l = s.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    l.sort((a, b) => ((b['olusturmaTarihi'] as Timestamp?) ?? Timestamp.now()).compareTo((a['olusturmaTarihi'] as Timestamp?) ?? Timestamp.now()));
    return l;
  }

  Future<int> aktifRandevuSayisi(String t) async {
    var s = await _db.collection('randevular').where('musteriTelefon', isEqualTo: t.trim()).where('durum', isEqualTo: 'aktif').get();
    return s.docs.length;
  }

  Future<void> randevuyuTamamlaVeOyla(String id) async {
    await _db.collection('randevular').doc(id).update({'durum': 'tamamlandi'});
  }

  Stream<List<Map<String, dynamic>>> salonRandevulariniGetir(String s) {
    return _db.collection('randevular').where('berberIsmi', isEqualTo: s).snapshots().map((sn) => sn.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Future<Map<String, dynamic>?> salonGetirByEmail(String e) async {
    var s = await _db.collection('salonlar').where('sahipEmail', isEqualTo: e).limit(1).get();
    if (s.docs.isEmpty) return null;
    var d = s.docs.first.data(); d['id'] = s.docs.first.id; return d;
  }

  Stream<List<Map<String, dynamic>>> salonlariGetir(String sehir) {
    return _db.collection('salonlar').snapshots().map((sn) => sn.docs.map((d) => {...d.data(), 'id': d.id}).where((s) => (s['sehir'] ?? "").toString().toLowerCase().contains(sehir.split(',')[0].toLowerCase().trim())).toList());
  }

  Future<void> ustaEkle(String id, Map<String, dynamic> u) async { await _db.collection('salonlar').doc(id).update({'ustalar': FieldValue.arrayUnion([u])}); }
  Future<void> hizmetEkle(String id, Map<String, dynamic> h) async { await _db.collection('salonlar').doc(id).update({'hizmetler': FieldValue.arrayUnion([h])}); }
}
