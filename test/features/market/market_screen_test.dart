import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'package:crush_word/src/core/config/game_rules_loader.dart';
import 'package:crush_word/src/core/models/joker_inventory.dart';
import 'package:crush_word/src/core/repositories/joker_inventory_repository.dart';
import 'package:crush_word/src/core/repositories/wallet_repository.dart';
import 'package:crush_word/src/features/market/market_controller.dart';
import 'package:crush_word/src/features/market/market_screen.dart';

void main() {
  late MarketController controller;
  late _FakeWalletRepository walletRepository;
  late _FakeJokerInventoryRepository inventoryRepository;

  setUp(() {
    walletRepository = _FakeWalletRepository();
    inventoryRepository = _FakeJokerInventoryRepository();

    controller = MarketController(
      loader: GameRulesLoader(bundle: _TestAssetBundle(_gameRulesJson)),
      walletRepository: walletRepository,
      inventoryRepository: inventoryRepository,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  testWidgets('market shows the documented joker catalog and gold balance', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(home: MarketScreen(controller: controller)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('market-gold-balance')), findsOneWidget);
    expect(find.text('9999'), findsWidgets);

    expect(find.text('Balık'), findsOneWidget);
    expect(find.text('Tekerlek'), findsOneWidget);
    expect(find.text('Lolipop Kırıcı'), findsOneWidget);
    expect(find.text('Serbest Değiştirme'), findsOneWidget);

    expect(
      find.descendant(
        of: find.byKey(const Key('market-price-fish')),
        matching: find.text('100'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('market-price-wheel')),
        matching: find.text('200'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('market-price-lollipop_breaker')),
        matching: find.text('75'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('market-price-free_swap')),
        matching: find.text('125'),
      ),
      findsOneWidget,
    );

    expect(
      find.text(
        'Gridde rastgele olarak harfleri yok etmektedir. Rastgele yok olan '
        'harflerin üzerindeki harfler aşağıya düşmektedir.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Gridde seçilen harfin bulunduğu satır ve sütundaki tüm harfler yok '
        'olmaktadır.',
      ),
      findsOneWidget,
    );
    expect(find.text('Kullanım amacı'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Harf Karıştırma'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.text('Harf Karıştırma'), findsOneWidget);
    expect(find.text('Parti Güçlendiricisi'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('market-price-shuffle_letters')),
        matching: find.text('300'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('market-price-party_booster')),
        matching: find.text('400'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping a joker opens its detail popup', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(home: MarketScreen(controller: controller)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('market-joker-fish')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('market-dialog-price-fish')), findsOneWidget);
    expect(find.byKey(const Key('market-dialog-stock-fish')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('market-dialog-price-fish')),
        matching: find.text('100'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('market-dialog-stock-fish')),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );
    expect(find.text('Kullanım şekli'), findsOneWidget);
    expect(
      find.text(
        'Satın aldıktan sonra oyun ekranının altındaki joker alanından '
        'seçilerek etkinleştirilir.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Gridde rastgele olarak harfleri yok etmektedir. Rastgele yok olan '
        'harflerin üzerindeki harfler aşağıya düşmektedir.',
      ),
      findsWidgets,
    );
    expect(find.text('Açıklama'), findsNothing);
  });

  testWidgets('buying from the popup updates stock and gold', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(home: MarketScreen(controller: controller)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('market-joker-fish')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('market-dialog-buy-fish')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('9899'), findsWidgets);
    expect(
      find.descendant(
        of: find.byKey(const Key('market-dialog-stock-fish')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(find.text('Balık envantere eklendi.'), findsOneWidget);
  });

  testWidgets('buying a joker spends gold and updates inventory', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(home: MarketScreen(controller: controller)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('market-stock-fish')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('market-stock-fish')),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('market-buy-fish')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('9899'), findsWidgets);
    expect(
      find.descendant(
        of: find.byKey(const Key('market-stock-fish')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(find.text('Balık envantere eklendi.'), findsOneWidget);
  });
}

class _TestAssetBundle extends CachingAssetBundle {
  _TestAssetBundle(this.gameRulesJson);

  final String gameRulesJson;

  @override
  Future<ByteData> load(String key) async {
    final Uint8List bytes = Uint8List.fromList(utf8.encode(gameRulesJson));
    return ByteData.view(bytes.buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    return gameRulesJson;
  }
}

class _FakeWalletRepository extends WalletRepository {
  _FakeWalletRepository() : _goldBalance = 9999;

  int _goldBalance;

  @override
  Future<int> loadGoldBalance({DatabaseExecutor? executor}) async {
    return _goldBalance;
  }

  @override
  Future<void> setGoldBalance(
    int goldBalance, {
    DatabaseExecutor? executor,
  }) async {
    _goldBalance = goldBalance;
  }
}

class _FakeJokerInventoryRepository extends JokerInventoryRepository {
  final Map<String, int> _inventoryById = <String, int>{};

  @override
  Future<List<JokerInventory>> loadInventory({
    DatabaseExecutor? executor,
  }) async {
    return _inventoryById.entries.map((MapEntry<String, int> entry) {
      return JokerInventory(jokerId: entry.key, quantity: entry.value);
    }).toList(growable: false);
  }

  @override
  Future<int> quantityFor(
    String jokerId, {
    DatabaseExecutor? executor,
  }) async {
    return _inventoryById[jokerId] ?? 0;
  }

  @override
  Future<void> setQuantity(
    String jokerId,
    int quantity, {
    DatabaseExecutor? executor,
  }) async {
    _inventoryById[jokerId] = quantity;
  }
}

const String _gameRulesJson = '''
{
  "setup": {
    "difficultyOptions": [
      {
        "difficulty": "hard",
        "label": "Zor",
        "gridLabel": "6x6 Grid",
        "gridSize": 6
      }
    ],
    "moveCountOptions": [
      {
        "difficulty": "hard",
        "label": "Zor",
        "moveLimit": 15
      }
    ]
  },
  "market": {
    "initialGold": 9999,
    "jokers": [
      {
        "id": "fish",
        "name": "Balık",
        "cost": 100,
        "description": "Gridde rastgele olarak harfleri yok etmektedir. Rastgele yok olan harflerin üzerindeki harfler aşağıya düşmektedir.",
        "purpose": "Gridde sıkışan alanları açıp yeni kelime fırsatları oluşturmak için kullanılır.",
        "usage": "Satın aldıktan sonra oyun ekranının altındaki joker alanından seçilerek etkinleştirilir."
      },
      {
        "id": "wheel",
        "name": "Tekerlek",
        "cost": 200,
        "description": "Gridde seçilen harfin bulunduğu satır ve sütundaki tüm harfler yok olmaktadır.",
        "purpose": "Tek hamlede geniş bir satır ve sütun temizliği yapmak için kullanılır.",
        "usage": "Joker seçildikten sonra gridde hedeflenen harfe dokunularak uygulanır."
      },
      {
        "id": "lollipop_breaker",
        "name": "Lolipop Kırıcı",
        "cost": 75,
        "description": "Gridde seçilen bir harfi yok etmek için kullanılmaktadır. Bu harf yok olduğunda yukarısındaki kelimeler aşağı düşmektedir.",
        "purpose": "Tek bir harfi ortadan kaldırıp üstteki dizilimi aşağı düşürmek için kullanılır.",
        "usage": "Joker aktifken gridde kaldırılmak istenen harf seçilerek kullanılır."
      },
      {
        "id": "free_swap",
        "name": "Serbest Değiştirme",
        "cost": 125,
        "description": "Gridde birbirine temas eden iki harfin yer değiştirilmesini sağlamaktadır.",
        "purpose": "Komşu iki harfin yerini değiştirerek yeni kelime kombinasyonları hazırlamak için kullanılır.",
        "usage": "Joker seçildikten sonra birbirine temas eden iki harf peş peşe seçilerek uygulanır."
      },
      {
        "id": "shuffle_letters",
        "name": "Harf Karıştırma",
        "cost": 300,
        "description": "Bu özellik seçildiğinde gridde bulunan harflerin rastgele bir şekilde karıştırılmasını sağlamaktadır.",
        "purpose": "Tıkanan grid düzenini tamamen değiştirip yeni kelime olasılıkları üretmek için kullanılır.",
        "usage": "Joker seçildiğinde mevcut griddeki harfler rastgele karıştırılarak yeniden dağıtılır."
      },
      {
        "id": "party_booster",
        "name": "Parti Güçlendiricisi",
        "cost": 400,
        "description": "Bu özellik seçildiğinde gridde bulunan tüm harfler yok edilir ve tekrardan rastgele bir şekilde harfler yukarıdan aşağıya düşmektedir.",
        "purpose": "Tüm tahtayı sıfırlayıp baştan harf düşürerek büyük bir yeniden kurulum yapmak için kullanılır.",
        "usage": "Joker etkinleştirildiğinde grid tamamen temizlenir ve yeni harfler yukarıdan aşağıya yeniden gelir."
      }
    ]
  },
  "boardGeneration": {
    "letterFrequencyGroups": [
      {
        "tier": "high",
        "weight": 6,
        "letters": ["A", "E", "İ", "L", "R", "N"]
      }
    ]
  }
}
''';
