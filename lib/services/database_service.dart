import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- KULLANICI PROFİL RESMİ YÜKLEME ---
  Future<String?> profilResmiYukle(File file, String telefon) async {
    try {
      String fileName = "profile_${telefon}.jpg";
      Reference ref = _storage.ref().child('users/$telefon/$fileName');
      await ref.putFile(file);
      String url = await ref.getDownloadURL();
      var snap = await _db.collection('users').where('telefon', isEqualTo: telefon.trim()).get();
      if (snap.docs.isNotEmpty) {
        await snap.docs.first.reference.update({'profilResmi': url});
      }
      return url;
    } catch (e) {
      debugPrint("Profil resmi yükleme hatası: $e");
      return null;
    }
  }

  // --- KULLANICI İŞLEMLERİ ---
  Future<void> kullaniciKaydet({
    required String adSoyad, 
    required String telefon, 
    String? profilResmi,
    String? dogumTarihi,
    String? cinsiyet,
    String? sehir,
    String? email,
    bool yeniKayit = false,
  }) async {
    final String cleanPhone = telefon.trim();
    final String newDocId = "$adSoyad ($cleanPhone)";
    var existingDocs = await _db.collection('users').where('telefon', isEqualTo: cleanPhone).get();
    for (var doc in existingDocs.docs) {
      if (doc.id != newDocId) await doc.reference.delete();
    }
    Map<String, dynamic> data = {
      'adSoyad': adSoyad,
      'telefon': cleanPhone,
      'sonGuncelleme': FieldValue.serverTimestamp(),
    };
    if (yeniKayit) {
      data['profilResmi'] = "";
      data['dogumTarihi'] = "";
      data['cinsiyet'] = "";
      data['sehir'] = "";
      data['email'] = "";
      data['rol'] = 'musteri';
      data['kayitTarihi'] = FieldValue.serverTimestamp();
    } else {
      if (profilResmi != null) data['profilResmi'] = profilResmi;
      if (dogumTarihi != null) data['dogumTarihi'] = dogumTarihi;
      if (cinsiyet != null) data['cinsiyet'] = cinsiyet;
      if (sehir != null) data['sehir'] = sehir;
      if (email != null) data['email'] = email;
    }
    await _db.collection('users').doc(newDocId).set(data, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> kullaniciGetir(String t) async {
    var s = await _db.collection('users').where('telefon', isEqualTo: t.trim()).limit(1).get();
    return s.docs.isNotEmpty ? s.docs.first.data() : null;
  }

  // --- RANDEVU İŞLEMLERİ ---
  Future<void> randevuOlustur({required String musteriTelefon, required String berberIsmi, required String ustaIsmi, required String tarih, required String saat, required String kisiTuru, required String musteriAd}) async {
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
      'olusturmaTarihi': FieldValue.serverTimestamp()
    });
  }

  Future<List<Map<String, dynamic>>> musterininRandevulariniGetir(String t) async {
    var s = await _db.collection('randevular').where('musteriTelefon', isEqualTo: t.trim()).get();
    var l = s.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    l.sort((a, b) => ((b['olusturmaTarihi'] as Timestamp?) ?? Timestamp.now()).compareTo((a['olusturmaTarihi'] as Timestamp?) ?? Timestamp.now()));
    return l;
  }

  Future<void> randevuSil(String id) async {
    await _db.collection('randevular').doc(id).delete();
  }

  Future<int> aktifRandevuSayisi(String t) async {
    var s = await _db.collection('randevular').where('musteriTelefon', isEqualTo: t.trim()).where('durum', isEqualTo: 'aktif').get();
    return s.docs.length;
  }

  Stream<List<Map<String, dynamic>>> salonRandevulariniGetir(String s) {
    return _db.collection('randevular').where('berberIsmi', isEqualTo: s).snapshots().map((sn) => sn.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Future<List<String>> doluSaatleriGetir(String berberIsmi, String ustaIsmi, String tarih) async {
    var snap = await _db.collection('randevular')
        .where('berberIsmi', isEqualTo: berberIsmi)
        .where('ustaIsmi', isEqualTo: ustaIsmi)
        .where('tarih', isEqualTo: tarih)
        .where('durum', isEqualTo: 'aktif')
        .get();
    return snap.docs.map((d) => d['saat'].toString()).toList();
  }

  Future<Map<String, int>> dolulukOranlariniGetir(String berberIsmi, String ustaIsmi) async {
    var snap = await _db.collection('randevular')
        .where('berberIsmi', isEqualTo: berberIsmi)
        .where('ustaIsmi', isEqualTo: ustaIsmi)
        .where('durum', isEqualTo: 'aktif')
        .get();
    Map<String, int> counts = {};
    for (var doc in snap.docs) {
      String t = doc['tarih'];
      counts[t] = (counts[t] ?? 0) + 1;
    }
    return counts;
  }

  // --- SALON İŞLEMLERİ ---
  Stream<List<Map<String, dynamic>>> salonlariGetir(String sehir) {
    return _db.collection('salonlar').snapshots().map((sn) => sn.docs.map((d) => {...d.data(), 'id': d.id}).where((s) => (s['sehir'] ?? "").toString().toLowerCase().contains(sehir.split(',')[0].toLowerCase().trim())).toList());
  }

  Future<Map<String, dynamic>?> salonGetirByEmail(String e) async {
    var s = await _db.collection('salonlar').where('sahipEmail', isEqualTo: e).limit(1).get();
    if (s.docs.isEmpty) return null;
    var d = s.docs.first.data(); d['id'] = s.docs.first.id; return d;
  }

  Future<void> ustaEkle(String id, Map<String, dynamic> u) async { await _db.collection('salonlar').doc(id).update({'ustalar': FieldValue.arrayUnion([u])}); }
  Future<void> hizmetEkle(String id, Map<String, dynamic> h) async { await _db.collection('salonlar').doc(id).update({'hizmetler': FieldValue.arrayUnion([h])}); }

  // --- YORUM VE PUANLAMA SİSTEMİ (ORTALAMA HESAPLAMA DÜZELTİLDİ) ---
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
    // 1. O salona ait tüm yorumları çek
    var yorumlarSnap = await _db.collection('yorumlar').where('salonIsmi', isEqualTo: salonIsmi).get();
    var tumYorumlar = yorumlarSnap.docs;
    
    if (tumYorumlar.isEmpty) return;

    // 2. Salon Genel Ortalaması Hesapla
    double sToplam = 0;
    for (var doc in tumYorumlar) {
      sToplam += (doc.data()['salonPuan'] as num? ?? 0).toDouble();
    }
    double sYeniPuan = double.parse((sToplam / tumYorumlar.length).toStringAsFixed(1));

    // 3. Spesifik Usta Ortalaması Hesapla
    var ustaYorumlar = tumYorumlar.where((d) => d.data()['ustaIsmi'] == ustaIsmi).toList();
    double uYeniPuan = 0.0;
    
    if (ustaYorumlar.isNotEmpty) {
      double uToplam = 0;
      for (var doc in ustaYorumlar) {
        uToplam += (doc.data()['ustaPuan'] as num? ?? 0).toDouble();
      }
      uYeniPuan = double.parse((uToplam / ustaYorumlar.length).toStringAsFixed(1));
    }

    // 4. Salon dökümanındaki puanları güncelle
    var salonSnap = await _db.collection('salonlar').where('isim', isEqualTo: salonIsmi).limit(1).get();
    if (salonSnap.docs.isNotEmpty) {
      var doc = salonSnap.docs.first;
      List ustalar = List.from(doc.data()['ustalar'] ?? []);
      
      for (var i = 0; i < ustalar.length; i++) {
        if (ustalar[i]['isim'] == ustaIsmi) {
          ustalar[i]['puan'] = uYeniPuan;
        }
      }
      
      await doc.reference.update({
        'puan': sYeniPuan,
        'ustalar': ustalar
      });
    }
  }

  Stream<List<Map<String, dynamic>>> salonYorumlariniGetir(String salonIsmi) {
    return _db.collection('yorumlar').where('salonIsmi', isEqualTo: salonIsmi).snapshots().map((sn) {
      var list = sn.docs.map((d) => d.data()).toList();
      list.sort((a, b) => ((b['tarih'] as Timestamp?) ?? Timestamp.now()).compareTo((a['tarih'] as Timestamp?) ?? Timestamp.now()));
      return list;
    });
  }

  Stream<List<Map<String, dynamic>>> ustaYorumlariniGetir(String ustaIsmi) {
    return _db.collection('yorumlar').where('ustaIsmi', isEqualTo: ustaIsmi).snapshots().map((sn) {
      var list = sn.docs.map((d) => d.data()).toList();
      list.sort((a, b) => ((b['tarih'] as Timestamp?) ?? Timestamp.now()).compareTo((a['tarih'] as Timestamp?) ?? Timestamp.now()));
      return list;
    });
  }

  // --- GALERİ İŞLEMLERİ ---
  Future<String?> fotografYukle(File file, String salonId) async {
    try {
      String fileName = "galeri_${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference ref = _storage.ref().child('salonlar/$salonId/galeri/$fileName');
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String url = await snapshot.ref.getDownloadURL();
      await _db.collection('salonlar').doc(salonId).update({'galeri': FieldValue.arrayUnion([url])});
      return url;
    } catch (e) { return null; }
  }

  Future<void> fotografSil(String salonId, String url) async {
    await _db.collection('salonlar').doc(salonId).update({'galeri': FieldValue.arrayRemove([url])});
    await _storage.refFromURL(url).delete();
  }
}
