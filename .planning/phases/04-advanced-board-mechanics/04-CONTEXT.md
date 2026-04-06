# Phase 4: Advanced Board Mechanics - Context

**Gathered:** 2026-04-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Bu faz, board'un her zaman oynanabilir kalmasi, olusturulabilir kelime sayisinin hesaplanmasi, combo puanlamasi ve uzun kelimelerden dogan ozel guclerin uretilip kullanilmasini kapsar. Marketten satin alinan jokerler bu fazin disinda kalir.

</domain>

<decisions>
## Implementation Decisions

### Playable-word analysis
- Analiz, board baslangicinda ve her hamle sonrasinda calisacak.
- Kullaniciya gosterilen sayi, ortak harf kullanmayan cozumlere gore hesaplanacak.

### Dead-board recovery
- Birinci tercih harfleri karistirmak.
- Hala cozum yoksa kontrollu yeniden uretim devreye girecek.

### Power tiles
- Ozel guc, son harf hucresinde kalacak ve alttaki harf bilgisini koruyacak.
- Gorsel farklilik overlay ikon ile verilecek; harf tamamen kaybolmayacak.

### Combo
- Combo icin yalnizca benzersiz alt kelimeler sayilacak.
- Harf sirasini bozan permutasyonlar sayilmayacak.

### Claude's Discretion
- Karistirma animasyonu stili
- Ozel guc ikonlarinin tasarimi

</decisions>

<specifics>
## Specific Ideas

- Dead-board recovery sonucu oyuncunun oyun akisi kesintiye ugramamali; board bir "hata" gibi degil, oyunun parcasi gibi yenilenmeli.
- Power tile davranislari testlerde 4/5/6/7+ kelime fixture'lariyla ayri ayri dogrulanmali.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Advanced gameplay
- `docs/Yazlab 2- Proje 2.pdf` - Ozel gucler, dead-board kontrolu ve combo aciklamalari
- `.agent/rules/05-puanlama-ozel-gucler-combo.md` - Power/combo zorunluluklari
- `.agent/rules/06-grid-gecerlilik-ve-jokerler.md` - Oynanabilir board ve kelime sayisi kurallari

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Phase 3 scoring ve board update pipeline'i, combo ve power hesaplarinin uzerine insa edilecek.
- Phase 2 board generator'i dead-board recovery stratejisinde yeniden kullanilacak.

### Established Patterns
- Oyun motoru kurallari saf servisler halinde kalmali; UI sadece sonuc state'ini gostermeli.

### Integration Points
- Guc tile state'i game session modeline eklenecek.
- Oynanabilir kelime sayisi ust bilgi paneline baglanacak.

</code_context>

<deferred>
## Deferred Ideas

- Marketten satin alinan jokerlerin envanter akisi - Phase 5
- Sunum polish ve test sweep - Phase 6

</deferred>

---

*Phase: 04-advanced-board-mechanics*
*Context gathered: 2026-04-07*
