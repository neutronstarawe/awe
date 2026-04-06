import 'package:flutter/material.dart';
import '../core/app_preferences.dart';
import 'gallery_screen.dart';
import 'experience_screen.dart';

class HubScreen extends StatelessWidget {
  final AppPreferences preferences;

  const HubScreen({
    super.key,
    required this.preferences,
  });

  // Update these lists as you add images to the corresponding asset folders.
  static const _intricatePaths = <String>[
    // Add paths here as you drop images into assets/images/intricate/
    // e.g. 'assets/images/intricate/01.jpg',
  ];

  static const _majesticPaths = <String>[
    // Add paths here as you drop images into assets/images/majestic/
    // e.g. 'assets/images/majestic/01.jpg',
  ];

  static const _cosmicPaths = <String>[
    'assets/images/cosmic/01.jpg',
    'assets/images/cosmic/02.jpg',
    'assets/images/cosmic/03.jpg',
    'assets/images/cosmic/04.jpg',
    'assets/images/cosmic/05.jpg',
    'assets/images/cosmic/06.jpg',
    'assets/images/cosmic/07.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  // Left: title
                  SizedBox(
                    width: 140,
                    child: Center(
                      child: Text(
                        'awe',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 28,
                          fontWeight: FontWeight.w100,
                          letterSpacing: 10,
                        ),
                      ),
                    ),
                  ),
                  // Divider
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 24),
                    color: Colors.white10,
                  ),
                  // Right: 4 tiles
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          _HubTile(
                            label: 'Intricate',
                            sublabel: 'The Small',
                            icon: Icons.biotech,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const GalleryScreen(
                                  title: 'Intricate',
                                  imagePaths: _intricatePaths,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _HubTile(
                            label: 'Majestic',
                            sublabel: 'The Grand',
                            icon: Icons.landscape,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const GalleryScreen(
                                  title: 'Majestic',
                                  imagePaths: _majesticPaths,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _HubTile(
                            label: 'Cosmic',
                            sublabel: 'The Infinite',
                            icon: Icons.stars,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const GalleryScreen(
                                  title: 'Cosmic',
                                  imagePaths: _cosmicPaths,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _HubTile(
                            label: 'Stars\nSimulation',
                            sublabel: 'Coming Soon',
                            icon: Icons.scatter_plot,
                            onTap: null,
                            muted: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // "Relive the Experience" button below tiles
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExperienceScreen(preferences: preferences),
                  ),
                ),
                child: Text(
                  'Relive the Experience',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 13,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final VoidCallback? onTap;
  final bool muted;

  const _HubTile({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.onTap,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: muted ? 0.4 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white38, size: 32),
                const SizedBox(height: 14),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w300,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  sublabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
