import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import 'home_page.dart';
import 'login_page.dart';

class AuthGatePage extends StatefulWidget {
  const AuthGatePage({super.key});

  @override
  State<AuthGatePage> createState() => _AuthGatePageState();
}

class _AuthGatePageState extends State<AuthGatePage> {
  final _supabase = Supabase.instance.client;
  String? _lastUserId;

  Future<void> _ensureDefaultProfile(User user) async {
    if (_lastUserId == user.id) return;
    _lastUserId = user.id;

    try {
      await ProfileService.ensureDefaultProfile(user);
    } catch (_) {
      // Do not block app entry on profile bootstrap errors.
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // While waiting for the first auth event, check synchronously
        final session = snapshot.hasData
            ? snapshot.data!.session
            : _supabase.auth.currentSession;

        if (session != null) {
          final user = session.user;
          // Kick off profile creation after build to avoid build-phase state conflicts.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _ensureDefaultProfile(user);
          });

          return const HomePage();
        }

        return const LoginPage();
      },
    );
  }
}
