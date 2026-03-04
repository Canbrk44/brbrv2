import 'dart:convert';
import 'dart:io';

// Veritabanı (Bellekte tutulur, sunucu durunca sıfırlanır - Gerçek DB öncesi son aşama)
List<Map<String, dynamic>> salonlar = []; 
bool bakimModu = false;

void main() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 3000);
  print('Berber Yönetim API: http://localhost:3000');

  await for (HttpRequest request in server) {
    // CORS Ayarları
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, DELETE, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      continue;
    }

    final path = request.uri.path;

    // --- ENDPOINTS ---

    // 1. Bakım Modu Kontrolü
    if (path == '/api/status') {
      request.response.write(jsonEncode({'bakimModu': bakimModu}));
    } 
    
    // 2. Bakım Modunu Değiştir (Admin)
    else if (path == '/api/admin/maintenance' && request.method == 'POST') {
      bakimModu = !bakimModu;
      request.response.write(jsonEncode({'status': 'success', 'bakimModu': bakimModu}));
    }

    // 3. Salonları Listele ve Ekle
    else if (path == '/api/salonlar') {
      if (request.method == 'GET') {
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(salonlar));
      } else if (request.method == 'POST') {
        final content = await utf8.decoder.bind(request).join();
        final data = jsonDecode(content);
        data['id'] = DateTime.now().millisecondsSinceEpoch;
        salonlar.add(data);
        request.response.statusCode = HttpStatus.created;
        request.response.write(jsonEncode(data));
      }
    }

    // 4. Salon Sil
    else if (path.startsWith('/api/salonlar/') && request.method == 'DELETE') {
      final id = int.tryParse(path.split('/').last);
      salonlar.removeWhere((s) => s['id'] == id);
      request.response.write(jsonEncode({'status': 'deleted'}));
    }

    else {
      request.response.statusCode = HttpStatus.notFound;
    }

    await request.response.close();
  }
}
