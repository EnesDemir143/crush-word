import 'package:flutter/material.dart';

import 'package:crush_word/src/features/market/market_screen.dart';

class MarketRoutes {
  static Route<dynamic> build(RouteSettings settings) {
    return MaterialPageRoute<void>(
      builder: (_) => const MarketScreen(),
      settings: settings,
    );
  }
}
