import 'dart:async';

import 'package:flutter/material.dart';

import 'package:crush_word/src/core/config/game_rules_config.dart';
import 'package:crush_word/src/features/market/market_controller.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key, this.controller});

  final MarketController? controller;

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  late final MarketController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? MarketController();
    _ownsController = widget.controller == null;
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }

    super.dispose();
  }

  Future<void> _purchase(MarketJokerDefinition joker) async {
    final MarketPurchaseStatus status = await _controller.purchaseJoker(joker);

    if (!mounted) {
      return;
    }

    final String message = switch (status) {
      MarketPurchaseStatus.success =>
        '${joker.name} envantere eklendi.',
      MarketPurchaseStatus.insufficientGold =>
        'Bu joker için yeterli altın yok.',
      MarketPurchaseStatus.busy => 'Satın alma işlemi zaten sürüyor.',
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showJokerDetails(MarketJokerDefinition joker) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, _) {
            return AlertDialog(
              titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
              title: Row(
                children: <Widget>[
                  _JokerArtwork(jokerId: joker.id),
                  const SizedBox(width: 12),
                  Expanded(child: Text(joker.name)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _InfoChip(
                        key: Key('market-dialog-price-${joker.id}'),
                        icon: Icons.toll_rounded,
                        label: '${joker.cost}',
                      ),
                      _InfoChip(
                        key: Key('market-dialog-stock-${joker.id}'),
                        icon: Icons.inventory_2_rounded,
                        label: '${_controller.quantityFor(joker.id)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    joker.description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Color(0xFF3A3025),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DetailBlock(title: 'Kullanım şekli', content: joker.usage),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Kapat'),
                ),
                FilledButton.icon(
                  key: Key('market-dialog-buy-${joker.id}'),
                  onPressed:
                      _controller.canPurchase(joker) &&
                          !_controller.isPurchasing(joker.id)
                      ? () => _purchase(joker)
                      : null,
                  icon: _controller.isPurchasing(joker.id)
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.shopping_cart_checkout_rounded),
                  label: Text(
                    _controller.isPurchasing(joker.id)
                        ? 'İşleniyor'
                        : 'Satın Al',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            foregroundColor: const Color(0xFF3A3025),
            elevation: 0,
            title: const Text(
              'Market',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF3A3025),
              ),
            ),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _GoldHeaderChip(goldBalance: _controller.goldBalance),
              ),
            ],
          ),
          extendBodyBehindAppBar: false,
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xFFFDF8F0),
                  Color(0xFFF5EBDA),
                  Color(0xFFEDE0CB),
                ],
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _buildBody(context),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_controller.isLoading && _controller.marketRules == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.error != null && _controller.marketRules == null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Market yüklenemedi.',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Joker kataloğu veya ekonomi verisi okunurken hata oluştu.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => _controller.load(force: true),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      children: <Widget>[
        for (final MarketJokerDefinition joker in _controller.jokers) ...[
          _JokerCard(
            joker: joker,
            quantity: _controller.quantityFor(joker.id),
            isPurchasing: _controller.isPurchasing(joker.id),
            canPurchase: _controller.canPurchase(joker),
            onShowDetails: () => _showJokerDetails(joker),
            onPurchase: () => _purchase(joker),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _GoldHeaderChip extends StatelessWidget {
  const _GoldHeaderChip({required this.goldBalance});

  final int goldBalance;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4E4C8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE1C89C)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.monetization_on_rounded,
              color: Color(0xFF9A6B00),
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              '$goldBalance',
              key: const Key('market-gold-balance'),
              style: const TextStyle(
                color: Color(0xFF6E5432),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JokerCard extends StatelessWidget {
  const _JokerCard({
    required this.joker,
    required this.quantity,
    required this.isPurchasing,
    required this.canPurchase,
    required this.onShowDetails,
    required this.onPurchase,
  });

  final MarketJokerDefinition joker;
  final int quantity;
  final bool isPurchasing;
  final bool canPurchase;
  final VoidCallback onShowDetails;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: Key('market-joker-${joker.id}'),
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onShowDetails,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE4D3B8)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _JokerArtwork(jokerId: joker.id),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            joker.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2F261D),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              _InfoChip(
                                key: Key('market-price-${joker.id}'),
                                icon: Icons.toll_rounded,
                                label: '${joker.cost}',
                              ),
                              _InfoChip(
                                key: Key('market-stock-${joker.id}'),
                                icon: Icons.inventory_2_rounded,
                                label: '$quantity',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  joker.description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Color(0xFF3A3025),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Detay için dokun',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    key: Key('market-buy-${joker.id}'),
                    onPressed: canPurchase && !isPurchasing ? onPurchase : null,
                    icon: isPurchasing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.shopping_cart_checkout_rounded),
                    label: Text(isPurchasing ? 'İşleniyor' : 'Satın Al'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JokerArtwork extends StatelessWidget {
  const _JokerArtwork({required this.jokerId});

  final String jokerId;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF1A5D57), Color(0xFF2E8B7A)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(
          _iconFor(jokerId),
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF7A6F62),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.45,
            color: Color(0xFF3A3025),
          ),
        ),
      ],
    );
  }
}

IconData _iconFor(String jokerId) {
  return switch (jokerId) {
    'fish' => Icons.set_meal_rounded,
    'wheel' => Icons.trip_origin_rounded,
    'lollipop_breaker' => Icons.close_rounded,
    'free_swap' => Icons.swap_horiz_rounded,
    'shuffle_letters' => Icons.shuffle_rounded,
    'party_booster' => Icons.celebration_rounded,
    _ => Icons.auto_awesome_rounded,
  };
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF6EEE1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: const Color(0xFF8B6A12)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF604A12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
