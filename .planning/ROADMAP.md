# Roadmap: Word Crush Mobil Oyunu

## Overview

Bu roadmap, varsayilan Flutter starter uygulamasini ders dokumanindaki zorunlu kurallari eksiksiz karsilayan bir mobil kelime oyununa donusturmek icin tasarlandi. Fazlar, once dusuk riskli uygulama kabugu ve veri temelini kurup sonra oyun motorunu, ardindan ileri mekanikleri ve market/skor gecmisi katmanlarini ekleyecek sekilde sirlaniyor; son faz ise mobil sunum ve teslim hazirligini kapatiyor.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planli ana is paketleri
- Decimal phases (2.1, 2.2): Yalnizca acil araya giren isler icin ayrilacak

- [x] **Phase 1: Foundation and Shell** - Starter uygulamayi urun kabuguna, kalici kullanici akisina ve ortak temel modellere donustur.
- [x] **Phase 01.1: Requirements, Architecture and Persistence Eval Gate** - Phase 2'ye gecmeden once kaynak dokuman, kurallar, SQLite/persistence mimarisi ve riskli oyun davranislarinin ownership/validation planini dondur.
- [x] **Phase 2: Game Setup and Board Foundation** - Yeni oyun ayarlari, agirlikli harf uretimi ve board UI temelini kur.
- [x] **Phase 02.1: Initial Board Solvability Gate** - Phase 2 tamamlanir tamamlanmaz ilk gosterilen board'un dead gelmesini engelle ve ilk render oncesi recovery kapisini kapat.
- [x] **Phase 3: Core Gameplay and Session Results** - Kelime dogrulama, puanlama, refill ve oyun sonu kayit akislarini tamamla.
- [x] **Phase 4: Advanced Board Mechanics** - Her zaman oynanabilir board, combo ve ozel guc davranislarini ekle.
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
- [x] 01-01: Replace starter app with feature-first app shell and navigation
- [x] 01-02: Implement username persistence, editing flow and home screen
- [x] 01-03: Add dictionary asset plumbing, shared models and baseline test harness

### Phase 01.1: Requirements, Architecture and Persistence Eval Gate (INSERTED)
**Goal**: Phase 2 kodlamasina gecmeden once ana proje dokumani, `.agent` kurallari, mevcut roadmap ve mevcut kod tabani arasindaki uyumu degerlendirip persistence/SQLite secimini, tablo yapisini, klasor organizasyonunu ve riskli oyun kurallari icin dogrulama sahipligini netlestirmek.
**Depends on**: Phase 1
**Requirements**: Cross-phase eval gate for [GRID-01, GRID-02, GRID-06, GRID-08, COMBO-01, POWER-01, POWER-02, POWER-03, POWER-04, POWER-05, MKT-01, MKT-02, MKT-05, HIST-01, HIST-02, END-01]
**Success Criteria** (what must be TRUE):
  1. Ana markdown dokumani, `.agent` kurallari, `.planning` artefaktlari ve mevcut kod arasindaki eksik/yanlis ownership alanlari yazili olarak kaydedilir.
  2. `shared_preferences` ile `sqflite` sorumluluk siniri, secilecek SQLite paketi, hedef tablo yapisi ve migration yaklasimi netlestirilir.
  3. Oyun motoru ve persistence kodunun nereye tasinacagi, hangi klasorlerde tutulacagi ve hangi adapter/repository katmanlarina bolunecegi Phase 2 oncesi karara baglanir.
  4. Asagidaki yuksek riskli davranislar icin validation owner'i atanir: gecersiz secimde hamle dusumu, grid solvability/fallback, combo subsequence mantigi, power-tile tetikleme, non-overlapping kelime sayisi, joker fiyat/etki sync, score aggregate siralama ve app background/resume persistence.
  5. Harf puan tablosu ve fiyat sabitleri icin manuel kontrol gerektiren maddeler ayrica isaretlenir; otomatik ve manuel kontrol alanlari karistirilmaz.
**Canonical refs**:
  - `docs/yazlab2_2_opendataloader/Yazlab 2- Proje 2.md`
  - `.agent/rules/04-oyun-akisi-ve-kelime-kurallari.md`
  - `.agent/rules/05-puanlama-ozel-gucler-combo.md`
  - `.agent/rules/06-grid-gecerlilik-ve-jokerler.md`
  - `.agent/rules/07-skor-gecmisi-ve-oyun-bitisi.md`
  - `.planning/PROJECT.md`
  - `.planning/REQUIREMENTS.md`
  - `.planning/codebase/ARCHITECTURE.md`
**Plans**: 3 plans

Plans:
- [x] 01.1-01: Audit source spec, agent rules and roadmap for missing or misassigned gameplay rules
- [x] 01.1-02: Freeze persistence boundary, SQLite schema and target file structure
- [x] 01.1-03: Define eval matrix, manual review checklist and downstream phase updates
**Exit criteria note**: Phase 2 implementasyonu bu phase'te olusan `01.1-EVAL-MATRIX.md` ve `01.1-MANUAL-CHECKLIST.md` kontratina uyarak ilerleyecektir. `mixed` veya `manual` satirlarda downstream execution `MANUAL GATE` bildirimi olmadan item kapatamaz.

### Phase 2: Game Setup and Board Foundation
**Goal**: Yeni oyun ayarlari akisiyla beraber, agirlikli harf ureten ve kare harf gridini gosteren ilk oynanabilir board temelini kurmak.
**Depends on**: Phase 01.1
**Requirements**: [PLAT-03, SETUP-01, SETUP-02, SETUP-03, GRID-01, GRID-03]
**Success Criteria** (what must be TRUE):
  1. `Yeni Oyun` akisinda grid secenekleri tam dokumanla ayni deger ve zorluk eslesmesiyle sunulur.
  2. Hamle secenekleri secilen zorluga uygun degerlerle sunulur ve secim tamamlaninca oyun baslar.
  3. Oyun ekrani secilen boyutta kare harf gridini gosterir.
  4. Baslangic board'undaki harfler Turkce frekans mantigina gore uretilir.
  5. Oyuncu herhangi bir hucreden 8 yonlu komsulukla tekrar kullanmadan secim yolunu olusturabilir ve secilen yol ekranda vurgulanir.
  6. Phase 01.1'de dondurulen folder structure ve persistence sinirlari ihlal edilmeden ilerlenir.
**Ownership note**: `GRID-02` solvability/fallback davranisinin authoritative owner'i bu faz degil, Phase 4 / `04-01`'dir. Phase 2 yalnizca weighted generation ve session-level hook'lari hazirlar.
**Manual gate note**: Zorluk-grid-hamle mapping config'e ilk kez tasindiginda kullaniciyla manuel source check yapilir.
**Canonical refs**:
  - `docs/yazlab_2_2/Yazlab 2- Proje 2/auto/Yazlab 2- Proje 2.md`
  - `.agent/rules/03-yeni-oyun-ve-zorluk.md`
  - `.agent/rules/04-oyun-akisi-ve-kelime-kurallari.md`
**Plans**: 3 plans

Plans:
- [x] 02-01: Build new game settings flow and session bootstrap
- [x] 02-02: Implement weighted board generator and playable initial seed
- [x] 02-03: Render the board UI and drag-path capture behavior

### Phase 02.1: Initial Board Solvability Gate (INSERTED)
**Goal**: Phase 2 board'u gorunur olur olmaz, ilk oturumun dead board ile acilmasini engellemek ve kullaniciya ilk kez gosterilen gridde en az bir gecerli kelime oldugunu garanti etmek.
**Depends on**: Phase 2
**Requirements**: [GRID-02]
**Success Criteria** (what must be TRUE):
  1. Yeni oyun baslatildiginda ilk board kullaniciya gosterilmeden once analyzer ile en az bir gecerli kelime icerdigi kontrol edilir.
  2. Ilk generate edilen board dead ise oyuncuya hic gosterilmeden shuffle veya kontrollu yeniden uretimle recover edilir.
  3. Bu faz yalnizca first-render solvability guard'ini sahiplenir; visible playable-word count ve post-move recheck daha sonraki owner'da kalir.
**Ownership note**: Bu faz `GRID-02`'nin initial-session guard alt alanini one ceker. Phase 4 / `04-01` ise post-move recovery continuity ve `GRID-08` visible count owner'i olarak kalir.
**Manual gate note**: crafted bir dead start board'un ilk render oncesi recover edildigi kullaniciya acikca raporlanir.
**Canonical refs**:
  - `docs/Yazlab 2- Proje 2.pdf`
  - `.agent/rules/06-grid-gecerlilik-ve-jokerler.md`
  - `.planning/phases/04-advanced-board-mechanics/04-CONTEXT.md`
**Plans**: 1 plan

Plans:
- [x] 02.1-01: Add initial-session playable-board analyzer and recovery gate

### Phase 3: Core Gameplay and Session Results
**Goal**: Kelime gecerliligi, hamle dusumu, puanlama, gravity/refill ve oyun sonucu kaydetme akislarini eksiksiz hale getirmek.
**Depends on**: Phase 02.1
**Requirements**: [GRID-04, GRID-05, GRID-06, GRID-07, SCORE-01, END-01, END-02]
**Success Criteria** (what must be TRUE):
  1. Parmak kaldirildiginda secim tamamlanir ve kelime sozlukte dogrulanir.
  2. 3 harften kisa secimler veya gecersiz kelimeler board'u bozmadan geri alinir, ama yine de 1 hamle dusurur.
  3. Gecerli kelimelerde puan hesabi harf tablosuna gore yapilir, secilen harfler temizlenir, yercekimi uygulanir ve ustten yeni harfler dolar.
  4. Hamle sifirlandiginda ya da kullanici cikisi onayladiginda sonuc kaydedilir ve ana ekrana donulur.
**Manual gate note**: `03-02` sonunda harf puan tablosu canonical source ile kaynak dokuman arasinda manuel karsilastirilir. Resume persistence implement edildiginde app background/resume smoke-check yapilir.
**Canonical refs**:
  - `docs/Yazlab 2- Proje 2.pdf`
  - `.agent/rules/04-oyun-akisi-ve-kelime-kurallari.md`
  - `.agent/rules/05-puanlama-ozel-gucler-combo.md`
  - `.agent/rules/07-skor-gecmisi-ve-oyun-bitisi.md`
**Plans**: 3 plans

Plans:
- [x] 03-01: Implement word finalization and dictionary validation flow
- [x] 03-02: Add scoring table, move consumption, gravity and refill pipeline
- [x] 03-02.1: Implement UI polish, game animations, game-over screen and premium visuals
- [x] 03-03: Persist game results and exit/endgame flows

### Phase 4: Advanced Board Mechanics
**Goal**: Hamle sonrasi board continuity count'ini, combo puanlamasini ve uzun kelime ozel guclerini eklemek.
**Depends on**: Phase 3
**Requirements**: [GRID-02, GRID-08, POWER-01, POWER-02, POWER-03, POWER-04, POWER-05, COMBO-01]
**Success Criteria** (what must be TRUE):
  1. Hamle sonrasi/refill sonrasi board'larda en az bir gecerli kelime kalir; yoksa otomatik cozum uygulanir.
  2. Oyun ekrani ortak harf kullanmayan cozum mantigiyla hesaplanan guncel olusturulabilir kelime sayisini gosterir.
  3. Combo puani, ana kelime icindeki benzersiz ve sirayi koruyan alt kelimelerin puanlarini da toplama ekler.
  4. 4/5/6/7+ harfli kelimeler dogru guc tile'ini son harfte olusturur.
  5. Guc tasiyan hucre sonradan kullanildiginda dogru board etkisi tetiklenir.
**Ownership note**: `02.1-01` ilk render solvability guard'ini one ceker; `04-01` ayni analyzer/recovery hattini post-move continuity ve visible count owner'ligi icin genisletir.
**Manual gate note**: `04-01` ve `04-03` sonlarinda oyuncuya gorunen count/power davranisi kisa smoke-check ile teyit edilir; power threshold degerleri config'e ilk yazildiginda manuel source check yapilir.
**Canonical refs**:
  - `docs/Yazlab 2- Proje 2.pdf`
  - `.agent/rules/05-puanlama-ozel-gucler-combo.md`
  - `.agent/rules/06-grid-gecerlilik-ve-jokerler.md`
**Plans**: 3 plans

Plans:
- [x] 04-01: Extend playable-word analyzer to post-move recovery and visible count
- [x] 04-02: Implement combo detection and combo scoring
- [x] 04-03: Add power-tile creation, storage and activation effects

### Phase 5: Market and Score History
**Goal**: Market ekonomisini, joker satin alma/kullanma akislarini ve skor tablosu ekranini tamamlamak.
**Depends on**: Phase 4
**Requirements**: [ECON-01, MKT-01, MKT-02, MKT-03, MKT-04, MKT-05, HIST-01, HIST-02]
**Success Criteria** (what must be TRUE):
  1. Oyuncu yuksek test altiniyla baslar ve market ekraninda guncel altinini gorebilir.
  2. Market, tum zorunlu jokerleri tek canonical katalog kaynagindan gelen maliyet ve aciklamalariyla gosterir.
  3. Yeterli altinla satin alinan jokerler oyun ekraninin alt kisiminda secilebilir ve kullanilabilir olarak gorunur.
  4. Satin alinan jokerler ayni canonical katalog ile uyumlu dogru board etkisini uygular.
  5. Skor tablosu ustte gerekli ozet verilerini, altta da en yeni once olacak sekilde tum gecmis oyunlari gosterir.
**Ownership note**: Oyuncuya gorunen score aggregate/newest-first davranisinin authoritative owner'i Phase 5 / `05-03`'tur; `03-03` bu davranis icin yalnizca persistence onkosulu saglar.
**Manual note**: Joker fiyat sabitleri davranis testlerinden ayri olarak insan tarafindan kaynak tabloya gore dogrulanir.
**Manual gate note**: `05-01` sonunda joker fiyat/katalog sabitleri, `05-03` sonunda newest-first history ve aggregate alanlari kullanici tarafindan manuel teyit edilir.
**Canonical refs**:
  - `docs/Yazlab 2- Proje 2.pdf`
  - `.agent/rules/06-grid-gecerlilik-ve-jokerler.md`
  - `.agent/rules/07-skor-gecmisi-ve-oyun-bitisi.md`
**Plans**: 3 plans

Plans:
- [x] 05-01: Build market catalog, gold balance and purchase persistence
- [ ] 05-02: Execute joker actions from in-game inventory
- [x] 05-03: Implement score summary metrics and history list UI

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
Phases execute in numeric order: 1 -> 1.1 -> 2 -> 2.1 -> 3 -> 4 -> 5 -> 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation and Shell | 3/3 | Completed | 2026-04-07 |
| 01.1 Requirements, Architecture and Persistence Eval Gate | 3/3 | Completed | 2026-04-18 |
| 2. Game Setup and Board Foundation | 3/3 | Completed | 2026-04-18 |
| 02.1 Initial Board Solvability Gate | 1/1 | Completed | 2026-04-18 |
| 3. Core Gameplay and Session Results | 4/4 | Completed | 2026-04-18 |
| 4. Advanced Board Mechanics | 3/3 | Completed | 2026-04-21 |
| 5. Market and Score History | 2/3 | In progress | - |
| 6. Mobile Polish and Delivery | 0/3 | Not started | - |
