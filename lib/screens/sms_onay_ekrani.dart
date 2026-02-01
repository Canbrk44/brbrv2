import 'package:flutter/material.dart';

class SmsOnayEkrani extends StatefulWidget {
  final String berberIsmi;
  final String ustaIsmi;
  final String tarih;
  final String saat;

  SmsOnayEkrani({
    required this.berberIsmi,
    required this.ustaIsmi,
    required this.tarih,
    required this.saat,
  });

  @override
  _SmsOnayEkraniState createState() => _SmsOnayEkraniState();
}

class _SmsOnayEkraniState extends State<SmsOnayEkrani> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("SMS Onayı"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message_outlined, size: 80, color: Colors.brown),
            SizedBox(height: 20),
            Text(
              "Onay Kodu Gönderildi",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "${widget.berberIsmi} - ${widget.ustaIsmi}\n${widget.tarih} saat ${widget.saat} randevusu için kodu girin.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 30),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold,
                letterSpacing: 10,
              ),
              decoration: InputDecoration(
                hintText: "0000",
                hintStyle: TextStyle(color: Colors.grey[300], letterSpacing: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                onPressed: () {
                  if (_codeController.text.length == 4) {
                    _basariliDialog(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Lütfen 4 haneli kodu girin.")),
                    );
                  }
                },
                child: Text("Onayla ve Randevuyu Tamamla", style: TextStyle(color: Colors.white)),
              ),
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
            Icon(Icons.check_circle, color: Colors.green, size: 80),
            SizedBox(height: 20),
            Text("Randevunuz Alındı!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text(
              "Randevu detaylarını 'Randevularım' sekmesinden görebilirsiniz.",
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text("Ana Sayfaya Dön"),
            )
          ],
        ),
      ),
    );
  }
}
