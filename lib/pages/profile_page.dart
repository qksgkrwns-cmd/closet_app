import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../models/profile.dart';
import '../widgets/app_network_image.dart';
import '../widgets/empty_state_view.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Profile?> profileFuture;

  @override
  void initState() {
    super.initState();
    profileFuture = ProfileService.getCurrentProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('프로필')),
      body: FutureBuilder<Profile?>(
        future: profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const EmptyStateView(
              icon: Icons.person_outline,
              title: '프로필 정보가 없습니다.',
              subtitle: '프로필 설정에서 정보를 입력해 주세요.',
            );
          }
          final profile = snapshot.data!;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: ClipOval(
                      child: AppNetworkImage(
                        imageUrl: profile.avatarUrl,
                        fit: BoxFit.cover,
                        fallbackIcon: Icons.person,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.username,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('성별: ${profile.gender}'),
                          const SizedBox(height: 8),
                          Text('체형: ${profile.bodyType}'),
                          const SizedBox(height: 8),
                          Text('키: ${profile.height}cm'),
                          const SizedBox(height: 8),
                          Text('몸무게: ${profile.weight}kg'),
                          const SizedBox(height: 8),
                          Text('피부톤: ${profile.skinTone}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('선호 스타일', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: profile.stylePreferences
                        .map((style) => Chip(label: Text(style)))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/profile_setup');
                    },
                    child: const Text('프로필 수정'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}