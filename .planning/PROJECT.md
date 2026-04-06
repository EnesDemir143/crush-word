# Word Crush Mobil Oyunu

## What This Is

Kocaeli Universitesi Yazilim Laboratuvari-II icin gelistirilecek bu proje, Turkce kelime bulmaya dayali bir mobil oyun uygulamasidir. Oyuncu kare grid uzerindeki harfleri surukleyerek kelime olusturur; gecerli kelimeler patlar, puan kazandirir ve yerine yeni harfler duser. Uygulama, ders dokumanindaki zorunlu kurallari eksiksiz karsilayacak sekilde Android veya iOS tarafinda calisan, yerel verili ve sunuma hazir bir Flutter uygulamasi olarak planlanmistir.

## Core Value

Oyuncuya her zaman oynanabilir kalan, kurallari acikca gorunen ve ders dokumanindaki tum zorunlu maddeleri eksiksiz yerine getiren bir mobil kelime oyunu sunmak.

## Requirements

### Validated

(None yet - ship to validate)

### Active

- [ ] Dokumandaki zorunlu mobil uygulama akisi, oyun kurallari, jokerler, skor gecmisi ve teslim beklentileri tam kapsamli olarak uygulanacak.
- [ ] Mimari, bu proje icin gereksiz backend, online servis, cok katmanli state yonetimi veya premium sistemler eklemeden yalnizca gerekli parcalardan kurulacak.
- [ ] Kod tabani, oyun mantigi gibi riskli bolumleri test edilebilir tutacak; sunumda canli anlatim ve degisiklik yapmaya uygun kalacak.

### Out of Scope

- Online leaderboard, hesap sistemi veya bulut senkronizasyonu - dokumanda istenmiyor ve gereksiz karmasiklik ekliyor.
- Gercek para ile satin alma veya uygulama ici odeme - dokuman bunu acikca istemiyor, hatta yuksek/sinirsiz test altini tercih ediyor.
- Web ve masaustu urun ciktisi - sunum mobil ortamda yapilacak, bu hedef proje teslim kapsamina girmiyor.
- Agir state-management veya mikro-servis benzeri yapilar - proje buyuklugu icin gereksiz.

## Context

Repo su an varsayilan Flutter counter uygulamasi seviyesinde ve urun davranisi henuz gerceklesmis degil. Asil urun gereksinimleri `docs/yazlab_2_2/Yazlab 2- Proje 2/auto/Yazlab 2- Proje 2.md`, orijinal `docs/Yazlab 2- Proje 2.pdf` ve bunlardan cikartilan `.agent/rules/*.md` dosyalarinda. PDF uzerinden ek olarak harf puan tablosu, joker altin degerleri ve ozel guc sembol davranislari dogrulandi.

## Constraints

- **Platform**: Uygulama Android veya iOS icin calismali - web/masaustu gosterimleri kabul edilmiyor.
- **Timeline**: Proje teslim tarihi 1 Mayis 2026 - kalan sure sinirli oldugu icin MVP odakli, dusuk riskli bir mimari gerekli.
- **Presentation**: Sunumlar 4-8 Mayis 2026 haftasinda yapilacak - akisin emulator veya fiziksel cihazda sorunsuz calismasi gerekiyor.
- **Product Scope**: Uygulama tek oyunculu, yerel verili bir kelime oyunu olmali - backend ve online servis varsayilmamali.
- **Data Source**: Kelime dogrulamasi icin uygulama icinde paketlenmis Turkce sozluk gerekli - harici API bagimliligi olmamali.
- **Documentation**: Rapor LaTeX ile IEEE formatinda en az 4 sayfa olacak sekilde hazirlanmali - kod deposunda rapor iskeleti ve kaynaklari tutulmali.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Flutter tabanli, yerel calisan uygulama hedefi | Mevcut repo Flutter ve proje dokumani mobil agirlikli | - Pending |
| Backend yerine yerel kalici depolama kullan | Skor gecmisi, kullanici adi, altin ve joker envanteri icin yeterli; gereksiz karmasiklik azaltir | - Pending |
| Sozluk dosyasini uygulama asset'i olarak paketle | Sunum sirasinda offline ve deterministik davranis saglar | - Pending |
| Oyun mantigini UI'dan ayri servis/controller katmanlarinda tut | Grid, combo, joker ve puanlama davranislarini test edilebilir hale getirir | - Pending |
| Agir state-management kutuphaneleri ekleme | Proje olcegi icin built-in Flutter yapilari ve yalnizca gerekli controller katmani yeterli | - Pending |

---
*Last updated: 2026-04-07 after initial GSD planning setup*
