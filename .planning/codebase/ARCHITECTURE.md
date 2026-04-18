# Architecture

**Analysis Date:** 2026-04-18

## Pattern Overview

**Overall:** Su anda tek dosyali Flutter starter uygulamasi; hedef mimari ise yerel depolamali, feature-first organize edilmis mobil oyun uygulamasi.

**Key Characteristics:**
- Tek istemci uygulamasi
- Sunucusuz, yerel veri odakli calisma
- Hibrit persistence: `shared_preferences` + SQLite
- Runtime config: `assets/config/game_rules.json`
- Oyun motoru ile UI'nin ayrilmasi ihtiyaci
- Skor, joker ve grid mantiginin saf Dart katmanlarinda testlenebilir tutulmasi gerekliligi

## Layers

**App Shell:**
- Purpose: Uygulama baslatma, tema, route ve genel kabuk davranislarini yonetmek
- Contains: `main.dart`, uygulama widget'i, route tanimlari
- Depends on: Feature ekranlari ve temel konfigrasyon
- Used by: Tum uygulama

**Feature Layer:**
- Purpose: Onboarding, home, game setup, game, market ve skor gecmisi ekranlarini tasimak
- Contains: Screen, controller ve feature-ozel widget'lar
- Depends on: Core modeller, repository'ler, game engine
- Used by: App shell

**Core Gameplay Layer:**
- Purpose: Is kurallarini UI'dan bagimsiz sekilde tanimlamak
- Contains: `lib/src/core/gameplay/` altinda modeller, rule engine'ler ve gameplay servisleri
- Depends on: Dart temel kutuphaneleri ve `lib/src/core/config/` tarafindan yuklenen typed config
- Used by: Feature layer ve repository/controller koordinasyonu

**Config Layer:**
- Purpose: Runtime sabitlerini typed ve validate edilmis bicimde yuklemek
- Contains: `lib/src/core/config/` ve `assets/config/game_rules.json`
- Depends on: Flutter asset loading + JSON decode
- Used by: `lib/src/core/gameplay/`, katalog/repository hazirlama akislari

**Persistence Adapter Layer:**
- Purpose: `sqflite` detaylarini tablo, mapper ve migration seviyesinde izole etmek
- Contains: `lib/src/core/persistence/sqlite/`
- Depends on: `sqflite`, `path`, JSON serialization
- Used by: repository katmani

**Repository Layer:**
- Purpose: Uygulama tarafina persistence ve config verisini domain-dostu arayuzlerle sunmak
- Contains: `lib/src/core/repositories/`
- Depends on: `shared_preferences`, `lib/src/core/persistence/sqlite/`, `lib/src/core/config/`
- Used by: Feature layer

## Data Flow

**Typical App Flow:**
1. Uygulama baslar
2. `shared_preferences` icinden kayitli kullanici adi kontrol edilir
3. Varsa `session_checkpoint` + `player_wallet` + `joker_inventory` verisi `word_crush.db` uzerinden okunarak resume adayi degerlendirilir
4. Kullanici onboarding veya ana ekrana gider
5. Yeni oyun akisi grid ve hamle secimini toplar
6. `lib/src/core/config/` tarafindan yuklenen `game_rules.json` sabitleriyle session state uretilir
7. Oyun ekrani `lib/src/core/gameplay/` rule engine'leri ile state uretir/gunceller
8. Sonuclar `game_results` uzerinden, ekonomi state'i `player_wallet` / `joker_inventory` uzerinden yazilir
9. Skor ve market ekranlari repository katmanindan depolanan veriyi okur

**State Management:**
- Mevcut kodda yalnizca `setState`
- Hedefte hafif controller + repository yapisi oneriliyor
- Harici, agir state yonetimi framework'u zorunlu degil

## Key Abstractions

**Game Session:**
- Purpose: Tek bir oyunun gridi, hamlesi, puani, secili yol, power tile'lari ve kalan joker durumunu temsil etmek
- Pattern: Mutable session state + pure rule engines

**Rule Engine:**
- Purpose: Kelime gecerliligi, puanlama, combo, board refill, joker etkileri ve dead-board cozumunu hesaplamak
- Pattern: Stateless service / pure function agirlikli

**Repository:**
- Purpose: Kullanici, market ve skor gecmisi verisini saklayip okumak
- Pattern: Hibrit local adapter (`shared_preferences` profil/ayarlar, `sqflite` structured game data)

**SQLite Boundary:**
- Database file: `word_crush.db`
- Tables: `game_results`, `player_wallet`, `joker_inventory`, `session_checkpoint`
- Repository examples: `wallet_repository.dart`, `session_checkpoint_repository.dart`

## Entry Points

**Flutter entry point:**
- Location: `lib/main.dart`
- Triggers: `flutter run`
- Responsibilities: Uygulamayi baslatmak

## Error Handling

**Strategy:** Su an acik bir hata yonetim katmani yok.

**Needed patterns for target app:**
- Kullaniciya gore anlamli hata/uyari metinleri
- Sozluk yuklenememesi veya bozuk save verisinde guvenli fallback
- Oyun state guncellemelerinde atomik davranis

## Cross-Cutting Concerns

**Validation:**
- Kelime, komsuluk, hamle ve grid oynanabilirligi merkezi kurallarla dogrulanmali

**Persistence:**
- Kullanici adi ve hafif tercihler `shared_preferences` uzerinden tutulmali
- Skor gecmisi, altin ve joker envanteri `sqflite` repository'leri uzerinden atomik tutulmali
- App background/resume icin grid, hamle ve sure bilgisi `session_checkpoint` uzerinden geri yuklenmeli

**Configuration:**
- `assets/config/game_rules.json` config-driven sabitler icin canonical source olmali
- Combo, non-overlapping count ve power effects gibi code-driven davranislar JSON'a tasinmamali

**Testing:**
- En kritik coverage oyun motoru kurallari uzerinde olmali

---
*Architecture analysis: 2026-04-18*
*Update when major patterns change*
