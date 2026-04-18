# Crush Word

Crush Word, Kocaeli Universitesi Yazilim Laboratuvari-II kapsaminda gelistirilen
Flutter tabanli, tek oyunculu bir Turkce kelime oyunudur. Oyuncu kare grid
uzerindeki harfleri surukleyerek kelime olusturur; gecerli kelimeler puan
kazandirir, harfler temizlenir ve tahta yeniden dolar.

## Mevcut Durum

- Phase 3 tamamlandi.
- Kelime secimi, sozluk dogrulama, puanlama, gravity/refill, game-over akisi ve
  confirmed exit persistence aktif.
- Sonraki hedef: Phase 4 advanced board mechanics.

## Ozellikler

- Turkce sozlukle offline kelime dogrulama
- Zorluga gore 6x6 / 8x8 / 10x10 oyun kurulumu
- Turkce harf frekanslarina gore agirlikli board uretimi
- Gecerli ve gecersiz denemelerde hamle tuketimi
- Harf puan tablosuna gore skor hesaplama
- Gravity ve refill ile tahta cozumleme
- `sqflite` ile sonuc gecmisi ve aktif session checkpoint persistence
- Game-over overlay ve `Evet / Hayir` cikis onayi

## Teknoloji Yigini

- Flutter
- Dart
- `shared_preferences` for lightweight profile storage
- `sqflite` for structured local game persistence

## Proje Yapisi

```text
assets/
  config/
  dictionary/

lib/src/
  app/
  core/
    config/
    gameplay/
    persistence/sqlite/
    repositories/
  features/
    game/
    game_setup/
    home/
    onboarding/
```

## Calistirma

```bash
flutter pub get
flutter run
```

## Test ve Kontrol

Tum genel kontroller:

```bash
flutter analyze
flutter test
```

Phase 3 endgame persistence akisi icin hedef test:

```bash
flutter test test/features/game/endgame_flow_test.dart
```

## Local Persistence

Uygulama structured local data icin `word_crush.db` dosyasini kullanir.
Su an aktif tablolar:

- `game_results`
- `session_checkpoint`

Skor gecmisi UI'si Phase 5'te eklenecek olsa da result kayitlari simdiden
SQLite tarafinda tutulmaktadir.

## Lisans

Bu proje [MIT License](LICENSE) altinda lisanslanmistir.
