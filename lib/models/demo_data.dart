import 'package:flutter/material.dart';
import '../app_colors.dart';

class DemoImages {
  static const himalayas =
      'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80';
  static const city =
      'https://images.unsplash.com/photo-1524492412937-b28074a5d7da?auto=format&fit=crop&w=1200&q=80';
  static const beach =
      'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80';
  static const forest =
      'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=1200&q=80';
  static const fort =
      'https://images.unsplash.com/photo-1599661046289-e31897846e41?auto=format&fit=crop&w=1200&q=80';
  static const food =
      'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1200&q=80';
}

final destinations = [
  {
    'name': 'Himalayan Aurora Trail',
    'place': 'Manali, Himachal Pradesh',
    'image': DemoImages.himalayas,
    'rating': '4.9',
    'price': 'INR 12,999',
    'tags': ['AI route', 'Snowline', '5 days'],
  },
  {
    'name': 'Hidden Fort Circuit',
    'place': 'Jaipur, Rajasthan',
    'image': DemoImages.fort,
    'rating': '4.8',
    'price': 'INR 8,450',
    'tags': ['Heritage', 'Night tour', 'Local guide'],
  },
  {
    'name': 'Midnight Beach Quest',
    'place': 'Gokarna, Karnataka',
    'image': DemoImages.beach,
    'rating': '4.7',
    'price': 'INR 6,900',
    'tags': ['Coastal', 'Stargaze', 'Food map'],
  },
];

final hiddenGems = [
  {
    'name': 'Yarada Beach',
    'type': 'Secluded coast',
    'distance': '15 km',
    'rating': '4.8',
    'image': DemoImages.beach,
    'desc': 'A quiet crescent beach wrapped by hills, ideal for sunset scouting.',
  },
  {
    'name': 'Borra Caves',
    'type': 'Limestone caves',
    'distance': '92 km',
    'rating': '4.9',
    'image': DemoImages.forest,
    'desc': 'Ancient caves with dramatic formations and an excellent audio story path.',
  },
  {
    'name': 'Bheemili Dutch Ruins',
    'type': 'Culture trail',
    'distance': '24 km',
    'rating': '4.6',
    'image': DemoImages.city,
    'desc': 'Weathered ruins, local cafes, and a sleepy coastline in one loop.',
  },
];

final moods = [
  {'label': 'Romantic', 'icon': Icons.favorite_rounded, 'color': const Color(0xFFFF6FAE)},
  {'label': 'Chill', 'icon': Icons.spa_rounded, 'color': AppColors.accent},
  {'label': 'Adventurous', 'icon': Icons.local_fire_department_rounded, 'color': AppColors.secondary},
  {'label': 'Rainy Day', 'icon': Icons.water_drop_rounded, 'color': const Color(0xFF70B7FF)},
  {'label': 'Comfort Food', 'icon': Icons.ramen_dining_rounded, 'color': AppColors.xpGold},
  {'label': 'Party Mood', 'icon': Icons.nightlife_rounded, 'color': const Color(0xFFC78BFF)},
];
