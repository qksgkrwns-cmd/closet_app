import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../services/similarity_service.dart';
import '../widgets/profile_card.dart';

class SimilarUsersPage extends StatefulWidget {
  const SimilarUsersPage({super.key});

  @override
  State<SimilarUsersPage> createState() => _SimilarUsersPageState();
}

class _SimilarUsersPageState extends State<SimilarUsersPage> {
  late Future<List<Map<String, dynamic>>> similarUsersFuture;

  @override
  void initState() {
    super.initState();
    _loadSimilarUsers();
  }

  Future<void> _loadSimilarUsers() async {
    final currentProfile = await ProfileService.getCurrentProfile();
    if (currentProfile != null) {
      similarUsersFuture = SimilarityService.findSimilarUsers(currentProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('나와 비슷한 사람')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: similarUsersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('비슷한 사람이 없습니다.'));
          }
          final similarUsers = snapshot.data!;
          return ListView.builder(
            itemCount: similarUsers.length,
            itemBuilder: (context, index) {
              final userMap = similarUsers[index];
              final profile = userMap['profile'];
              final score = userMap['similarity_score'] as double;
              return ProfileCard(profile: profile, similarityScore: score);
            },
          );
        },
      ),
    );
  }
}