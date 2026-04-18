# Crush Word

Crush Word, Flutter ile gelistirilen tek oyunculu bir Turkce kelime bulma
oyunudur. Oyuncu kare bir harf tahtasi uzerinde komsu harfleri surukleyerek
kelimeler olusturur; gecerli kelimeler puan kazandirir, secilen hucreler
temizlenir ve tahta yeniden dolar. Proje, hizli oynanabilirlik, yerel
calisma, deterministik oyun kurallari ve test edilebilir gameplay mantigi
uzerine kuruludur.

## Oyun Deneyimi

- 6x6, 8x8 ve 10x10 olmak uzere farkli tahta boyutlari
- Turkce harf frekanslarina gore agirlikli harf uretimi
- Parmak surukleme ile kelime secimi
- Sozluk tabanli gecerli / gecersiz kelime kontrolu
- Harf puan tablosuna gore skor hesaplama
- Gravity ve refill ile her hamle sonrasi tahtanin yeniden kurulmasi
- Oyun bitisi ve onayli cikista sonuc kaydetme

## Temel Ozellikler

- Offline calisan Turkce kelime dogrulama
- Yerel persistence ile session ve sonuc yonetimi
- Game-over overlay ve `Evet / Hayir` cikis onayi
- Feature-first Flutter yapisi
- Ayrik gameplay servisleri sayesinde test edilebilir is kurallari
- SQLite tabanli gecmis ve checkpoint altyapisi

## Teknoloji Yigini

- Flutter
- Dart
- `shared_preferences` ile hafif profil bilgileri
- `sqflite` ile structured local persistence
- `path` ile yerel database path yonetimi
- `flutter_test` ile unit ve widget testleri
- `sqflite_common_ffi` ile persistence testleri

## Mimari Yapi

Uygulama, UI ile oyun kurallarini ayiran bir yapi izler:

- `lib/src/features/` ekranlar, route'lar ve kullanici akislarini barindirir
- `lib/src/core/gameplay/` board, scoring ve validation gibi oyun mantigini
  tasir
- `lib/src/core/config/` runtime oyun kurallarini ve config modellerini tutar
- `lib/src/core/repositories/` uygulamanin domain-facing veri sinirlarini
  saglar
- `lib/src/core/persistence/sqlite/` SQLite bootstrap ve persistence adapter
  detaylarini izole eder

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

## Guncel Durum

Su an proje; oyun kurulumu, drag-selection, kelime dogrulama, puanlama,
gravity/refill, game-over akisi ve yerel sonuc kaydi gibi temel gameplay
akisini desteklemektedir. Skor gecmisi ekraninin kullaniciya gosterilen UI
katmani ise sonraki gelistirme adimlarinda tamamlanacaktir.

## Gelistirme

### Calistirma

```bash
flutter pub get
flutter run
```

### Test ve Kontrol

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

Uygulama structured local data icin `word_crush.db` dosyasini kullanir. Mevcut
kalici veri katmani asagidaki tablolari kullanir:

- `game_results`
- `session_checkpoint`

Bu sayede tamamlanan oyunlar ve aktif oturum snapshot'lari yerel olarak
saklanabilir.

## Lisans

Bu proje [MIT License](LICENSE) altinda lisanslanmistir.
