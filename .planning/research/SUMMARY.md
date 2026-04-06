# Research Summary: Word Crush Mobil Oyunu

**Date:** 2026-04-07
**Sources Reviewed:**
- `docs/yazlab_2_2/Yazlab 2- Proje 2/auto/Yazlab 2- Proje 2.md`
- `docs/Yazlab 2- Proje 2.pdf`
- `.agent/rules/README.md`
- `.agent/rules/01-platform-ve-temel-kisitlar.md`
- `.agent/rules/02-giris-ve-ana-ekran.md`
- `.agent/rules/03-yeni-oyun-ve-zorluk.md`
- `.agent/rules/04-oyun-akisi-ve-kelime-kurallari.md`
- `.agent/rules/05-puanlama-ozel-gucler-combo.md`
- `.agent/rules/06-grid-gecerlilik-ve-jokerler.md`
- `.agent/rules/07-skor-gecmisi-ve-oyun-bitisi.md`
- `.agent/rules/08-teslim-ve-sunum-kurallari.md`
- `lib/main.dart`
- `pubspec.yaml`

## Executive Summary

Proje gereksinimleri acik ve kapsamli; asil risk, mevcut kodun neredeyse tamamen bos olmasi ve en zor bolumlerin oyun motoru tarafinda yogunlasmasi. Bu nedenle roadmap, once uygulama kabugunu ve yerel veri yapilarini kurup daha sonra grid ureteme, kelime dogrulama, puanlama, ozel guc, joker ve skor gecmisi gibi davranislari asamali sekilde oturtacak sekilde tasarlandi. Arastirma sonucu, bu proje icin en dogru strateji yerel-odakli, Flutter built-in yapilarini kullanan, testlenebilir ama hafif bir mimari kurmaktir.

## Confirmed Requirements From Sources

### Mobil ve Sunum Sinirlari
- Uygulama Android veya iOS icin gelistirilmeli.
- Sunum emulator veya fiziksel telefon uzerinden yapilmali.
- Web veya masaustu gosterimleri kabul edilmiyor.

### Giris ve Ana Ekran
- Ilk acilista kullanici adi alinmali ve saklanmali.
- Kullanici adi ana ekranin sol ustunden degistirilebilmeli.
- Ana ekranda `Yeni Oyun`, `Skor Tablosu`, `Market` secenekleri bulunmali.

### Oyun Kurulum Kurallari
- Zorluk-grid eslesmesi tam olarak:
  - `6x6 = Zor`
  - `8x8 = Orta`
  - `10x10 = Kolay`
- Hamle sayilari tam olarak:
  - `Zor = 15`
  - `Orta = 20`
  - `Kolay = 25`

### Kelime ve Grid Kurallari
- Harfler tam rastgele degil, Turkce frekansina gore agirlikli uretilmeli.
- Baslangicta ve hamlelerden sonra gridde en az bir gecerli kelime kalmali.
- Secim, 8 yonlu komsulukla ve tekrarli hucre kullanmadan yapilmali.
- Minimum kelime uzunlugu 3.
- Gecerli ve gecersiz denemelerin ikisi de 1 hamle harcamali.
- Gecerli kelimede harfler patlamali; gecersiz denemede secim geri alinmali.

### Harf Puanlari (PDF'den Dogrulandi)

| Harf | Puan | Harf | Puan |
|------|------|------|------|
| A | 1 | M | 2 |
| B | 3 | N | 1 |
| C | 4 | O | 2 |
| Ç | 4 | Ö | 7 |
| D | 3 | P | 5 |
| E | 1 | R | 1 |
| F | 7 | S | 2 |
| G | 5 | Ş | 4 |
| Ğ | 8 | T | 1 |
| H | 5 | U | 2 |
| I | 2 | Ü | 3 |
| İ | 1 | V | 7 |
| J | 10 | Y | 3 |
| K | 1 | Z | 4 |
| L | 1 |  |  |

### Ozel Guc Kurallari (PDF'den Dogrulandi)
- `4 harf`: Satir temizleme
- `5 harf`: Alan patlatma
- `6 harf`: Sutun temizleme
- `7+ harf`: Mega patlatma
- Ozel guc son harfin bulundugu hucrede kalir ve tekrar kullanildiginda aktive olur.

### Jokerler ve Altin Maliyetleri (PDF'den Dogrulandi)
- `Balık`: 100
- `Tekerlek`: 200
- `Lolipop Kırıcı`: 75
- `Serbest Değiştirme`: 125
- `Harf Karıştırma`: 300
- `Parti Güçlendiricisi`: 400

### Combo Kurallari
- Ana kelime icinde gecen anlamli alt kelimeler combo'ya dahil.
- Minimum alt kelime uzunlugu 3.
- Ayni alt kelime bir kez sayilir.
- Harf sirasi korunur.
- Alt kelime puanlari toplam puana eklenir.

### Skor Gecmisi ve Oyun Sonu
- Skor ekraninda ust ozet ve detayli gecmis listesi olmali.
- Oyun bitince sonuc kaydedilmeli ve ana ekrana donulmeli.
- Geri cikisinda `Evet/Hayir` onayi olmali.

### Teslim ve Rapor
- Rapor LaTeX ile yazilmali.
- IEEE formatinda en az 4 sayfa olmali.
- PDF ile birlikte LaTeX kaynaklari da teslim edilmeli.

## Current Codebase Findings

- `lib/main.dart` halen varsayilan Flutter counter ornegi.
- Uygulama davranisi, veri modeli, sozluk, oyun motoru veya ekran yapisi henuz yok.
- `pubspec.yaml` neredeyse sifir bagimlilikta; bu iyi, cunku gereksiz paket birikimi olmadan baslanabilir.
- Repo git deposu degil; planlama dokumanlari olusturulabilir ama commit akisi henuz kurulmus degil.

## Recommended Implementation Direction

### Mimari
- Backend kurma: hayir.
- Yerel kalici depolama: evet.
- Oyun mantigi ile UI'yi ayir: evet.
- Agir state-management kutuphanesi: hayir.

### Neden?
- Skor gecmisi, altin, kullanici adi ve envanter yerel depolama ile rahatca yonetilir.
- Grid, puan, combo, joker ve ozel guc kurallari saf Dart servislerine alininca test etmek kolaylasir.
- Ekran sayisi az ve veri akisi tek kullanicili; bu nedenle BLoC, Redux veya online senkronizasyon gerekmiyor.

### Onerilen Basit Yapilanma
- `lib/src/app/` - uygulama kabugu, tema, route tanimlari
- `lib/src/core/` - modeller, sabitler, depolama, ortak yardimcilar
- `lib/src/core/game_engine/` - board generator, validator, scoring, combo, power, joker davranislari
- `lib/src/features/` - onboarding, home, new game, game, market, score history
- `assets/dictionary/` - paketlenmis Turkce kelime listesi

## Risk Areas

### 1. Gridin Her Zaman Oynanabilir Kalmasi
Bu, projenin algoritmik olarak en zor bolumu. Salt agirlikli harf uretimi yeterli degil; uretim sonrasinda gecerli kelime taramasi ve gerekirse yeniden duzeltme gerekir.

### 2. Touch/Drag UX
8 yonlu surukleme, vurgulama, geri alma ve parmak kaldirma davranisi mobilde stabil olmali. Bunun widget tarafinda erken test edilmesi gerekir.

### 3. Combo ve Ozel Guc Etkilesimi
Bir kelime hem combo puani uretecek hem de son harfte power doguracak. Puanlama sirasi ve board guncelleme sirasinin netlestirilmesi gerekir.

### 4. Joker ve Ozel Guc Ayrimi
Oyun ici ozel gucler ile marketten satin alinan jokerler karistirilmamali. Biri kelime uzunlugundan dogan board tile etkisi, digeri ise kullanici envanterindeki aktif araclar olarak modellenmeli.

### 5. Kaynak Belgede Bozulan Karakterler
Markdown donusumunde bazi Turkce karakterler ve tablolar bozulmus. Yol haritasinda bu risk, orijinal PDF'den yeniden dogrulanan degerlerle azaltildi.

## Scope Guardrails

Asagidaki seyler bilerek roadmap disinda tutuldu:
- Online hesap, leaderboard, cloud backup
- Gercek para odeme veya store baglantilari
- Live ops, event system, remote config
- Buyuk animasyon sistemleri veya moduler plugin mimarileri
- Gereksiz package ekleme ve her ekran icin ayri state framework'u

## Open Decisions Resolved For Planning

- Baslangic altini: yuksek test altini (`9999`) veya esdeger sabit deger ile baslanacak.
- Dead-board cozum sirasi: once karistirma, yetmezse kontrollu yeniden uretim.
- Ozel guc gorseli: son harf korunacak, uzerinde ikon/overlay gosterilecek.
- Gecmis kayitlari: kullanici bazli tek cihaz icinde tutulacak.

## Planning Readiness

Plan olusturmaya hazir. Gereksinimler net, kritik veri tablolarinin eksikleri PDF ile kapatildi ve mevcut kod tabani yeni feature-first bir Flutter yapisina evrilebilecek durumda.
