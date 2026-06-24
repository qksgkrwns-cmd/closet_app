import 'package:flutter/material.dart';
import '../models/profile.dart';

class ProfileCard extends StatelessWidget {
  final Profile profile;
  final double similarityScore;

  const ProfileCard({
    super.key,
    required this.profile,
    required this.similarityScore,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: profile.avatarUrl != null
                      ? NetworkImage(profile.avatarUrl!)
                      : null,
                  child: profile.avatarUrl == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.username, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('${profile.bodyType} | ${profile.height}cm'),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text('${(similarityScore * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                    const Text('일치도'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 4,
              children: profile.stylePreferences
                  .map((style) => Chip(
                        label: Text(style),
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}