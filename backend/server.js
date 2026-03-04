const express = require('express');
const cors = require('cors');
const path = require('path');
const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());
app.use(express.static(__dirname));

let data = {
  salonlar: [],
  randevular: [],
  yorumlar: []
};

// Puan Hesaplama
const getPuan = (type, name) => {
    const y = data.yorumlar.filter(x => (type === 'usta' ? x.ustaIsmi : x.salonIsmi) === name);
    return y.length === 0 ? "0.0" : (y.reduce((a, b) => a + parseFloat(b.puan), 0) / y.length).toFixed(1);
};

// API'ler
app.get('/api/dashboard', (req, res) => {
    let ustaListesi = [];
    data.salonlar.forEach(s => {
        (s.ustalar || []).forEach(u => {
            ustaListesi.push({ isim: u.isim, salon: s.isim, puan: getPuan('usta', u.isim) });
        });
    });
    res.json({
        stats: { salonSayisi: data.salonlar.length, ustaSayisi: ustaListesi.length, randevuSayisi: data.randevular.length, yorumSayisi: data.yorumlar.length },
        enIyiUstalar: ustaListesi.sort((a,b) => b.puan - a.puan).slice(0, 5),
        enIyiSalonlar: data.salonlar.map(s => ({ isim: s.isim, puan: getPuan('salon', s.isim), sehir: s.sehir })).sort((a,b) => b.puan - a.puan).slice(0, 5)
    });
});

app.get('/api/salonlar', (req, res) => {
    res.json(data.salonlar.map(s => ({
        ...s,
        puan: getPuan('salon', s.isim),
        ustalar: (s.ustalar || []).map(u => ({ ...u, puan: getPuan('usta', u.isim) }))
    })));
});

app.post('/api/salonlar', (req, res) => {
    const yeni = { id: Date.now().toString(), ...req.body };
    data.salonlar.push(yeni);
    res.status(201).json(yeni);
});

app.put('/api/salonlar/:id', (req, res) => {
    const id = req.params.id.toString();
    const idx = data.salonlar.findIndex(s => s.id.toString() === id);
    if (idx !== -1) {
        data.salonlar[idx] = { ...data.salonlar[idx], ...req.body, id: id };
        res.json(data.salonlar[idx]);
    } else { res.status(404).send("Bulunamadı"); }
});

app.delete('/api/salonlar/:id', (req, res) => {
    const id = req.params.id.toString();
    const initialLen = data.salonlar.length;
    data.salonlar = data.salonlar.filter(s => s.id.toString() !== id);
    console.log("Silme denemesi ID:", id, "Başarılı mı:", data.salonlar.length < initialLen);
    res.json({ success: data.salonlar.length < initialLen });
});

app.get('/', (req, res) => res.sendFile(path.join(__dirname, 'admin_panel.html')));
app.post('/api/randevular', (req, res) => { data.randevular.push(req.body); res.json({ok:true}); });
app.post('/api/yorumlar', (req, res) => { data.yorumlar.push(req.body); res.json({ok:true}); });

app.listen(port, '0.0.0.0', () => console.log(`🚀 Sunucu: http://localhost:${port}`));
