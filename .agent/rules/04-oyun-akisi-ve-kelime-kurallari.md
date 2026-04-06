# Oyun Akisi ve Kelime Kurallari

## Zorunlu Kurallar

1. Oyun ekraninda secilen grid boyutuna gore harf alani olusturulmalidir.
2. Griddeki harfler rastgele atanmalidir.
3. Harf uretimi tamamen duz rastgele olmamali, Turkce harf frekanslarina gore agirliklandirilmalidir.
4. Harf uretim algoritmasi, kelime olusabilirligini dikkate alacak sekilde gelistirilmelidir.
5. Oyuncu kelimeyi griddeki herhangi bir harften baslatabilmelidir.
6. Ilk secilen harf gorsel olarak vurgulanmalidir.
7. Oyuncu ilk harften sonra sadece komsu harflere gecebilmelidir.
8. Komsuluk 8 yonu kapsamalidir:
   - yukari
   - asagi
   - sag
   - sol
   - sag ust
   - sag alt
   - sol ust
   - sol alt
9. Her yeni secilen harf, bir onceki harfe komsu olmak zorundadir.
10. Ayni hucre ayni kelime icinde tekrar secilemez.
11. Gecerli kelime minimum 3 harften olusmalidir.
12. 3 harften kisa secimler gecersiz sayilmalidir.
13. Oyuncu parmagini ekrandan kaldirdiginda kelime olusturma islemi tamamlanmis sayilmalidir.
14. Secilen harfler birlestirilerek elde edilen kelime sozlukte kontrol edilmelidir.
15. Kelime sozlukte varsa gecerli kabul edilmelidir.
16. Gecerli kelimede secilen harfler patlatilmalidir.
17. Kelime sozlukte yoksa secim iptal edilmelidir.
18. Gecersiz kelimede harfler eski haline donmelidir.
19. Hem gecerli hem gecersiz kelime sonrasinda hamle sayisi 1 azalmalidir.
