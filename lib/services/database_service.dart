import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- PHP SERVER AYARLARI ---
  final String apiBaseUrl = "http://89.252.152.89/api.php"; 

  // --- YAZMA İŞLEMLERİ ---

  Future<bool> salonEkleServer(Map<String, dynamic> salonData) async {
    try {
      final Map<String, dynamic> guncelSalonData = {
        ...salonData,
        'puan': 2.0,
        'ustalar': [],
        'hizmetler': [],
        'galeri': [],
      };
      
      final response = await http.post(
        Uri.parse('$apiBaseUrl?islem=salon_ekle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(guncelSalonData),
      );
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<bool> ustaEkle(String salonId, Map<String, dynamic> ustaData) async {
    try {
      final Map<String, dynamic> guncelUstaData = {
        ...ustaData,
        'puan': 2.0,
      };
      
      await _db.collection('salonlar').doc(salonId).set({
        'ustalar': FieldValue.arrayUnion([guncelUstaData])
      }, SetOptions(merge: true));
      return true;
    } catch (e) { return false; }
  }

  Future<bool> hizmetEkle(String salonId, Map<String, dynamic> hizmetData) async {
    try {
      await _db.collection('salonlar').doc(salonId).set({
        'hizmetler': FieldValue.arrayUnion([hizmetData])
      }, SetOptions(merge: true));
      return true;
    } catch (e) { return false; }
  }

  Future<bool> salonSilServer(String salonId) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl?islem=salon_sil'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'salonId': salonId}),
      );
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  // --- OKUMA VE DİĞER İŞLEMLER ---

  Future<Map<String, dynamic>?> kullaniciGetir(String t) async {
    var s = await _db.collection('users').where('telefon', isEqualTo: t.trim()).limit(1).get();
    return s.docs.isNotEmpty ? s.docs.first.data() : null;
  }

  Stream<List<Map<String, dynamic>>> salonlariGetir(String sehir) {
    return _db.collection('salonlar').snapshots().map((sn) {
      return sn.docs.map((d) {
        var data = d.data();
        return {
          ...data,
          'id': d.id,
          'ustalar': data['ustalar'] ?? [],
          'hizmetler': data['hizmetler'] ?? [],
          'galeri': data['galeri'] ?? [],
          'puan': (data['puan'] ?? 2.0).toDouble(),
        };
      }).where((s) {
        if (sehir.isEmpty || sehir.contains("aranıyor")) return true;
        String salonSehir = (s['sehir'] ?? "").toString().toLowerCase();
        String arananSehir = sehir.split(',')[0].toLowerCase().trim();
        return salonSehir.contains(arananSehir) || arananSehir.contains(salonSehir);
      }).toList();
    });
  }

  // --- GÜNCELLENEN RANDEVU OLUŞTURMA ---
  Future<void> randevuOlustur({
    required String musteriTelefon, 
    required String musteriAd,
    required String salonId,
    required String berberIsmi, 
    required String ustaIsmi, 
    required String tarih, 
    required String saat, 
    required String kisiTuru,
    required double fiyat,
    required String hizmetAdi,
  }) async {
    await _db.collection('randevular').add({
      'salonId': salonId,
      'berberIsmi': berberIsmi,
      'musteriTelefon': musteriTelefon.trim(), 
      'musteriAd': musteriAd, 
      'ustaIsmi': ustaIsmi, 
      'tarih': tarih, 
      'saat': saat, 
      'kisiTuru': kisiTuru, 
      'fiyat': fiyat,
      'hizmet': hizmetAdi,
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

  Future<List<String>> doluSaatleriGetir(String berberIsmi, String ustaIsmi, String tarih) async {
    var snap = await _db.collection('randevular').where('berberIsmi', isEqualTo: berberIsmi).where('ustaIsmi', isEqualTo: ustaIsmi).where('tarih', isEqualTo: tarih).where('durum', isEqualTo: 'aktif').get();
    return snap.docs.map((d) => d['saat'].toString()).toList();
  }

  Future<Map<String, int>> dolulukOranlariniGetir(String berberIsmi, String ustaIsmi) async {
    var snap = await _db.collection('randevular').where('berberIsmi', isEqualTo: berberIsmi).where('ustaIsmi', isEqualTo: ustaIsmi).where('durum', isEqualTo: 'aktif').get();
    Map<String, int> counts = {};
    for (var doc in snap.docs) {
      String t = doc['tarih'];
      counts[t] = (counts[t] ?? 0) + 1;
    }
    return counts;
  }

  Future<int> aktifRandevuSayisi(String t) async {
    var s = await _db.collection('randevular').where('musteriTelefon', isEqualTo: t.trim()).where('durum', isEqualTo: 'aktif').get();
    return s.docs.length;
  }

  Future<void> randevuSil(String id) async {
    await _db.collection('randevular').doc(id).delete();
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

  Future<void> yorumKaydet({required String randevuId, required String ustaIsmi, required String salonIsmi, required String musteriAd, required double salonPuan, required String salonYorum, required double ustaPuan, required String ustaYorum}) async {
    try {
      await _db.collection('yorumlar').add({'randevuId': randevuId, 'ustaIsmi': ustaIsmi, 'salonIsmi': salonIsmi, 'musteriAd': musteriAd, 'salonPuan': salonPuan, 'salonYorum': salonYorum, 'ustaPuan': ustaPuan, 'ustaYorum': ustaYorum, 'tarih': FieldValue.serverTimestamp()});
      await _db.collection('randevular').doc(randevuId).update({'oylandi': 1, 'durum': 'tamamlandi'});
      await _puanlariHesaplaVeGuncelle(salonIsmi, ustaIsmi);
    } catch (e) {}
  }

  Future<void> _puanlariHesaplaVeGuncelle(String salonIsmi, String ustaIsmi) async {
    var yorumlarSnap = await _db.collection('yorumlar').where('salonIsmi', isEqualTo: salonIsmi).get();
    var tumYorumlar = yorumlarSnap.docs;
    
    double salonGenelPuan = 2.0;
    if (tumYorumlar.isNotEmpty) {
      double toplam = 0;
      for (var doc in tumYorumlar) toplam += (doc.data()['salonPuan'] as num? ?? 0).toDouble();
      salonGenelPuan = double.parse((toplam / tumYorumlar.length).toStringAsFixed(1));
    }

    var ustaYorumlari = tumYorumlar.where((d) => d.data()['ustaIsmi'] == ustaIsmi).toList();
    double ustaYeniPuan = 2.0;
    if (ustaYorumlari.isNotEmpty) {
      double ustaToplam = 0;
      for (var doc in ustaYorumlari) ustaToplam += (doc.data()['ustaPuan'] as num? ?? 0).toDouble();
      ustaYeniPuan = double.parse((ustaToplam / ustaYorumlari.length).toStringAsFixed(1));
    }

    var salonSnap = await _db.collection('salonlar').where('isim', isEqualTo: salonIsmi).limit(1).get();
    if (salonSnap.docs.isNotEmpty) {
      var doc = salonSnap.docs.first;
      List ustalar = List.from(doc.data()['ustalar'] ?? []);
      for (var i = 0; i < ustalar.length; i++) {
        if (ustalar[i]['isim'] == ustaIsmi) {
          ustalar[i]['puan'] = ustaYeniPuan;
        }
      }
      await doc.reference.update({
        'puan': salonGenelPuan,
        'ustalar': ustalar
      });
    }
  }

  Future<String?> profilResmiYukle(File file, String telefon) async {
    try {
      String fileName = "profile_${telefon}.jpg";
      Reference ref = _storage.ref().child('users/$telefon/$fileName');
      await ref.putFile(file);
      String url = await ref.getDownloadURL();
      var snap = await _db.collection('users').where('telefon', isEqualTo: telefon.trim()).get();
      if (snap.docs.isNotEmpty) await snap.docs.first.reference.update({'profilResmi': url});
      return url;
    } catch (e) { return null; }
  }

  Future<Map<String, dynamic>?> salonGetirByEmail(String e) async {
    var s = await _db.collection('salonlar').where('sahipEmail', isEqualTo: e).limit(1).get();
    if (s.docs.isEmpty) return null;
    var d = s.docs.first.data(); d['id'] = s.docs.first.id;
    d['ustalar'] = d['ustalar'] ?? [];
    d['hizmetler'] = d['hizmetler'] ?? [];
    d['galeri'] = d['galeri'] ?? [];
    d['puan'] = (d['puan'] ?? 2.0).toDouble();
    return d;
  }

  Future<String?> fotografYukle(File file, String salonId) async {
    try {
      String fn = "galeri_${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference ref = _storage.ref().child('salonlar/$salonId/galeri/$fn');
      await ref.putFile(file);
      String url = await ref.getDownloadURL();
      await _db.collection('salonlar').doc(salonId).update({'galeri': FieldValue.arrayUnion([url])});
      return url;
    } catch (e) { return null; }
  }

  Future<void> fotografSil(String salonId, String url) async {
    await _db.collection('salonlar').doc(salonId).update({'galeri': FieldValue.arrayRemove([url])});
    await _storage.refFromURL(url).delete();
  }

  Future<void> kullaniciKaydet({required String adSoyad, required String telefon, String? profilResmi, String? dogumTarihi, String? cinsiyet, String? sehir, String? email, bool yeniKayit = false}) async {
    final String cleanPhone = telefon.trim();
    final String newDocId = "$adSoyad ($cleanPhone)";
    var existingDocs = await _db.collection('users').where('telefon', isEqualTo: cleanPhone).get();
    for (var doc in existingDocs.docs) { if (doc.id != newDocId) await doc.reference.delete(); }
    Map<String, dynamic> data = {'adSoyad': adSoyad, 'telefon': cleanPhone, 'sonGuncelleme': FieldValue.serverTimestamp()};
    if (yeniKayit) { data['profilResmi'] = ""; data['dogumTarihi'] = ""; data['cinsiyet'] = ""; data['sehir'] = ""; data['email'] = ""; data['rol'] = 'musteri'; data['kayitTarihi'] = FieldValue.serverTimestamp(); }
    else { if (profilResmi != null) data['profilResmi'] = profilResmi; if (dogumTarihi != null) data['dogumTarihi'] = dogumTarihi; if (cinsiyet != null) data['cinsiyet'] = cinsiyet; if (sehir != null) data['sehir'] = sehir; if (email != null) data['email'] = email; }
    await _db.collection('users').doc(newDocId).set(data, SetOptions(merge: true));
  }
  
  Stream<List<Map<String, dynamic>>> salonRandevulariniGetir(String s) {
    return _db.collection('randevular').where('berberIsmi', isEqualTo: s).snapshots().map((sn) => sn.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }
}
