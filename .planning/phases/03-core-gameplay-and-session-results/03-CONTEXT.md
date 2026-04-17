# Phase 3: Core Gameplay and Session Results - Context

**Gathered:** 2026-04-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Bu faz, secilen yolun kelimeye donusturulmesi, sozlukte kontrol edilmesi, puan ve hamle guncellemesi, gecerli secimde board refill mantigi ve oyun sonucu kaydini kapsar. Combo, dead-board recovery ve ozel guc/joker davranislarinin ileri bolumleri bu fazdan sonra gelir.

</domain>

<decisions>
## Implementation Decisions

### Validation lifecycle
- Parmak kaldirma olayi secimi finalize eder.
- Gecerli ve gecersiz her deneme 1 hamle dusurur.
- Gecersiz denemede board state degismeyecek, yalnizca secim temizlenecek.

### Scoring
- Harf puanlari PDF'den dogrulanan tabloya gore tek kaynak olarak tutulacak.
- Puanlama, UI icinde daginik degil, tek bir scoring engine tarafindan hesaplanacak.

### Session persistence
- Oyun sonucu; grid boyutu, puan, bulunan kelime sayisi, en uzun kelime ve sure gibi alanlarla kaydedilecek.
- Bu kayitlar `shared_preferences` yerine `sqflite` tabanli bir `game_results` tablosuna yazilacak.
- Oyun sonu ve cikis onayi ayni result-save akisini kullanacak.

### Claude's Discretion
- Gecersiz kelime geri bildirim stili
- Oyun ekrani ust bilgi panelinin mikro yerlesimi

</decisions>

<specifics>
## Specific Ideas

- `soru = 7 puan` ornegi, scoring engine testlerinde ornek fixture olarak kullanilmali.
- Exit confirmation diyaloğu sade ve iki butonlu kalmali; ekstra branching eklenmemeli.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Gameplay rules
- `docs/Yazlab 2- Proje 2.pdf` - Puan tablosu ve kelime dogrulama anlatimi
- `.agent/rules/04-oyun-akisi-ve-kelime-kurallari.md` - Deneme ve secim kurallari
- `.agent/rules/05-puanlama-ozel-gucler-combo.md` - Harf puanlama temeli
- `.agent/rules/07-skor-gecmisi-ve-oyun-bitisi.md` - Oyun bitisi ve kayit davranisi

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Phase 2 board UI ve session bootstrap'i validation lifecycle'in girdisi olacak.
- Phase 1 dictionary altyapisi bu fazin validation adiminda kullanilacak.

### Established Patterns
- Grid state, UI widget'larina yayilmadan merkezi session modeli uzerinden guncellenmeli.
- Profil/ayarlar ve structured oyun verisi ayni depolama turunde karistirilmamali.

### Integration Points
- History persistence bu fazda `sqflite` ile yazilacak veriyi Phase 5'te okuyacak.

</code_context>

<deferred>
## Deferred Ideas

- Combo puani - Phase 4
- Ozel guc dogurma/aktive etme - Phase 4
- Market ve joker satin alma/kullanma - Phase 5

</deferred>

---

*Phase: 03-core-gameplay-and-session-results*
*Context gathered: 2026-04-07*
