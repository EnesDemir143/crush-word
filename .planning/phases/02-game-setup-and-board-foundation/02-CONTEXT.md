# Phase 2: Game Setup and Board Foundation - Context

**Gathered:** 2026-04-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Bu faz, kullanicinin yeni oyun olusturabildigi ayar akisina ve secilen zorluk/move degerleriyle ilk board'u gorebildigi oyun ekranina odaklanir. Agirlikli harf uretimi, kare grid gorsel yapisi ve drag-path toplama davranisi bu faza dahildir. Kelimenin gecerli olup olmadigini hesaplayan tam oyun sonucu bu fazda tamamlanmaz.

</domain>

<decisions>
## Implementation Decisions

### Difficulty setup
- Grid ve zorluk eslesmesi dokumandaki adlarla birebir korunacak.
- Hamle secimi dokumandaki sabit degerlerle sinirli olacak; serbest numeric input olmayacak.

### Board generation
- Harf uretimi Turkce frekans kategorileriyle agirliklandirilacak.
- Board olusturucu, testlenebilir olmasi icin deterministik random wrapper ile tasarlanacak.

### Interaction
- Oyuncu secimi surukleme bazli toplanacak.
- Komsuluk ve duplicate-cell engeli secim sirasinda uygulanacak.

### Claude's Discretion
- Ayar ekraninin tek sayfa mi yoksa iki adim mi olacagi
- Path highlight gorsel stili

</decisions>

<specifics>
## Specific Ideas

- `6x6 = Zor` ve `10x10 = Kolay` tersine sezgisel oldugu icin UI metinleri bunu acikca gostermeli.
- Oyun ekrani, daha Phase 2'de fiziksel boyut farklarina gore okunakli olmalı.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Gameplay setup
- `docs/yazlab_2_2/Yazlab 2- Proje 2/auto/Yazlab 2- Proje 2.md` - Yeni oyun ve grid yapisi bolumleri
- `.agent/rules/03-yeni-oyun-ve-zorluk.md` - Zorluk ve hamle sayisi zorunluluklari
- `.agent/rules/04-oyun-akisi-ve-kelime-kurallari.md` - Komsuluk ve secim kurallari

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Phase 1 app shell ve ana ekran ciktilari yeni oyun akisina giris noktasi olacak.
- Phase 1'de eklenen sozluk yukleyici ve temel modeller board/session olusturmada yeniden kullanilacak.

### Established Patterns
- Agir framework yerine basit controller + model yaklaşimi korunmali.

### Integration Points
- Yeni oyun akisi ana ekrandan acilacak.
- Game screen, sonraki fazlarda validation/scoring motoruna evrilecek ortak container olacak.

</code_context>

<deferred>
## Deferred Ideas

- Kelime dogrulama ve puanlama - Phase 3
- Board'un her zaman oynanabilir kalmasi ve combo/power mekanikleri - Phase 4

</deferred>

---

*Phase: 02-game-setup-and-board-foundation*
*Context gathered: 2026-04-07*
