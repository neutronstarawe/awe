import 'package:flutter/material.dart';
import '../core/audio_engine.dart';
import '../core/app_preferences.dart';
import 'micro_awe_screen.dart';
import 'cosmic_awe_screen.dart';
import 'power_of_nature_screen.dart';
import 'splash_screen.dart';

class HubScreen extends StatelessWidget {
  final AudioEngine audioEngine;
  final AppPreferences preferences;

  const HubScreen({
    super.key,
    required this.audioEngine,
    required this.preferences,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'awe',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w100,
                  letterSpacing: 12,
                ),
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(16),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _HubTile(
                    label: 'Micro Awe',
                    icon: Icons.biotech,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MicroAweScreen(
                          audioEngine: audioEngine,
                        ),
                      ),
                    ),
                  ),
                  _HubTile(
                    label: 'Cosmic Awe',
                    icon: Icons.stars,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CosmicAweScreen(
                          audioEngine: audioEngine,
                        ),
                      ),
                    ),
                  ),
                  _HubTile(
                    label: 'Power of Nature',
                    icon: Icons.landscape,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PowerOfNatureScreen(
                          audioEngine: audioEngine,
                        ),
                      ),
                    ),
                  ),
                  _HubTile(
                    label: 'Reset',
                    icon: Icons.refresh,
                    onTap: () => _reset(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reset(BuildContext context) async {
    await preferences.setHasSeenIntro(false);
    await preferences.setMontageIndex(0);
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SplashScreen(
          audioEngine: audioEngine,
          preferences: preferences,
        ),
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _HubTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white60, size: 40),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
