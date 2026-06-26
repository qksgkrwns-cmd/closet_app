import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../services/profile_service.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  String selectedGender = '미설정';
  String selectedBodyType = '보통';
  String selectedSkinTone = '중간색';
  List<String> selectedStyles = [];
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final usernameController = TextEditingController();
  bool isLoading = false;

  final bodyTypes = ['마른', '보통', '통통', '상체발달', '하체발달', '근육'];
  final genders = ['남성', '여성'];
  final skinTones = ['밝은색', '중간색', '어두운색'];
  final styles = ['캐주얼', '시크', '스포츠', '우아함', '펑키', '미니멀'];

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      usernameController.text = user.email?.split('@')[0] ?? 'user';
    }
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final profile = await ProfileService.getCurrentProfile();
    if (!mounted || profile == null) return;

    setState(() {
      usernameController.text = profile.username;

      if (genders.contains(profile.gender)) {
        selectedGender = profile.gender;
      }

      if (bodyTypes.contains(profile.bodyType)) {
        selectedBodyType = profile.bodyType;
      }

      if (skinTones.contains(profile.skinTone)) {
        selectedSkinTone = profile.skinTone;
      }

      selectedStyles = profile.stylePreferences
          .where((style) => styles.contains(style))
          .toList();

      heightController.text = profile.height?.toString() ?? '';
      weightController.text = profile.weight?.toString() ?? '';
    });
  }

  Future<void> saveProfile() async {
    if (usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 이름을 입력해주세요.')),
      );
      return;
    }
    if (selectedGender == '미설정') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('성별을 선택해주세요.')),
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
        gender: selectedGender,
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
      debugPrint('Profile save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
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
              const Text('성별 (필수)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: genders.map((gender) => ChoiceChip(
                  label: Text(gender),
                  selected: selectedGender == gender,
                  onSelected: (_) => setState(() => selectedGender = gender),
                )).toList(),
              ),
              const SizedBox(height: 20),
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