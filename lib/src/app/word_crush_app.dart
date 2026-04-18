import 'package:flutter/material.dart';

import 'package:crush_word/src/app/app_routes.dart';
import 'package:crush_word/src/app/app_router.dart';
import 'package:crush_word/src/core/repositories/profile_repository.dart';
import 'package:crush_word/src/core/theme/app_theme.dart';

class WordCrushApp extends StatelessWidget {
  WordCrushApp({super.key, ProfileRepository? profileRepository})
    : _appRouter = AppRouter(
        profileRepository: profileRepository ?? ProfileRepository(),
      );

  final AppRouter _appRouter;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Word Crush',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: AppRoutes.onboarding,
      onGenerateRoute: _appRouter.onGenerateRoute,
    );
  }
}
