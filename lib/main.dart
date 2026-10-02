import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/queue_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('Firebase.initializeApp note: $e');
  }

  runApp(const StudentQueueApp());
}

class StudentQueueApp extends StatelessWidget {
  const StudentQueueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QueueProvider(),
      child: MaterialApp(
        title: 'Fayoum Students',
        debugShowCheckedModeBanner: false,

        // Arabic RTL Localization
        locale: const Locale('ar', 'EG'),
        supportedLocales: const [
          Locale('ar', 'EG'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        // Modern Material 3 Theme with Google Fonts
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0284C7),
            primary: const Color(0xFF0284C7),
            secondary: const Color(0xFF0D9488),
            surface: const Color(0xFFF8FAFC),
          ),
          textTheme: GoogleFonts.cairoTextTheme(ThemeData.light().textTheme),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),

        home: const MainNavigationScreen(),
      ),
    );
  }
}
