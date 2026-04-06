# Codebase Concerns

**Analysis Date:** 2026-04-07

## Tech Debt

**Starter application baseline:**
- Issue: `lib/main.dart` halen Flutter counter ornegi
- Why: Proje daha yeni olusturulmus
- Impact: Gereksinimlerin neredeyse hicbiri uygulanmis degil
- Fix approach: Uygulama kabugunu feature-first yapiya tasiyip starter kodu tamamen kaldirmak

**No project git repository:**
- Issue: Calisma klasoru git deposu degil
- Why: Repo init edilmemis
- Impact: Planning ve implementation asamalarinda surumleme, geri donus ve commit akisi eksik
- Fix approach: Kod calismasi baslamadan once git init + mantikli `.gitignore`

## Known Bugs

**Product-level missing implementation:**
- Symptoms: Uygulama acildiginda kelime oyunu yerine sayaç ekrani geliyor
- Trigger: `flutter run`
- Workaround: Yok
- Root cause: Urun davranisi henuz yazilmamis

## Security Considerations

**Local save integrity:**
- Risk: Bozuk ya da eksik kayitli veri uygulamayi acilista bozabilir
- Current mitigation: Yok
- Recommendations: Save verisi icin guvenli parse + fallback default state kullan

## Performance Bottlenecks

**Potential future hotspot - word search:**
- Problem: Tum gridde kelime var mi taramasi ve non-overlapping word count hesabi pahali olabilir
- Measurement: Henuz uygulanmadi
- Cause: 8 yonlu kombinasyon aramasi
- Improvement path: Prefix tabanli pruning, cache'leme ve net hamle-sonrasi tarama siniri

## Fragile Areas

**Touch selection behavior:**
- Why fragile: Mobil gesture akisi UI ve oyun state'ini es zamanli etkiliyor
- Common failures: Yanlis komsuluk, duplicate cell secimi, finger-up finalize bug'lari
- Safe modification: Gesture kodu ile rule validation ayri tutulmali
- Test coverage: Henuz yok

**Board solvability logic:**
- Why fragile: Harf uretimi, refill ve dead-board recovery birbirine bagli
- Common failures: Oyuncuya hic kelime olmayan board gostermek
- Safe modification: Generator ve analyzer ayni kurallar setini kullanmali
- Test coverage: Henuz yok

## Missing Critical Features

**Almost entire product scope:**
- Problem: Onboarding, game setup, gameplay, market, history ve delivery artifact'lari yok
- Current workaround: Yok
- Blocks: Projenin teslim ve sunumu
- Implementation complexity: High but manageable with phase-based delivery

## Test Coverage Gaps

**Game rules:**
- What's not tested: Grid, scoring, combo, joker, endgame
- Risk: Sunum oncesi regressions fark edilmez
- Priority: High
- Difficulty to test: Orta; saf Dart servislerine ayrilirsa kolaylasir

---
*Concerns audit: 2026-04-07*
*Update as issues are fixed or new ones discovered*
