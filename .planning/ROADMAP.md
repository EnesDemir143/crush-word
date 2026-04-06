# Roadmap: Word Crush Mobil Oyunu

## Overview

Bu roadmap, varsayilan Flutter starter uygulamasini ders dokumanindaki zorunlu kurallari eksiksiz karsilayan bir mobil kelime oyununa donusturmek icin tasarlandi. Fazlar, once dusuk riskli uygulama kabugu ve veri temelini kurup sonra oyun motorunu, ardindan ileri mekanikleri ve market/skor gecmisi katmanlarini ekleyecek sekilde sirlaniyor; son faz ise mobil sunum ve teslim hazirligini kapatiyor.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planli ana is paketleri
- Decimal phases (2.1, 2.2): Yalnizca acil araya giren isler icin ayrilacak

- [ ] **Phase 1: Foundation and Shell** - Starter uygulamayi urun kabuguna, kalici kullanici akisina ve ortak temel modellere donustur.
- [ ] **Phase 2: Game Setup and Board Foundation** - Yeni oyun ayarlari, agirlikli harf uretimi ve board UI temelini kur.
- [ ] **Phase 3: Core Gameplay and Session Results** - Kelime dogrulama, puanlama, refill ve oyun sonu kayit akislarini tamamla.
- [ ] **Phase 4: Advanced Board Mechanics** - Her zaman oynanabilir board, combo ve ozel guc davranislarini ekle.
- [ ] **Phase 5: Market and Score History** - Joker ekonomisi, market kullanimi ve skor tablosu ekranlarini tamamla.
- [ ] **Phase 6: Mobile Polish and Delivery** - Mobil sunum sertlestirmesi, testler ve LaTeX/teslim varliklarini kapat.

## Phase Details

### Phase 1: Foundation and Shell
**Goal**: Varsayilan counter uygulamasini kaldirip kullanici adi onboarding'i, ana ekran kabugu, ortak modeller ve yerel sozluk/persistence temelini kurmak.
**Depends on**: Nothing (first phase)
**Requirements**: [PLAT-02, USER-01, USER-02, HOME-01, HOME-02]
**Success Criteria** (what must be TRUE):
  1. Uygulama ilk acilista kullanici adini ister ve basarili kayit sonrasi ana ekrana gecer.
  2. Uygulama yeniden acildiginda kayitli kullanici adi yuklenir ve ana ekran acilir.
  3. Kullanici adi ana ekranin sol ustunden degistirilebilir.
  4. Ana ekranda `Yeni Oyun`, `Skor Tablosu` ve `Market` girisleri net bicimde gorunur.
  5. Paketlenmis Turkce sozluk ve ortak veri modelleri sonraki fazlar tarafindan kullanilabilecek durumda olur.
**Canonical refs**:
  - `docs/yazlab_2_2/Yazlab 2- Proje 2/auto/Yazlab 2- Proje 2.md`
  - `.agent/rules/01-platform-ve-temel-kisitlar.md`
  - `.agent/rules/02-giris-ve-ana-ekran.md`
**Plans**: 3 plans

Plans:
- [ ] 01-01: Replace starter app with feature-first app shell and navigation
- [ ] 01-02: Implement username persistence, editing flow and home screen
- [ ] 01-03: Add dictionary asset plumbing, shared models and baseline test harness

### Phase 2: Game Setup and Board Foundation
**Goal**: Yeni oyun ayarlari akisiyla beraber, agirlikli harf ureten ve kare harf gridini gosteren ilk oynanabilir board temelini kurmak.
**Depends on**: Phase 1
**Requirements**: [PLAT-03, SETUP-01, SETUP-02, SETUP-03, GRID-01, GRID-03]
**Success Criteria** (what must be TRUE):
  1. `Yeni Oyun` akisinda grid secenekleri tam dokumanla ayni deger ve zorluk eslesmesiyle sunulur.
  2. Hamle secenekleri secilen zorluga uygun degerlerle sunulur ve secim tamamlaninca oyun baslar.
  3. Oyun ekrani secilen boyutta kare harf gridini gosterir.
  4. Baslangic board'undaki harfler Turkce frekans mantigina gore uretilir.
  5. Oyuncu herhangi bir hucreden 8 yonlu komsulukla tekrar kullanmadan secim yolunu olusturabilir ve secilen yol ekranda vurgulanir.
**Canonical refs**:
  - `docs/yazlab_2_2/Yazlab 2- Proje 2/auto/Yazlab 2- Proje 2.md`
  - `.agent/rules/03-yeni-oyun-ve-zorluk.md`
  - `.agent/rules/04-oyun-akisi-ve-kelime-kurallari.md`
**Plans**: 3 plans

Plans:
- [ ] 02-01: Build new game settings flow and session bootstrap
- [ ] 02-02: Implement weighted board generator and playable initial seed
- [ ] 02-03: Render the board UI and drag-path capture behavior

### Phase 3: Core Gameplay and Session Results
**Goal**: Kelime gecerliligi, hamle dusumu, puanlama, gravity/refill ve oyun sonucu kaydetme akislarini eksiksiz hale getirmek.
**Depends on**: Phase 2
**Requirements**: [GRID-04, GRID-05, GRID-06, GRID-07, SCORE-01, END-01, END-02]
**Success Criteria** (what must be TRUE):
  1. Parmak kaldirildiginda secim tamamlanir ve kelime sozlukte dogrulanir.
  2. 3 harften kisa secimler veya gecersiz kelimeler board'u bozmadan geri alinir, ama yine de 1 hamle dusurur.
  3. Gecerli kelimelerde puan hesabi harf tablosuna gore yapilir, secilen harfler temizlenir, yercekimi uygulanir ve ustten yeni harfler dolar.
  4. Hamle sifirlandiginda ya da kullanici cikisi onayladiginda sonuc kaydedilir ve ana ekrana donulur.
**Canonical refs**:
  - `docs/Yazlab 2- Proje 2.pdf`
  - `.agent/rules/04-oyun-akisi-ve-kelime-kurallari.md`
  - `.agent/rules/05-puanlama-ozel-gucler-combo.md`
  - `.agent/rules/07-skor-gecmisi-ve-oyun-bitisi.md`
**Plans**: 3 plans

Plans:
- [ ] 03-01: Implement word finalization and dictionary validation flow
- [ ] 03-02: Add scoring table, move consumption, gravity and refill pipeline
- [ ] 03-03: Persist game results and exit/endgame flows

### Phase 4: Advanced Board Mechanics
**Goal**: Board'un her zaman oynanabilir kalmasini, combo puanlamasini ve uzun kelime ozel guclerini eklemek.
**Depends on**: Phase 3
**Requirements**: [GRID-02, GRID-08, POWER-01, POWER-02, POWER-03, POWER-04, POWER-05, COMBO-01]
**Success Criteria** (what must be TRUE):
  1. Baslangic ve hamle sonrasi board'larda en az bir gecerli kelime kalir; yoksa otomatik cozum uygulanir.
  2. Oyun ekrani guncel olusturulabilir kelime sayisini gosterir.
  3. Combo puani, ana kelime icindeki benzersiz alt kelimelerin puanlarini da toplama ekler.
  4. 4/5/6/7+ harfli kelimeler dogru guc tile'ini son harfte olusturur.
  5. Guc tasiyan hucre sonradan kullanildiginda dogru board etkisi tetiklenir.
**Canonical refs**:
  - `docs/Yazlab 2- Proje 2.pdf`
  - `.agent/rules/05-puanlama-ozel-gucler-combo.md`
  - `.agent/rules/06-grid-gecerlilik-ve-jokerler.md`
**Plans**: 3 plans

Plans:
- [ ] 04-01: Build playable-word analyzer and dead-board recovery
- [ ] 04-02: Implement combo detection and combo scoring
- [ ] 04-03: Add power-tile creation, storage and activation effects

### Phase 5: Market and Score History
**Goal**: Market ekonomisini, joker satin alma/kullanma akislarini ve skor tablosu ekranini tamamlamak.
**Depends on**: Phase 4
**Requirements**: [ECON-01, MKT-01, MKT-02, MKT-03, MKT-04, HIST-01, HIST-02]
**Success Criteria** (what must be TRUE):
  1. Oyuncu yuksek test altiniyla baslar ve market ekraninda guncel altinini gorebilir.
  2. Market, tum zorunlu jokerleri maliyet ve aciklamalariyla gosterir.
  3. Yeterli altinla satin alinan jokerler oyun ekraninda secilebilir olur ve dogru board etkisini uygular.
  4. Skor tablosu ustte gerekli ozet verilerini, altta da en yeni once olacak sekilde tum gecmis oyunlari gosterir.
**Canonical refs**:
  - `docs/Yazlab 2- Proje 2.pdf`
  - `.agent/rules/06-grid-gecerlilik-ve-jokerler.md`
  - `.agent/rules/07-skor-gecmisi-ve-oyun-bitisi.md`
**Plans**: 3 plans

Plans:
- [ ] 05-01: Build market catalog, gold balance and purchase persistence
- [ ] 05-02: Execute joker actions from in-game inventory
- [ ] 05-03: Implement score summary metrics and history list UI

### Phase 6: Mobile Polish and Delivery
**Goal**: Mobil sunum guvenilirligini, kritik test kapsamlarini ve LaTeX/teslim varliklarini tamamlamak.
**Depends on**: Phase 5
**Requirements**: [PLAT-01, SHIP-01, SHIP-02]
**Success Criteria** (what must be TRUE):
  1. Uygulama emulator veya fiziksel telefonda, web/masaustu bagimliligi olmadan gosterilebilir durumda olur.
  2. Kritik oyun mantigi ve temel ekran akislarini kapsayan analyze/test adimlari calisir.
  3. Repo icinde IEEE uyumlu LaTeX rapor iskeleti ve PDF uretimine uygun dosyalar bulunur.
  4. Sunum/teslim kontrol listesi; cihazda calistirma, anlatim ve canli degisiklik hazirligini kapsar.
**Canonical refs**:
  - `.agent/rules/01-platform-ve-temel-kisitlar.md`
  - `.agent/rules/08-teslim-ve-sunum-kurallari.md`
  - `docs/Yazlab 2- Proje 2.pdf`
**Plans**: 3 plans

Plans:
- [ ] 06-01: Polish mobile UX and verify required manual flows on device/emulator
- [ ] 06-02: Add focused automated tests and perform bugfix sweep
- [ ] 06-03: Create LaTeX report skeleton and presentation/delivery checklist

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5 -> 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation and Shell | 0/3 | Not started | - |
| 2. Game Setup and Board Foundation | 0/3 | Not started | - |
| 3. Core Gameplay and Session Results | 0/3 | Not started | - |
| 4. Advanced Board Mechanics | 0/3 | Not started | - |
| 5. Market and Score History | 0/3 | Not started | - |
| 6. Mobile Polish and Delivery | 0/3 | Not started | - |
