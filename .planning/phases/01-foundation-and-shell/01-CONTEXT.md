# Phase 1: Foundation and Shell - Context

**Gathered:** 2026-04-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Bu faz, starter Flutter uygulamasini gercek urun kabuguna donusturur. Kapsam: kullanici adi onboarding'i, ana ekran navigasyonu, temel tema/shell, yerel veri temeli ve paketlenmis sozluk altyapisidir. Oyun setup'i, grid davranisi, market ve skor detaylari bu fazin disindadir.

</domain>

<decisions>
## Implementation Decisions

### App structure
- Kod tabani `lib/src/` altinda feature-first duzende ayrilacak.
- `main.dart` yalnizca bootstrap gorevi gorecek; urun widget agaci ayri app dosyasina alinacak.

### Persistence
- Kullanici adi ve temel kalici veriler yerel depolamada tutulacak.
- Bu proje icin backend veya hesap sistemi kurulmayacak.

### Navigation
- Ana akista agir bir routing kutuphanesi yerine Flutter'in kendi navigation yapisi yeterli kabul ediliyor.
- Ana ekran merkezde uc ana aksiyonu acikca gosterecek.

### Claude's Discretion
- Tema renkleri ve tipografi detaylari
- Home ekraninin mikro yerlesim kararları

</decisions>

<specifics>
## Specific Ideas

- Kullanici adinin gorunur ve duzenlenebilir olmasi, sunum sirasinda hocalarin kolayca fark edecegi sekilde tasarlanacak.
- Sozluk dosyasi bu fazda eklenmeli ki sonraki fazlar harici kaynaga bagimli kalmasin.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Product scope
- `docs/yazlab_2_2/Yazlab 2- Proje 2/auto/Yazlab 2- Proje 2.md` - Tum urun akisinin ana kaynagi
- `docs/Yazlab 2- Proje 2.pdf` - Orijinal kaynak belge

### Mandatory rules
- `.agent/rules/01-platform-ve-temel-kisitlar.md` - Mobil kapsam ve sozluk/grid zorunluluklari
- `.agent/rules/02-giris-ve-ana-ekran.md` - Kullanici adi ve ana ekran gereksinimleri

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/main.dart`: Sadece Flutter bootstrap noktasi olarak kalabilir; urun mantigi tasimiyor.
- `pubspec.yaml`: Asset ve olasi hafif package eklemeleri burada yonetilecek.

### Established Patterns
- Mevcut proje Flutter defaults disinda bir pattern olusturmamis.

### Integration Points
- Bu fazda olusacak app shell, sonraki tum fazlarin baglanacagi ortak catisi olacak.

</code_context>

<deferred>
## Deferred Ideas

- Yeni oyun akisi ve grid olusturma - Phase 2
- Kelime dogrulama ve puanlama - Phase 3
- Joker/market ve skor tablosu icerigi - Phase 5

</deferred>

---

*Phase: 01-foundation-and-shell*
*Context gathered: 2026-04-07*
