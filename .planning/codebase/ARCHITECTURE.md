# Architecture

**Analysis Date:** 2026-04-07

## Pattern Overview

**Overall:** Su anda tek dosyali Flutter starter uygulamasi; hedef mimari ise yerel depolamali, feature-first organize edilmis mobil oyun uygulamasi.

**Key Characteristics:**
- Tek istemci uygulamasi
- Sunucusuz, yerel veri odakli calisma
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

**Core / Domain Layer:**
- Purpose: Is kurallarini UI'dan bagimsiz sekilde tanimlamak
- Contains: Modeller, sabitler, depolama arabirimleri, game engine servisleri
- Depends on: Dart temel kutuphaneleri ve secilecek hafif yerel depolama mekanizmasi
- Used by: Feature layer

## Data Flow

**Typical App Flow:**
1. Uygulama baslar
2. Kayitli kullanici adi kontrol edilir
3. Kullanici onboarding veya ana ekrana gider
4. Yeni oyun akisi grid ve hamle secimini toplar
5. Oyun ekrani game engine ile state uretir/gunceller
6. Sonuclar yerel depolamaya yazilir
7. Skor ve market ekranlari depolanan veriyi okur

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
- Pattern: Local storage backed adapter

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
- Kullanici ve skor verisi tum ekranlarda tutarli olmali

**Testing:**
- En kritik coverage oyun motoru kurallari uzerinde olmali

---
*Architecture analysis: 2026-04-07*
*Update when major patterns change*
