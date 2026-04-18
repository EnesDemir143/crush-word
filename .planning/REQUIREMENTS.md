# Requirements: Word Crush Mobil Oyunu

**Defined:** 2026-04-07
**Core Value:** Oyuncuya her zaman oynanabilir kalan, kurallari acikca gorunen ve ders dokumanindaki tum zorunlu maddeleri eksiksiz yerine getiren bir mobil kelime oyunu sunmak.

## v1 Requirements

### Platform ve Kapsam

- [ ] **PLAT-01**: Uygulama Android veya iOS odakli mobil calisir ve sunum emulator ya da fiziksel telefon uzerinden yapilabilir; web/masaustu akisi zorunlu tutulmaz.
- [x] **PLAT-02**: Kelime dogrulamasi icin uygulama icine paketlenmis Turkce bir sozluk/kelime listesi kullanilir.
- [x] **PLAT-03**: Oyun alani kare grid yapisinda olur ve her hucre bir harf tasir.

### Kullanici ve Ana Ekran

- [x] **USER-01**: Ilk acilista kullanici adi alinir ve sonraki acilislarda ayni cihazda saklanir.
- [x] **USER-02**: Kullanici adi ana ekranin sol ust alanindan degistirilebilir.
- [x] **HOME-01**: Kullanici adi tamamlandiktan sonra kullanici ana ekrana yonlendirilir.
- [x] **HOME-02**: Ana ekranda `Yeni Oyun`, `Skor Tablosu` ve `Market` secenekleri bulunur.

### Yeni Oyun ve Kurulum

- [x] **SETUP-01**: `Yeni Oyun` secimi oyun ayarlari akisini acar.
- [x] **SETUP-02**: Grid secenekleri tam olarak `6x6 = Zor`, `8x8 = Orta`, `10x10 = Kolay` seklinde sunulur.
- [x] **SETUP-03**: Hamle secenekleri zorluga uygun olarak `15/20/25` seklinde sunulur ve secim tamamlaninca oyun baslar.

### Grid ve Kelime Kurallari

- [x] **GRID-01**: Harfler Turkce frekans mantigina gore agirlikli uretilir; duz uniform rastgelelik kullanilmaz.
- [ ] **GRID-02**: Baslangic board'u ve hamle sonrasi/refill board'lari her zaman en az bir gecerli kelime barindiracak sekilde analiz edilir; gerekirse otomatik cozum uygulanir.
- [x] **GRID-03**: Oyuncu herhangi bir hucreden baslayip 8 yonlu komsu hucreler uzerinden ayni hucreyi tekrar kullanmadan secim yapabilir.
- [x] **GRID-04**: 3 harften kisa secimler gecersiz sayilir.
- [x] **GRID-05**: Parmak kaldirildiginda secim tamamlanir ve olusan kelime sozlukte kontrol edilir.
- [x] **GRID-06**: Gecerli ve gecersiz denemelerin ikisi de 1 hamle harcar; gecersiz deneme secimi eski haline doner.
- [x] **GRID-07**: Gecerli kelimede secilen harfler kaldirilir, ustteki harfler asagi duser ve bosluklar ustten yeni harflerle dolar.
- [ ] **GRID-08**: O an olusturulabilir kelime sayisi, ortak harf kullanmayan cozum mantigiyla hesaplanip oyun ekraninda gosterilir.

### Puanlama, Ozel Gucler ve Combo

- [x] **SCORE-01**: Harf puanlari PDF tablosuna uygun tanimlanir ve gecerli kelime puani anlik toplama eklenir.
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
- [ ] **MKT-03**: Yeterli altina sahip kullanici joker satin alabilir.
- [ ] **MKT-04**: Satin alinan jokerler oyun ekraninin alt kisiminda secilebilir ve kullanilabilir olarak gorunur.
- [ ] **MKT-05**: Jokerler dokumandaki board etkilerini uygular.

### Skor Gecmisi ve Oyun Bitisi

- [ ] **HIST-01**: Skor tablosu ust bolumde toplam oyun, en yuksek puan, ortalama puan, toplam kelime, en uzun kelime ve toplam sure ozetini gosterir.
- [ ] **HIST-02**: Skor gecmisi en son oynanan ustte olacak sekilde listelenir ve her kart oyun no, tarih, grid, puan, kelime sayisi, en uzun kelime ve sureyi gosterir.
- [x] **END-01**: Hamle sayisi bittiginde oyun sonucu kaydedilir ve ana ekrana donulur.
- [x] **END-02**: Geri ile cikis denendiginde `Evet/Hayir` onayi gelir; `Hayir` oyuna devam eder, `Evet` sonucu kaydedip ana ekrana doner.

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
| PLAT-02 | Phase 1 | Completed |
| USER-01 | Phase 1 | Completed |
| USER-02 | Phase 1 | Completed |
| HOME-01 | Phase 1 | Completed |
| HOME-02 | Phase 1 | Completed |
| PLAT-03 | Phase 2 | Completed |
| SETUP-01 | Phase 2 | Completed |
| SETUP-02 | Phase 2 | Completed |
| SETUP-03 | Phase 2 | Completed |
| GRID-01 | Phase 2 | Completed |
| GRID-03 | Phase 2 | Completed |
| GRID-04 | Phase 3 | Completed |
| GRID-05 | Phase 3 | Completed |
| GRID-06 | Phase 3 | Completed |
| GRID-07 | Phase 3 | Completed |
| SCORE-01 | Phase 3 | Completed |
| END-01 | Phase 3 | Completed |
| END-02 | Phase 3 | Completed |
| GRID-02 | Phase 02.1 + Phase 4 | Pending |
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
| MKT-05 | Phase 5 | Pending |
| HIST-01 | Phase 5 | Pending |
| HIST-02 | Phase 5 | Pending |
| PLAT-01 | Phase 6 | Pending |
| SHIP-01 | Phase 6 | Pending |
| SHIP-02 | Phase 6 | Pending |

## Planning Notes

- `GRID-02 ownership`: initial-session solvability guard owner'i Phase `02.1-01`'dir; Phase `04-01` ise post-move recheck, recovery continuity ve visible count integration owner'i olarak kalir.
- `COMBO-01 note`: compliant implementasyon benzersiz ve sirayi koruyan alt kelimeleri hedefler; substring-only yaklasim yeterli degildir.
- `MKT-05 ownership`: Phase 5, market fiyat/aciklama verisi ile gameplay effect'lerini tek canonical joker katalogu uzerinden senkron tutmalidir.
- `HIST-01/HIST-02 ownership`: oyuncuya gorunen aggregate + newest-first davranisi Phase 5 / `05-03` owner'ligindedir; Phase 3 repository sirasini sadece veri onkosulu olarak hazirlar.
- `Persistence gap`: app background/resume session restore su an source requirement ID tasimayan bir architecture gap'tir ve Phase `01.1-02` icinde explicit owner karari gerektirir.
- `Manual review note`: `SCORE-01` harf puan sabitleri ile joker fiyat sabitleri otomatik testler olsa bile insan tarafindan kaynak dokumana gore tekrar dogrulanir.

**Coverage:**
- v1 requirements: 37 total
- Mapped to phases: 37
- Unmapped: 0

---
*Requirements defined: 2026-04-07*
*Last updated: 2026-04-18 after Phase 03-03 closure sync*
