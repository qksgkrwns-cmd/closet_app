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
    const blackBg = Color(0xFF090909);
    const blackSurface = Color(0xFF141414);
    const blackSurfaceAlt = Color(0xFF1E1E1E);
    const blackBorder = Color(0xFF343434);
    const textPrimary = Color(0xFFFFFFFF);
    const textSecondary = Color(0xFFC4C4C4);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: blackBg,
        canvasColor: blackBg,
        primaryColor: orangePrimary,
        colorScheme: ColorScheme.dark(
          primary: orangePrimary,
          secondary: orangeLight,
          tertiary: orangeAccent,
          surface: blackSurface,
          surfaceContainerHighest: blackSurfaceAlt,
          outline: blackBorder,
          outlineVariant: blackBorder,
          error: const Color(0xFFE74C3C),
        ),
        splashColor: orangePrimary.withValues(alpha: 0.12),
        highlightColor: orangePrimary.withValues(alpha: 0.08),
        dividerTheme: const DividerThemeData(
          color: blackBorder,
          thickness: 1,
          space: 24,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
        listTileTheme: const ListTileThemeData(
          iconColor: textPrimary,
          textColor: textPrimary,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: blackSurface,
          foregroundColor: textPrimary,
          elevation: 1,
          scrolledUnderElevation: 4,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          titleTextStyle: const TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: blackSurface,
          selectedItemColor: orangePrimary,
          unselectedItemColor: textSecondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          elevation: 10,
          type: BottomNavigationBarType.fixed,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: orangePrimary,
            foregroundColor: Colors.black,
            elevation: 0,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: orangePrimary,
            side: const BorderSide(color: orangePrimary, width: 1.2),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: orangePrimary,
            foregroundColor: Colors.black,
            elevation: 1,
            shadowColor: orangePrimary.withValues(alpha: 0.25),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: orangePrimary,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: blackSurfaceAlt,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: blackBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: blackBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: orangePrimary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE74C3C)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 2),
          ),
          hintStyle: const TextStyle(color: textSecondary),
          labelStyle: const TextStyle(color: textPrimary),
          prefixIconColor: textSecondary,
          suffixIconColor: orangePrimary,
          floatingLabelStyle: const TextStyle(color: orangePrimary),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: blackSurfaceAlt,
          selectedColor: orangePrimary,
          labelStyle: const TextStyle(color: textPrimary),
          secondaryLabelStyle: const TextStyle(color: Colors.black),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: const BorderSide(color: blackBorder),
          ),
        ),
        cardTheme: CardThemeData(
          color: blackSurface,
          elevation: 0,
          margin: EdgeInsets.zero,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: blackBorder, width: 1),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: blackSurface,
          titleTextStyle: const TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
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
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: orangePrimary,
          unselectedLabelColor: textSecondary,
          indicatorColor: orangePrimary,
          dividerColor: blackBorder,
          labelStyle: TextStyle(fontWeight: FontWeight.w700),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: orangePrimary,
          linearTrackColor: blackBorder,
          circularTrackColor: blackBorder,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return orangePrimary;
            return const Color(0xFFBDBDBD);
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return orangePrimary.withValues(alpha: 0.35);
            return blackBorder;
          }),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return orangePrimary;
            return blackSurfaceAlt;
          }),
          side: const BorderSide(color: blackBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return orangePrimary;
            return textSecondary;
          }),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w800, letterSpacing: -0.4),
          headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w800, letterSpacing: -0.3),
          headlineSmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, letterSpacing: -0.2),
          titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, letterSpacing: -0.2),
          titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
          titleSmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: textPrimary, height: 1.35),
          bodyMedium: TextStyle(color: textPrimary, height: 1.35),
          bodySmall: TextStyle(color: textSecondary, height: 1.25),
          labelLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
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