import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}

const List<Achievement> kAchievements = [
  Achievement(
    id: 'first_clear',
    title: 'First Clear',
    description: 'Cleared your first row or column',
    icon: Icons.cleaning_services,
  ),
  Achievement(
    id: 'combo_3',
    title: 'Triple Combo',
    description: 'Made an x3 combo',
    icon: Icons.local_fire_department,
  ),
  Achievement(
    id: 'combo_5',
    title: 'On Fire',
    description: 'Made an x5 combo',
    icon: Icons.whatshot,
  ),
  Achievement(
    id: 'score_1000',
    title: 'Thousand',
    description: 'Scored over 1000 points',
    icon: Icons.emoji_events,
  ),
  Achievement(
    id: 'score_5000',
    title: 'Five Thousand',
    description: 'Scored over 5000 points',
    icon: Icons.military_tech,
  ),
  Achievement(
    id: 'score_10000',
    title: 'Ten Thousand',
    description: 'Scored over 10000 points',
    icon: Icons.workspace_premium,
  ),
  Achievement(
    id: 'cleared_50',
    title: 'Cleaner',
    description: 'Cleared 50 rows/columns total',
    icon: Icons.auto_awesome,
  ),
  Achievement(
    id: 'games_10',
    title: 'Persistent',
    description: 'Played 10 games',
    icon: Icons.psychology,
  ),
];
