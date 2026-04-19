import 'package:flutter/foundation.dart';

import 'package:crush_word/src/core/config/game_rules_config.dart';
import 'package:crush_word/src/core/config/game_rules_loader.dart';
import 'package:crush_word/src/core/models/joker_inventory.dart';
import 'package:crush_word/src/core/repositories/joker_inventory_repository.dart';
import 'package:crush_word/src/core/repositories/wallet_repository.dart';

enum MarketPurchaseStatus { success, insufficientGold, busy }

class MarketController extends ChangeNotifier {
  factory MarketController({
    GameRulesLoader? loader,
    WalletRepository? walletRepository,
    JokerInventoryRepository? inventoryRepository,
  }) {
    return MarketController._(
      loader: loader ?? const GameRulesLoader(),
      walletRepository: walletRepository ?? WalletRepository(),
      inventoryRepository: inventoryRepository ?? JokerInventoryRepository(),
    );
  }

  MarketController._({
    required GameRulesLoader loader,
    required WalletRepository walletRepository,
    required JokerInventoryRepository inventoryRepository,
  }) : _loader = loader,
       _walletRepository = walletRepository,
       _inventoryRepository = inventoryRepository;

  final GameRulesLoader _loader;
  final WalletRepository _walletRepository;
  final JokerInventoryRepository _inventoryRepository;

  GameRulesConfig? _rules;
  bool _isLoading = false;
  Object? _error;
  int _goldBalance = 0;
  Map<String, int> _inventoryById = const <String, int>{};
  final Set<String> _purchasingJokerIds = <String>{};

  GameRulesConfig? get rules => _rules;
  bool get isLoading => _isLoading;
  Object? get error => _error;
  int get goldBalance => _goldBalance;

  MarketRules? get marketRules => _rules?.market;

  List<MarketJokerDefinition> get jokers =>
      marketRules?.jokers ?? const <MarketJokerDefinition>[];

  int quantityFor(String jokerId) => _inventoryById[jokerId] ?? 0;

  bool isPurchasing(String jokerId) => _purchasingJokerIds.contains(jokerId);

  bool canPurchase(MarketJokerDefinition joker) {
    return !isPurchasing(joker.id) && _goldBalance >= joker.cost;
  }

  Future<void> load({bool force = false}) async {
    if (_isLoading || (_rules != null && !force)) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final GameRulesConfig rules = await _loader.load();
      final MarketRules? market = rules.market;

      if (market == null) {
        throw const FormatException('Market rules are missing.');
      }

      final int goldBalance = await _walletRepository.loadGoldBalance();
      final List<JokerInventory> inventory =
          await _inventoryRepository.loadInventory();

      _rules = rules;
      _goldBalance = goldBalance;
      _inventoryById = Map<String, int>.unmodifiable(
        <String, int>{
          for (final JokerInventory item in inventory)
            item.jokerId: item.quantity,
        },
      );
    } catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<MarketPurchaseStatus> purchaseJoker(
    MarketJokerDefinition joker,
  ) async {
    if (_purchasingJokerIds.contains(joker.id)) {
      return MarketPurchaseStatus.busy;
    }

    if (_goldBalance < joker.cost) {
      return MarketPurchaseStatus.insufficientGold;
    }

    _purchasingJokerIds.add(joker.id);
    notifyListeners();

    int nextGoldBalance = _goldBalance;
    int nextQuantity = quantityFor(joker.id);

    try {
      final int currentGold = await _walletRepository.loadGoldBalance();

      if (currentGold < joker.cost) {
        return MarketPurchaseStatus.insufficientGold;
      }

      final int currentQuantity = await _inventoryRepository.quantityFor(
        joker.id,
      );

      nextGoldBalance = currentGold - joker.cost;
      nextQuantity = currentQuantity + 1;

      await _walletRepository.setGoldBalance(nextGoldBalance);
      await _inventoryRepository.setQuantity(joker.id, nextQuantity);
    } finally {
      _purchasingJokerIds.remove(joker.id);
    }

    _goldBalance = nextGoldBalance;
    _inventoryById = Map<String, int>.unmodifiable(<String, int>{
      ..._inventoryById,
      joker.id: nextQuantity,
    });
    notifyListeners();
    return MarketPurchaseStatus.success;
  }
}
