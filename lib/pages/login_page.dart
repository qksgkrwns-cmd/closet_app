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
  bool _submitted = false;

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
    setState(() => _submitted = true);
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
    final hasEmailError = _submitted &&
        (_emailController.text.trim().isEmpty || !_emailController.text.contains('@'));

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35)),
                ),
                child: Icon(
                  Icons.checkroom,
                  size: 34,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Closet App',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                '이메일 링크로 빠르게 로그인하고 옷장과 데일리룩을 바로 관리하세요.',
                style: TextStyle(color: Colors.grey.shade400, height: 1.4),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onChanged: (_) {
                  if (_submitted) setState(() {});
                },
                onSubmitted: (_) {
                  if (!_isLoading) _sendMagicLink();
                },
                decoration: const InputDecoration(
                  labelText: '이메일',
                  hintText: 'name@example.com',
                ),
              ),
              if (hasEmailError)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '올바른 이메일을 입력해주세요.',
                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                ),
                child: Row(
                  children: [
                    Icon(Icons.mark_email_read_outlined, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '비밀번호 없이 메일 링크로 로그인됩니다.',
                        style: TextStyle(color: Colors.grey.shade300),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(24, 8, 24, 12),
        child: FilledButton(
          onPressed: _isLoading ? null : _sendMagicLink,
          child: _isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('로그인 링크 받기'),
        ),
      ),
    );
  }
}
