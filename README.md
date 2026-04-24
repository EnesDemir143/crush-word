# Crush Word

Crush Word, Kocaeli Üniversitesi Yazılım Laboratuvarı-II kapsamında geliştirilen,
Flutter tabanlı tek oyunculu bir Türkçe kelime oyunudur. Oyuncu kare harf
ızgarasında komşu hücreleri sürükleyerek kelimeler oluşturur; geçerli kelimeler
puan kazandırır, harfler temizlenir, gravity/refill çalışır ve oyun akışı yerel
olarak saklanır.

Proje şu anda ders kapsamındaki ana oyun döngüsünü, ileri seviye tahta
mekaniklerini, market/joker sistemini, skor geçmişini ve rapor teslim
varlıklarını aynı repoda birleştiren tamamlanmış bir mobil oyun projesi
seviyesindedir.

## Öne Çıkan Özellikler

### Oyuncu akışı
- İlk açılışta kullanıcı adı alma ve cihazda saklama
- Ana ekrandan kullanıcı adı düzenleme
- `Yeni Oyun`, `Skor Tablosu` ve `Market` girişleri

### Oyun kurulumu
- 6x6 (`Zor`), 8x8 (`Orta`) ve 10x10 (`Kolay`) tahta seçenekleri
- Zorluğa bağlı 15 / 20 / 25 hamle limitleri
- Türkçe harf frekanslarına göre ağırlıklı tahta üretimi
- İlk açılışta ve hamle sonrasında oynanabilir tahta koruması

### Çekirdek gameplay
- 8 yönlü komşuluk ile sürükle-bırak kelime seçimi
- Aynı hücreyi tekrar kullanmayan path kontrolü
- Sözlük tabanlı geçerli / geçersiz kelime doğrulama
- 3 harften kısa seçimlerde geçersiz deneme davranışı
- Geçerli ve geçersiz denemelerde hamle tüketimi
- Harf puan tablosuna göre skor hesaplama
- Gravity, refill ve dead-board recovery akışı
- Oyun içinde gösterilen oynanabilir kelime sayısı

### İleri mekanikler
- Alt kelime tabanlı combo puanlama
- Kelime uzunluğuna göre power tile üretimi:
  - 4 harf: satır temizleme
  - 5 harf: alan patlatma
  - 6 harf: sütun temizleme
  - 7+ harf: mega patlatma
- Power tile yeniden kullanıldığında özel etkinin tetiklenmesi

### Market ve joker sistemi
- Yüksek başlangıç altını ile test dostu ekonomi
- 6 zorunlu jokerin tamamı:
  - Balık
  - Tekerlek
  - Lolipop Kırıcı
  - Serbest Değiştirme
  - Harf Karıştırma
  - Parti Güçlendiricisi
- Satın alma, envanterde saklama ve oyun içinde kullanma akışı
- Joker katalogu, fiyatlar ve açıklamalar için tekil config kaynağı

### Skor geçmişi ve oturum yönetimi
- Oyun bitiminde sonucu yerel veritabanına kaydetme
- Çıkış onayı ile sonucu koruyarak ana ekrana dönme
- En yeni oyun en üstte olacak şekilde skor geçmişi
- Üst özet kartında toplam oyun, en yüksek skor, ortalama skor,
  toplam kelime, en uzun kelime ve toplam süre metrikleri
- Aktif oyun için session checkpoint altyapısı

## Teknoloji Yığını

- Flutter
- Dart
- `shared_preferences` — profil ve hafif kullanıcı verileri
- `sqflite` — oyun sonuçları, altın, joker envanteri ve checkpoint verileri
- `path` — yerel veritabanı yolu yönetimi
- `flutter_test` — unit ve widget testleri
- `sqflite_common_ffi` — persistence test altyapısı

## Mimari

Kod tabanı feature-first bir yapı izler ve oyun kurallarını UI katmanından
ayırır:

- `lib/src/app/` — uygulama bootstrap, route ve navigation tanımları
- `lib/src/core/config/` — oyun kuralları ve runtime config modelleri
- `lib/src/core/models/` — ortak domain modelleri
- `lib/src/core/repositories/` — sözlük, profil, geçmiş, cüzdan ve checkpoint sınırları
- `lib/src/core/storage/` — düşük seviye yerel depolama servisleri
- `lib/src/features/` — ekranlar, controller'lar ve kullanıcı akışları

## Proje Yapısı

```text
assets/
  config/game_rules.json
  dictionary/tr_words.txt
  images/
    jokers/

lib/
  main.dart
  src/
    app/
    core/
      config/
      models/
      presentation/
      repositories/
      storage/
      theme/
    features/
      game/
      game_setup/
      home/
      market/
      onboarding/
      score_history/

test/
  app/
  core/
  features/

report/
  main.tex
  main.pdf
  references.bib
```

## Çalıştırma

```bash
flutter pub get
flutter run
```

Mobil hedef seçerek çalıştırmak için örnek:

```bash
flutter run -d ios
flutter run -d android
```

## Doğrulama

Genel kalite kontrolleri:

```bash
flutter analyze
flutter test
```

Odaklı test örnekleri:

```bash
flutter test test/features/game/endgame_flow_test.dart
flutter test test/features/game/joker_bar_test.dart
flutter test test/features/score_history/score_history_screen_test.dart
```

## Yerel Veri Katmanı

Uygulama `word_crush.db` veritabanını kullanır. Kalıcı veri yapısında oyun
sonuçları, joker envanteri, cüzdan/veri dengesi ve aktif oturum checkpoint'i
saklanır. Bu sayede uygulama tamamen offline çalışabilir.

## Rapor ve Teslim Varlıkları

Repo içinde proje raporu ve ilgili teslim materyalleri de yer alır:

- `report/main.tex` — IEEE formatındaki LaTeX raporu
- `report/main.pdf` — üretilmiş PDF çıktısı
- `report/architecture.md` ve diyagram dosyaları — mimari özetler
- `docs/Yazlab 2- Proje 2.pdf` — kaynak ders/proje dokümanı

Raporu yeniden derlemek için:

```bash
cd report
pdflatex main.tex
bibtex main
pdflatex main.tex
pdflatex main.tex
```

## Lisans

Bu proje [MIT License](LICENSE) altında lisanslanmıştır.
