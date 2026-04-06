# Testing Patterns

**Analysis Date:** 2026-04-07

## Test Framework

**Runner:**
- `flutter_test`

**Assertion Library:**
- Dart/Flutter built-in `expect`

**Run Commands:**
```bash
flutter test
flutter test test/widget_test.dart
flutter analyze
```

## Test File Organization

**Current location:**
- `test/widget_test.dart`

**Recommended expansion:**
- `test/core/` - oyun motoru unit testleri
- `test/features/` - secili widget testleri
- `integration_test/` - kritik mobil smoke flow'lari

## Test Structure

**Needed patterns for this project:**
- Arrange / act / assert yapisi
- Grid generator ve scoring icin deterministic fixture kullanimi
- UI surukleme davranislari icin widget/integration test kombinasyonu

## Mocking

**What to mock:**
- Local storage adapter'i
- Saat/tarih ureten katmanlar

**What not to mock:**
- Puanlama, combo, komsuluk ve kelime arama kurallari

## Coverage

**Highest priority coverage:**
- Grid komsuluk kurallari
- Kelime validation akisi
- Puan tablosu ve combo toplami
- Ozel guc ve joker etkileri
- Skor gecmisi ozet hesaplari

## Test Types

**Unit Tests:**
- Saf Dart oyun kurallari

**Widget Tests:**
- Username gate
- Home menu
- New game akisi
- Skor tablosu ozet kartlari

**Manual / Device Verification:**
- Surukleyerek harf secimi
- Oyun bitis akisi
- Joker kullanimi
- Emulator/telefon sunum akisi

## Current Gaps

- Projede anlamli bir test suiti henuz yok
- Varsayilan starter test, hedef urun icin degerli coverage saglamiyor

---
*Testing analysis: 2026-04-07*
*Update when test strategy changes*
