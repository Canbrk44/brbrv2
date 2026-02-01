import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import 'ana_sayfa.dart';

class SmsOnayEkrani extends StatefulWidget {
  final String berberIsmi;
  final String ustaIsmi;
  final String tarih;
  final String saat;
  final String? musteriTelefon;
  final String? userName;

  const SmsOnayEkrani({
    super.key,
    required this.berberIsmi,
    required this.ustaIsmi,
    required this.tarih,
    required this.saat,
    this.musteriTelefon,
    this.userName,
  });

  @override
  _SmsOnayEkraniState createState() => _SmsOnayEkraniState();
}

class _SmsOnayEkraniState extends State<SmsOnayEkrani> {
  final TextEditingController _codeController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SMS Onayı"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.message_outlined, size: 80, color: Color(0xFF0F172A)),
            const SizedBox(height: 20),
            const Text(
              "Onay Kodu Gönderildi",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "${widget.berberIsmi} - ${widget.ustaIsmi}\n${widget.tarih} saat ${widget.saat} randevusu için kodu girin.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 10),
              decoration: InputDecoration(
                hintText: "0000",
                hintStyle: TextStyle(color: Colors.grey[300], letterSpacing: 10),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                if (_codeController.text.length == 4) {
                  // SQLite'a kaydet
                  await _dbService.randevuOlustur(
                    musteriTelefon: widget.musteriTelefon ?? "Misafir",
                    berberIsmi: widget.berberIsmi,
                    ustaIsmi: widget.ustaIsmi,
                    tarih: widget.tarih,
                    saat: widget.saat,
                  );
                  _basariliDialog(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Lütfen 4 haneli kodu girin.")),
                  );
                }
              },
              child: const Text("Onayla ve Randevuyu Tamamla"),
            ),
          ],
        ),
      ),
    );
  }

  void _basariliDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text("Randevunuz Alındı!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
              "Randevu detaylarını 'Randevularım' sekmesinden görebilirsiniz.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Doğrudan Randevularım (Index: 1) sekmesine yönlendir
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnaSayfa(
                      initialIndex: 1, 
                      phoneNumber: widget.musteriTelefon,
                      userName: widget.userName,
                      isGuest: widget.musteriTelefon == null,
                    ),
                  ),
                  (route) => false,
                );
              },
              child: const Text("Randevularıma Git"),
            )
          ],
        ),
      ),
    );
  }
}
