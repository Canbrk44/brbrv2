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

  // --- YAZMA İŞLEMLERİ (PHP SERVER ÜZERİNDEN) ---

  Future<bool> salonEkleServer(Map<String, dynamic> salonData) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl?islem=salon_ekle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(salonData),
      );
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<bool> ustaEkle(String salonId, Map<String, dynamic> ustaData) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl?islem=usta_ekle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'salonId': salonId, 'usta': ustaData}),
      );
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<bool> hizmetEkle(String salonId, Map<String, dynamic> hizmetData) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl?islem=hizmet_ekle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'salonId': salonId, 'hizmet': hizmetData}),
      );
      return response.statusCode == 200;
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

  // --- OKUMA VE DİĞER İŞLEMLER (DİREKT FIRESTORE) ---

  Future<Map<String, dynamic>?> kullaniciGetir(String t) async {
    var s = await _db.collection('users').where('telefon', isEqualTo: t.trim()).limit(1).get();
    return s.docs.isNotEmpty ? s.docs.first.data() : null;
  }

  Stream<List<Map<String, dynamic>>> salonlariGetir(String sehir) {
    return _db.collection('salonlar').snapshots().map((sn) => sn.docs.map((d) => {...d.data(), 'id': d.id}).where((s) => (s['sehir'] ?? "").toString().toLowerCase().contains(sehir.split(',')[0].toLowerCase().trim())).toList());
  }

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
    if (tumYorumlar.isEmpty) return;
    double sT = 0; for (var doc in tumYorumlar) sT += (doc.data()['salonPuan'] as num? ?? 0).toDouble();
    double sYP = double.parse((sT / tumYorumlar.length).toStringAsFixed(1));
    var uY = tumYorumlar.where((d) => d.data()['ustaIsmi'] == ustaIsmi).toList();
    double uYP = 0.0;
    if (uY.isNotEmpty) { double uT = 0; for (var doc in uY) uT += (doc.data()['ustaPuan'] as num? ?? 0).toDouble(); uYP = double.parse((uT / uY.length).toStringAsFixed(1)); }
    var sS = await _db.collection('salonlar').where('isim', isEqualTo: salonIsmi).limit(1).get();
    if (sS.docs.isNotEmpty) {
      var d = sS.docs.first; List u = List.from(d.data()['ustalar'] ?? []);
      for (var i = 0; i < u.length; i++) { if (u[i]['isim'] == ustaIsmi) u[i]['puan'] = uYP; }
      await d.reference.update({'puan': sYP, 'ustalar': u});
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
    var d = s.docs.first.data(); d['id'] = s.docs.first.id; return d;
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
