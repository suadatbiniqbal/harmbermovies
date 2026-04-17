import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'services/theme_service.dart';
import 'services/watchlist_service.dart';
import 'services/fcm_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init local services
  await ThemeService.instance.init();
  await WatchlistService.instance.init();

  // Firebase (safe init)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler);
    await FcmService.instance.init();
  } catch (e) {
    debugPrint('Firebase not configured: $e');
  }

  // System UI
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const HarmberApp());
}

class HarmberApp extends StatelessWidget {
  const HarmberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final theme = ThemeService.instance;

        return MaterialApp(
          title: 'Harmber Movies',
          debugShowCheckedModeBanner: false,
          theme: theme.materialTheme.copyWith(
            textTheme: GoogleFonts.interTextTheme(
              theme.isDark
                  ? ThemeData.dark().textTheme
                  : ThemeData.light().textTheme,
            ),
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}