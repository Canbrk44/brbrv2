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
      version: 1,
      onCreate: _onCreate,
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
  }

  // Müşteri Kaydet
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
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print("SQLite Müşteri Kayıt Hatası: $e");
    }
  }

  // Aktif randevusu var mı kontrol et
  Future<bool> aktifRandevusuVarMi(String telefon) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'randevular',
      where: 'musteriTelefon = ? AND durum = ?',
      whereArgs: [telefon, 'aktif'],
    );
    return maps.isNotEmpty;
  }

  // Randevu Oluştur
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

  // Randevuları Getir
  Future<List<Map<String, dynamic>>> musterininRandevulariniGetir(String telefon) async {
    final db = await database;
    return await db.query(
      'randevular',
      where: 'musteriTelefon = ?',
      whereArgs: [telefon],
      orderBy: 'id DESC',
    );
  }

  // Oylanmamış ve süresi geçmiş randevuyu kontrol et
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
    // Tarih ve saat formatını ayrıştır (Örn: "25/5/2024" ve "14:00")
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

      // Randevu zamanından 1 saat geçmiş mi?
      if (DateTime.now().isAfter(randevuZamani.add(const Duration(hours: 1)))) {
        return r;
      }
    } catch (e) {
      print("Tarih parse hatası: $e");
    }
    
    return null;
  }

  // Randevuyu oylandı olarak işaretle ve tamamla
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
