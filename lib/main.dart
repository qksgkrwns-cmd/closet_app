import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/auth_gate_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const ClosetApp());
}

class ClosetApp extends StatelessWidget {
  const ClosetApp({super.key});

  @override
  Widget build(BuildContext context) {
    const orangePrimary = Color(0xFFFF9500);
    const orangeLight = Color(0xFFFFB84D);
    const orangeAccent = Color(0xFFE67E22);
    const blackBg = Color(0xFF0D0D0D);
    const blackSurface = Color(0xFF1A1A1A);
    const textPrimary = Color(0xFFFFFFFF);
    const textSecondary = Color(0xFFB0B0B0);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: blackBg,
        primaryColor: orangePrimary,
        colorScheme: ColorScheme.dark(
          primary: orangePrimary,
          secondary: orangeLight,
          tertiary: orangeAccent,
          surface: blackSurface,
          error: const Color(0xFFE74C3C),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: blackSurface,
          foregroundColor: textPrimary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: const TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: blackSurface,
          selectedItemColor: orangePrimary,
          unselectedItemColor: textSecondary,
          elevation: 8,
          type: BottomNavigationBarType.fixed,
        ),
        buttonTheme: const ButtonThemeData(
          buttonColor: orangePrimary,
          textTheme: ButtonTextTheme.primary,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: orangePrimary,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: orangePrimary,
            side: const BorderSide(color: orangePrimary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: orangePrimary,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: orangePrimary,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: blackSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF404040)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF404040)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: orangePrimary, width: 2),
          ),
          hintStyle: const TextStyle(color: textSecondary),
          labelStyle: const TextStyle(color: textPrimary),
          prefixIconColor: textSecondary,
          suffixIconColor: orangePrimary,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: blackSurface,
          selectedColor: orangePrimary,
          labelStyle: const TextStyle(color: textPrimary),
          secondaryLabelStyle: const TextStyle(color: Colors.black),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: const BorderSide(color: Color(0xFF404040)),
          ),
        ),
        cardTheme: CardThemeData(
          color: blackSurface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: blackSurface,
          titleTextStyle: const TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          contentTextStyle: const TextStyle(
            color: textSecondary,
            fontSize: 14,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: orangePrimary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const AuthGatePage(),
      onGenerateRoute: (settings) {
        return MaterialPageRoute(builder: (_) => const AuthGatePage());
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (_) => const AuthGatePage());
      },
    );
  }
}