# Coding Conventions

**Analysis Date:** 2026-04-07

## Naming Patterns

**Files:**
- Flutter/Dart tarafinda `snake_case.dart`
- Test dosyalari `*_test.dart`

**Functions:**
- `camelCase`
- Event handler'larda `handle...` isimlendirmesi uygun

**Variables:**
- `camelCase`
- Sabitler icin `lowerCamelCase` veya gerektiğinde `const` liste/harita yapilari

**Types:**
- `PascalCase`
- Enum benzeri modeller acik isimli olmali

## Code Style

**Formatting:**
- Flutter formatter (`dart format`)
- Mevcut projede tek tip format beklentisi Flutter defaults

**Linting:**
- `flutter_lints`
- `flutter analyze` ile calistirilabilir

## Import Organization

**Recommended order:**
1. Flutter / external packages
2. Core project imports
3. Relative imports

## Error Handling

**Patterns:**
- UI'da sessizce yutulan hata yerine kontrollu fallback kullan
- Oyun mantigi servisleri exception yerine acik sonuc tipleri veya guard'lar ile ilerlemeli
- Bozuk save verisi durumunda temiz default state'e donebilmeli

## Logging

**Framework:**
- Su an standart debug print seviyesi yeterli

**Patterns:**
- Oyun algoritmasi hata ayiklamasinda gecici loglar olabilir
- Final kodda gereksiz gürültü olusturan loglar birakilmamali

## Comments

**When to Comment:**
- Karmaşık grid/cozum algoritmasi ve puanlama sirasini aciklamak icin
- "Neden" sorusunu cevaplayan kisa yorumlar

## Function Design

**Preferred shape:**
- Saf hesaplama yapan fonksiyonlar kisa ve testlenebilir olmali
- UI widget'lari oyun kurali hesaplamasi tasimamali

## Module Design

**Preferred shape:**
- Feature ekranlari UI odakli
- Oyun kurallari ve local storage ortak/core katmanda
- Tek bir dosyada buyuyen "god class" yapilarindan kacin

---
*Convention analysis: 2026-04-07*
*Update when patterns change*
