import 'package:flutter/material.dart';

class RandevularEkrani extends StatelessWidget {
  const RandevularEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Randevularım"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              "Henüz bir randevunuz bulunmuyor.",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                onPressed: () {
                  // Ana sayfaya veya keşfet kısmına yönlendirilebilir
                },
                child: const Text("Hemen Randevu Bul"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
