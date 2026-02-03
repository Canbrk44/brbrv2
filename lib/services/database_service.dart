import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'berber_database.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE musteriler (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        adSoyad TEXT,
        telefon TEXT UNIQUE,
        kayitTarihi TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE randevular (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        musteriTelefon TEXT,
        berberIsmi TEXT,
        ustaIsmi TEXT,
        tarih TEXT,
        saat TEXT,
        durum TEXT DEFAULT 'aktif',
        oylandi INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE yorumlar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ustaIsmi TEXT,
        salonIsmi TEXT,
        musteriAd TEXT,
        puan REAL,
        yorumMetni TEXT,
        tarih TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE yorumlar (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          ustaIsmi TEXT,
          salonIsmi TEXT,
          musteriAd TEXT,
          puan REAL,
          yorumMetni TEXT,
          tarih TEXT
        )
      ''');
    }
  }

  Future<void> yorumKaydet({
    required String ustaIsmi,
    required String salonIsmi,
    required String musteriAd,
    required double puan,
    required String yorumMetni,
  }) async {
    final db = await database;
    await db.insert('yorumlar', {
      'ustaIsmi': ustaIsmi,
      'salonIsmi': salonIsmi,
      'musteriAd': musteriAd,
      'puan': puan,
      'yorumMetni': yorumMetni,
      'tarih': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> ustaYorumlariniGetir(String ustaIsmi) async {
    final db = await database;
    return await db.query(
      'yorumlar',
      where: 'ustaIsmi = ?',
      whereArgs: [ustaIsmi],
      orderBy: 'id DESC',
    );
  }

  // Salonun tüm yorumlarını getir
  Future<List<Map<String, dynamic>>> salonYorumlariniGetir(String salonIsmi) async {
    final db = await database;
    return await db.query(
      'yorumlar',
      where: 'salonIsmi = ?',
      whereArgs: [salonIsmi],
      orderBy: 'id DESC',
    );
  }

  Future<Map<String, dynamic>?> musteriGetir(String telefon) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'musteriler',
      where: 'telefon = ?',
      whereArgs: [telefon],
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  Future<void> musteriKaydet(String adSoyad, String telefon) async {
    final db = await database;
    try {
      await db.insert(
        'musteriler',
        {
          'adSoyad': adSoyad,
          'telefon': telefon,
          'kayitTarihi': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
    } catch (e) {
      print("SQLite Müşteri Kayıt Hatası: $e");
    }
  }

  Future<bool> aktifRandevusuVarMi(String telefon) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'randevular',
      where: 'musteriTelefon = ? AND durum = ?',
      whereArgs: [telefon, 'aktif'],
    );
    return maps.isNotEmpty;
  }

  Future<void> randevuOlustur({
    required String musteriTelefon,
    required String berberIsmi,
    required String ustaIsmi,
    required String tarih,
    required String saat,
  }) async {
    final db = await database;
    try {
      await db.insert('randevular', {
        'musteriTelefon': musteriTelefon,
        'berberIsmi': berberIsmi,
        'ustaIsmi': ustaIsmi,
        'tarih': tarih,
        'saat': saat,
        'durum': 'aktif',
        'oylandi': 0
      });
    } catch (e) {
      print("SQLite Randevu Oluşturma Hatası: $e");
    }
  }

  Future<List<Map<String, dynamic>>> musterininRandevulariniGetir(String telefon) async {
    final db = await database;
    return await db.query(
      'randevular',
      where: 'musteriTelefon = ?',
      whereArgs: [telefon],
      orderBy: 'id DESC',
    );
  }

  Future<Map<String, dynamic>?> yaklasanBugunkuRandevuyuGetir(String telefon) async {
    final db = await database;
    final simdi = DateTime.now();
    final bugun = "${simdi.day}/${simdi.month}/${simdi.year}";

    final List<Map<String, dynamic>> maps = await db.query(
      'randevular',
      where: 'musteriTelefon = ? AND tarih = ? AND durum = ?',
      whereArgs: [telefon, bugun, 'aktif'],
      limit: 1,
    );

    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  Future<Map<String, dynamic>?> oylanmamisGecmisRandevuGetir(String telefon) async {
    final db = await database;
    final List<Map<String, dynamic>> sonuclar = await db.query(
      'randevular',
      where: 'musteriTelefon = ? AND durum = ? AND oylandi = 0',
      whereArgs: [telefon, 'aktif'],
      orderBy: 'id DESC',
      limit: 1,
    );

    if (sonuclar.isEmpty) return null;

    final r = sonuclar.first;
    try {
      List<String> tParts = r['tarih'].split('/');
      List<String> sParts = r['saat'].split(':');
      DateTime randevuZamani = DateTime(
        int.parse(tParts[2]), 
        int.parse(tParts[1]), 
        int.parse(tParts[0]),
        int.parse(sParts[0]),
        int.parse(sParts[1]),
      );

      if (DateTime.now().isAfter(randevuZamani.add(const Duration(hours: 1)))) {
        return r;
      }
    } catch (e) {
      print("Tarih parse hatası: $e");
    }
    
    return null;
  }

  Future<void> randevuyuTamamlaVeOyla(int id) async {
    final db = await database;
    await db.update(
      'randevular',
      {'durum': 'Tamamlandı', 'oylandi': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
