import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  String? get _mobileRedirectUrl {
    if (kIsWeb) return null;
    final configured = dotenv.env['SUPABASE_EMAIL_REDIRECT_TO']?.trim();
    if (configured == null || configured.isEmpty) return null;
    return configured;
  }

  bool _isRedirectConfigError(String message) {
    final text = message.toLowerCase();
    return text.contains('redirect') &&
        (text.contains('not allowed') ||
            text.contains('invalid') ||
            text.contains('whitelist') ||
            text.contains('configuration'));
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendMagicLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 이메일을 입력해주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final redirectTo = _mobileRedirectUrl;
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: redirectTo,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 링크를 이메일로 보냈습니다. 메일에서 링크를 누르면 앱으로 돌아옵니다.')),
      );
    } on AuthException catch (e) {
      debugPrint('[LOGIN] AuthException: statusCode=${e.statusCode} message=${e.message}');
      if (!mounted) return;

      // If redirect URL is not configured in Supabase, retry without redirect to avoid hard failure.
      if (!kIsWeb && _mobileRedirectUrl != null && _isRedirectConfigError(e.message)) {
        debugPrint('[LOGIN] Redirect error detected, retrying without redirectTo...');
        try {
          await Supabase.instance.client.auth.signInWithOtp(email: email);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('로그인 링크를 보냈습니다. Supabase Redirect URL 설정 후 앱 복귀 로그인이 동작합니다.'),
            ),
          );
          return;
        } on AuthException catch (retryError) {
          debugPrint('[LOGIN] Retry AuthException: statusCode=${retryError.statusCode} message=${retryError.message}');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('로그인 요청 실패: ${retryError.message}')),
          );
          return;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 요청 실패: ${e.message}')),
      );
    } catch (e) {
      debugPrint('[LOGIN] Unknown error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 요청 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Text(
                'Closet App',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                '이메일만 입력하고 바로 시작하세요',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendMagicLink,
                child: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('로그인 링크 받기'),
              ),
              const SizedBox(height: 10),
              const Text(
                '비밀번호 없이 메일 링크로 로그인됩니다.',
                textAlign: TextAlign.center,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
