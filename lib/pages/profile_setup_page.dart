import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../services/profile_service.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  String selectedBodyType = '직사각형';
  String selectedSkinTone = '중간색';
  List<String> selectedStyles = [];
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final usernameController = TextEditingController();
  bool isLoading = false;

  final bodyTypes = ['마름모', '직사각형', '모래시계', '역삼각형', '삼각형'];
  final skinTones = ['밝은색', '중간색', '어두운색'];
  final styles = ['캐주얼', '시크', '스포츠', '우아함', '펑키', '미니멀'];

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      usernameController.text = user.email?.split('@')[0] ?? 'user';
    }
  }

  Future<void> saveProfile() async {
    if (usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 이름을 입력해주세요.')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final profile = Profile(
        id: user.id,
        username: usernameController.text,
        bodyType: selectedBodyType,
        height: int.tryParse(heightController.text),
        weight: int.tryParse(weightController.text),
        skinTone: selectedSkinTone,
        stylePreferences: selectedStyles,
        createdAt: DateTime.now(),
      );

      await ProfileService.saveProfile(profile);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      print(e);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    heightController.dispose();
    weightController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('프로필 설정')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: '사용자 이름'),
              ),
              const SizedBox(height: 20),
              const Text('체형', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: bodyTypes.map((type) => ChoiceChip(
                  label: Text(type),
                  selected: selectedBodyType == type,
                  onSelected: (_) => setState(() => selectedBodyType = type),
                )).toList(),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '키 (cm)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '몸무게 (kg)'),
              ),
              const SizedBox(height: 20),
              const Text('피부톤', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: skinTones.map((tone) => ChoiceChip(
                  label: Text(tone),
                  selected: selectedSkinTone == tone,
                  onSelected: (_) => setState(() => selectedSkinTone = tone),
                )).toList(),
              ),
              const SizedBox(height: 20),
              const Text('스타일', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: styles.map((style) => FilterChip(
                  label: Text(style),
                  selected: selectedStyles.contains(style),
                  onSelected: (selected) => setState(() {
                    if (selected) selectedStyles.add(style);
                    else selectedStyles.remove(style);
                  }),
                )).toList(),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading ? null : saveProfile,
                child: isLoading ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ) : const Text('저장'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}