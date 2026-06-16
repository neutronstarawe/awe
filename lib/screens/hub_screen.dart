import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_preferences.dart';
import 'gallery_screen.dart';
import 'experience_screen.dart';
import '../stars/star_catalog.dart';
import '../stars/sky_orientation.dart';
import 'stars_screen.dart';
import 'features_screen.dart';

class HubScreen extends StatefulWidget {
  final AppPreferences preferences;

  const HubScreen({super.key, required this.preferences});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  final _pageCtrl = PageController();
  static const _intricatePaths = <String>[
    'assets/images/intricate/01.jpg',
    'assets/images/intricate/02.jpeg',
    'assets/images/intricate/03.jpg',
    'assets/images/intricate/04.jpg',
    'assets/images/intricate/05.jpg',
    'assets/images/intricate/06.jpg',
    'assets/images/intricate/07.webp',
  ];

  static const _majesticPaths = <String>[
    'assets/images/majestic/01.jpg',
    'assets/images/majestic/02.jpg',
    'assets/images/majestic/03.webp',
    'assets/images/majestic/04.jpg',
    'assets/images/majestic/05.jpg',
    'assets/images/majestic/06.jpg',
    'assets/images/majestic/07.jpeg',
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
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([]);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _openGallery(BuildContext context, String title, List<String> paths) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GalleryScreen(title: title, imagePaths: paths),
      ),
    );
  }

  Future<void> _openStars(BuildContext context) async {
    final catalog = await StarCatalog.load(DefaultAssetBundle.of(context));
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StarsScreen(
          catalog: catalog,
          orientationSource: RealSkyOrientationSource(),
        ),
      ),
    );
  }

  Widget _reliveButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExperienceScreen(preferences: widget.preferences),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            'Relive the Experience',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
              letterSpacing: 2,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageCtrl,
      children: [
        Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: OrientationBuilder(
              builder: (context, orientation) {
                if (orientation == Orientation.landscape) {
                  return _buildLandscape(context);
                }
                return _buildPortrait(context);
              },
            ),
          ),
        ),
        const FeaturesScreen(),
      ],
    );
  }

  Widget _buildLandscape(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                          child: _HubTile(
                        label: 'Intricate',
                        sublabel: 'The Small',
                        icon: Icons.biotech,
                        onTap: () => _openGallery(
                            context, 'Intricate', _intricatePaths),
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _HubTile(
                        label: 'Majestic',
                        sublabel: 'The Grand',
                        icon: Icons.landscape,
                        onTap: () =>
                            _openGallery(context, 'Majestic', _majesticPaths),
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _HubTile(
                        label: 'Cosmic',
                        sublabel: 'The Infinite',
                        icon: Icons.stars,
                        onTap: () =>
                            _openGallery(context, 'Cosmic', _cosmicPaths),
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _HubTile(
                        label: 'Stars\nSimulation',
                        sublabel: 'The Sky',
                        icon: Icons.scatter_plot,
                        onTap: () => _openStars(context),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        _reliveButton(context),
      ],
    );
  }

  Widget _buildPortrait(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 12),
          child: Text(
            'awe',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 32,
              fontWeight: FontWeight.w100,
              letterSpacing: 12,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                          child: _HubTile(
                        label: 'Intricate',
                        sublabel: 'The Small',
                        icon: Icons.biotech,
                        onTap: () => _openGallery(
                            context, 'Intricate', _intricatePaths),
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _HubTile(
                        label: 'Majestic',
                        sublabel: 'The Grand',
                        icon: Icons.landscape,
                        onTap: () =>
                            _openGallery(context, 'Majestic', _majesticPaths),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                          child: _HubTile(
                        label: 'Cosmic',
                        sublabel: 'The Infinite',
                        icon: Icons.stars,
                        onTap: () =>
                            _openGallery(context, 'Cosmic', _cosmicPaths),
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _HubTile(
                        label: 'Stars\nSimulation',
                        sublabel: 'The Sky',
                        icon: Icons.scatter_plot,
                        onTap: () => _openStars(context),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _reliveButton(context),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chevron_right,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.15)),
              Text(
                'swipe for more',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.15),
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HubTile extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final VoidCallback? onTap;
  const _HubTile({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
    );
  }
}
