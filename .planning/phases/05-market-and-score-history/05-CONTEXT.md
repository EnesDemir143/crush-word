# Phase 5: Market and Score History - Context

**Gathered:** 2026-04-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Bu faz, kullanicinin marketten joker satin alip oyunda kullanmasini ve daha onceki oyun performansini skor tablosunda incelemesini kapsar. Temel oyun motoru Phase 1-4 ciktilari uzerine oturmus kabul edilir.

</domain>

<decisions>
## Implementation Decisions

### Economy
- Baslangic altini sabit yuksek test degeri olacak (`9999`).
- Gercek para veya store entegrasyonu eklenmeyecek.

### Joker inventory
- Satin alinan jokerler yerel depolamada tutulacak.
- Bu veri, score history ile ayni `sqflite` veritabani icinde tutulacak.
- Tek kullanimli joker mantigi varsayilacak; kullanildiginda stok duser.

### Score history
- Gecmis oyunlar tek cihaz/tek kullanici bazinda saklanacak.
- Gecmis oyunlar `sqflite` tabanli SQLite kayitlarindan okunacak.
- Ozet metrikler kayitli sonuclardan turetilecek, ayri elle tutulmus aggregate tablo gerekmeyecek.

### Claude's Discretion
- Market karti gorselleri ve mini animasyon seviyesi
- Skor kartlarinin gorsel yogunlugu

</decisions>

<specifics>
## Specific Ideas

- Joker isimleri ve maliyetleri PDF'den dogrulanan sabit katalog olarak merkezi tek dosyada tutulmali.
- Skor ekraninda en yeni kaydin ustte olmasi zorunlu; bunu repository seviyesinde garanti etmek daha guvenli.
- Altin dusumu ve joker stok artisi ayni SQLite transaction icinde yapilabilirse ekonomi daha guvenli kalir.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Market and jokers
- `docs/Yazlab 2- Proje 2.pdf` - Joker aciklamalari ve altin maliyetleri
- `.agent/rules/06-grid-gecerlilik-ve-jokerler.md` - Joker zorunluluklari

### Score history
- `.agent/rules/07-skor-gecmisi-ve-oyun-bitisi.md` - Ozet ve liste alanlari

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Phase 3'te kaydedilen oyun sonuclari skor ekraninin veri kaynagi olacak.
- Phase 4 game session modeli, joker etkilerinin board'a uygulanmasi icin entegrasyon noktasi sunacak.

### Established Patterns
- Profil ve hafif ayarlar `shared_preferences`, envanter/altin/skor gecmisi ise ayni `sqflite` veritabani uzerinden gitmeli.

### Integration Points
- Home ekranindaki `Market` ve `Skor Tablosu` girisleri bu fazda gercek ekranlara baglanacak.
- In-game joker secici, markette satin alinan envanteri okuyacak.
- Phase 3'te acilan app database bu fazin market ve history repository'leri tarafindan paylasilacak.

</code_context>

<deferred>
## Deferred Ideas

- Rapor ve teslim artefaktlari - Phase 6

</deferred>

---

*Phase: 05-market-and-score-history*
*Context gathered: 2026-04-07*
