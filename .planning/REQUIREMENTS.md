# Requirements: Word Crush Mobil Oyunu

**Defined:** 2026-04-07
**Core Value:** Oyuncuya her zaman oynanabilir kalan, kurallari acikca gorunen ve ders dokumanindaki tum zorunlu maddeleri eksiksiz yerine getiren bir mobil kelime oyunu sunmak.

## v1 Requirements

### Platform ve Kapsam

- [ ] **PLAT-01**: Uygulama Android veya iOS odakli mobil calisir ve sunum emulator ya da fiziksel telefon uzerinden yapilabilir; web/masaustu akisi zorunlu tutulmaz.
- [ ] **PLAT-02**: Kelime dogrulamasi icin uygulama icine paketlenmis Turkce bir sozluk/kelime listesi kullanilir.
- [ ] **PLAT-03**: Oyun alani kare grid yapisinda olur ve her hucre bir harf tasir.

### Kullanici ve Ana Ekran

- [ ] **USER-01**: Ilk acilista kullanici adi alinir ve sonraki acilislarda ayni cihazda saklanir.
- [ ] **USER-02**: Kullanici adi ana ekranin sol ust alanindan degistirilebilir.
- [ ] **HOME-01**: Kullanici adi tamamlandiktan sonra kullanici ana ekrana yonlendirilir.
- [ ] **HOME-02**: Ana ekranda `Yeni Oyun`, `Skor Tablosu` ve `Market` secenekleri bulunur.

### Yeni Oyun ve Kurulum

- [ ] **SETUP-01**: `Yeni Oyun` secimi oyun ayarlari akisini acar.
- [ ] **SETUP-02**: Grid secenekleri tam olarak `6x6 = Zor`, `8x8 = Orta`, `10x10 = Kolay` seklinde sunulur.
- [ ] **SETUP-03**: Hamle secenekleri zorluga uygun olarak `15/20/25` seklinde sunulur ve secim tamamlaninca oyun baslar.

### Grid ve Kelime Kurallari

- [ ] **GRID-01**: Harfler Turkce frekans mantigina gore agirlikli uretilir; duz uniform rastgelelik kullanilmaz.
- [ ] **GRID-02**: Baslangic board'u ve hamle sonrasi/refill board'lari her zaman en az bir gecerli kelime barindiracak sekilde analiz edilir; gerekirse otomatik cozum uygulanir.
- [ ] **GRID-03**: Oyuncu herhangi bir hucreden baslayip 8 yonlu komsu hucreler uzerinden ayni hucreyi tekrar kullanmadan secim yapabilir.
- [ ] **GRID-04**: 3 harften kisa secimler gecersiz sayilir.
- [ ] **GRID-05**: Parmak kaldirildiginda secim tamamlanir ve olusan kelime sozlukte kontrol edilir.
- [ ] **GRID-06**: Gecerli ve gecersiz denemelerin ikisi de 1 hamle harcar; gecersiz deneme secimi eski haline doner.
- [ ] **GRID-07**: Gecerli kelimede secilen harfler kaldirilir, ustteki harfler asagi duser ve bosluklar ustten yeni harflerle dolar.
- [ ] **GRID-08**: O an olusturulabilir kelime sayisi, ortak harf kullanmayan cozum mantigiyla hesaplanip oyun ekraninda gosterilir.

### Puanlama, Ozel Gucler ve Combo

- [ ] **SCORE-01**: Harf puanlari PDF tablosuna uygun tanimlanir ve gecerli kelime puani anlik toplama eklenir.
- [ ] **POWER-01**: 4 harfli kelime son harfte satir temizleme gucu olusturur.
- [ ] **POWER-02**: 5 harfli kelime son harfte alan patlatma gucu olusturur.
- [ ] **POWER-03**: 6 harfli kelime son harfte sutun temizleme gucu olusturur.
- [ ] **POWER-04**: 7 ve uzeri harfli kelime son harfte mega patlatma gucu olusturur.
- [ ] **POWER-05**: Guc tasiyan hucre yeniden kullanildiginda ilgili etki tetiklenir.
- [ ] **COMBO-01**: Ana kelime icindeki en az 3 harfli, benzersiz ve sirayi koruyan alt kelimeler combo'ya dahil edilir; alt kelime puanlari da toplama eklenir.

### Market, Altin ve Jokerler

- [ ] **ECON-01**: Oyuncu test/oyun rahatligi icin yuksek veya fiilen sinirsiz altinla baslar; gercek para ile satin alma akisi bulunmaz.
- [ ] **MKT-01**: Market ekrani mevcut altini, joker aciklamalarini, kullanim amacini, maliyetini ve kullanim seklini gosterir.
- [ ] **MKT-02**: Markette tam olarak `Balik`, `Tekerlek`, `Lolipop Kirici`, `Serbest Degistirme`, `Harf Karistirma`, `Parti Guclendiricisi` jokerleri bulunur.
- [ ] **MKT-03**: Yeterli altina sahip kullanici joker satin alabilir; satin alinan jokerler oyun ekraninda secilebilir olur.
- [ ] **MKT-04**: Jokerler dokumandaki board etkilerini uygular.

### Skor Gecmisi ve Oyun Bitisi

- [ ] **HIST-01**: Skor tablosu ust bolumde toplam oyun, en yuksek puan, ortalama puan, toplam kelime, en uzun kelime ve toplam sure ozetini gosterir.
- [ ] **HIST-02**: Skor gecmisi en son oynanan ustte olacak sekilde listelenir ve her kart oyun no, tarih, grid, puan, kelime sayisi, en uzun kelime ve sureyi gosterir.
- [ ] **END-01**: Hamle sayisi bittiginde oyun sonucu kaydedilir ve ana ekrana donulur.
- [ ] **END-02**: Geri ile cikis denendiginde `Evet/Hayir` onayi gelir; `Hayir` oyuna devam eder, `Evet` sonucu kaydedip ana ekrana doner.

### Teslim ve Sunum Hazirligi

- [ ] **SHIP-01**: Repoda IEEE uyumlu LaTeX rapor iskeleti ve PDF uretmeye uygun kaynak dosyalar bulunur.
- [ ] **SHIP-02**: Repoda mobil cihaz/emulator sunumu, canli kod anlatimi ve teslim adimlari icin net bir kontrol listesi bulunur.

## v2 Requirements

### Deferred

- Gercek online leaderboard
- Bulut yedekleme / hesap baglama
- Coklu kullanici destegi
- Tema sistemi veya kisilestirilmis skin yapilari

## Out of Scope

| Feature | Reason |
|---------|--------|
| Real-money IAP | Dokumanda istenmiyor; test altini daha dogru cozum |
| Online multiplayer | Tek oyunculu ders projesi kapsami icin gereksiz |
| Web release | Sunum mobilde yapilacak |
| Remote backend sync | Yerel veri modeli bu proje icin yeterli |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PLAT-02 | Phase 1 | Pending |
| USER-01 | Phase 1 | Pending |
| USER-02 | Phase 1 | Pending |
| HOME-01 | Phase 1 | Pending |
| HOME-02 | Phase 1 | Pending |
| PLAT-03 | Phase 2 | Pending |
| SETUP-01 | Phase 2 | Pending |
| SETUP-02 | Phase 2 | Pending |
| SETUP-03 | Phase 2 | Pending |
| GRID-01 | Phase 2 | Pending |
| GRID-03 | Phase 2 | Pending |
| GRID-04 | Phase 3 | Pending |
| GRID-05 | Phase 3 | Pending |
| GRID-06 | Phase 3 | Pending |
| GRID-07 | Phase 3 | Pending |
| SCORE-01 | Phase 3 | Pending |
| END-01 | Phase 3 | Pending |
| END-02 | Phase 3 | Pending |
| GRID-02 | Phase 4 | Pending |
| GRID-08 | Phase 4 | Pending |
| POWER-01 | Phase 4 | Pending |
| POWER-02 | Phase 4 | Pending |
| POWER-03 | Phase 4 | Pending |
| POWER-04 | Phase 4 | Pending |
| POWER-05 | Phase 4 | Pending |
| COMBO-01 | Phase 4 | Pending |
| ECON-01 | Phase 5 | Pending |
| MKT-01 | Phase 5 | Pending |
| MKT-02 | Phase 5 | Pending |
| MKT-03 | Phase 5 | Pending |
| MKT-04 | Phase 5 | Pending |
| HIST-01 | Phase 5 | Pending |
| HIST-02 | Phase 5 | Pending |
| PLAT-01 | Phase 6 | Pending |
| SHIP-01 | Phase 6 | Pending |
| SHIP-02 | Phase 6 | Pending |

**Coverage:**
- v1 requirements: 36 total
- Mapped to phases: 36
- Unmapped: 0

---
*Requirements defined: 2026-04-07*
*Last updated: 2026-04-07 after initial roadmap creation*
