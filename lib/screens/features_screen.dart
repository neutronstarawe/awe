import 'package:flutter/material.dart';
import '../core/ambient_audio_service.dart';
import '../core/circadian_service.dart';
import 'journal_screen.dart';

class FeaturesScreen extends StatefulWidget {
  const FeaturesScreen({super.key});

  @override
  State<FeaturesScreen> createState() => _FeaturesScreenState();
}

class _FeaturesScreenState extends State<FeaturesScreen> {
  final _audio = AmbientAudioService();
  final _circadian = CircadianService();

  bool _circadianEnabled = false;
  String? _sunriseLabel;
  String? _sunsetLabel;
  bool _circadianLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCircadian();
  }

  Future<void> _loadCircadian() async {
    final enabled = await _circadian.isEnabled;
    setState(() => _circadianEnabled = enabled);
    if (enabled) _refreshTimes();
  }

  Future<void> _refreshTimes() async {
    final times = await _circadian.todayTimes();
    if (!mounted) return;
    setState(() {
      _sunriseLabel = times?.sunrise != null ? _fmt(times!.sunrise!) : null;
      _sunsetLabel = times?.sunset != null ? _fmt(times!.sunset!) : null;
    });
  }

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _toggleCircadian(bool val) async {
    setState(() => _circadianLoading = true);
    if (val) {
      final granted = await _circadian.requestPermission();
      if (!granted) {
        if (mounted) setState(() => _circadianLoading = false);
        return;
      }
    }
    await _circadian.setEnabled(val);
    if (!mounted) return;
    setState(() {
      _circadianEnabled = val;
      _circadianLoading = false;
    });
    if (val) _refreshTimes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Row(
                children: [
                  Icon(Icons.chevron_left,
                      color: Colors.white.withValues(alpha: 0.3), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'swipe to return',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.2),
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _sectionHeader('Ambient Sound'),
                  const SizedBox(height: 12),
                  _AmbientPanel(service: _audio),
                  const SizedBox(height: 32),
                  _sectionHeader('Circadian Clock'),
                  const SizedBox(height: 12),
                  _CircadianPanel(
                    enabled: _circadianEnabled,
                    loading: _circadianLoading,
                    sunriseLabel: _sunriseLabel,
                    sunsetLabel: _sunsetLabel,
                    onToggle: _toggleCircadian,
                    onTest: () async {
                      final ok = await _circadian.testNotification();
                      if (!ok && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Notification permission denied — enable it in Settings.',
                              style: TextStyle(fontWeight: FontWeight.w300),
                            ),
                            backgroundColor: Colors.white12,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                  _sectionHeader('Journal'),
                  const SizedBox(height: 12),
                  _JournalTile(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String label) => Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 10,
          letterSpacing: 3,
          fontWeight: FontWeight.w400,
        ),
      );
}

// ── Ambient Sound Panel ───────────────────────────────────────────────────────

class _AmbientPanel extends StatefulWidget {
  final AmbientAudioService service;
  const _AmbientPanel({required this.service});

  @override
  State<_AmbientPanel> createState() => _AmbientPanelState();
}

class _AmbientPanelState extends State<_AmbientPanel> {
  AmbientSound _selected = AmbientSound.none;
  double _volume = 0.5;

  @override
  void initState() {
    super.initState();
    _selected = widget.service.current;
    _volume = widget.service.volume;
  }

  Future<void> _select(AmbientSound s) async {
    if (_selected == s) {
      await widget.service.stop();
      setState(() => _selected = AmbientSound.none);
    } else {
      await widget.service.play(s);
      setState(() => _selected = s);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AmbientSound.values
                .where((s) => s != AmbientSound.none)
                .map((s) => _SoundChip(
                      label: s.label,
                      active: _selected == s,
                      onTap: () => _select(s),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.volume_down,
                  size: 16, color: Colors.white.withValues(alpha: 0.3)),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.white38,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: Colors.white54,
                    overlayColor: Colors.white10,
                    trackHeight: 1.5,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: _volume,
                    onChanged: (v) {
                      setState(() => _volume = v);
                      widget.service.setVolume(v);
                    },
                  ),
                ),
              ),
              Icon(Icons.volume_up,
                  size: 16, color: Colors.white.withValues(alpha: 0.3)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SoundChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SoundChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: active ? 0.3 : 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: active ? 0.85 : 0.4),
            fontSize: 13,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }
}

// ── Circadian Clock Panel ─────────────────────────────────────────────────────

class _CircadianPanel extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final String? sunriseLabel;
  final String? sunsetLabel;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTest;

  const _CircadianPanel({
    required this.enabled,
    required this.loading,
    required this.sunriseLabel,
    required this.sunsetLabel,
    required this.onToggle,
    required this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Sunset & Sunrise Reminders',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: Colors.white38),
                )
              else
                Switch(
                  value: enabled,
                  onChanged: onToggle,
                  activeThumbColor: Colors.white60,
                  activeTrackColor: Colors.white24,
                  inactiveThumbColor: Colors.white30,
                  inactiveTrackColor: Colors.white10,
                ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 12),
            if (sunriseLabel != null || sunsetLabel != null)
              Row(
                children: [
                  if (sunriseLabel != null)
                    _TimeChip(
                        icon: Icons.wb_sunny_outlined, label: sunriseLabel!),
                  if (sunriseLabel != null && sunsetLabel != null)
                    const SizedBox(width: 12),
                  if (sunsetLabel != null)
                    _TimeChip(
                        icon: Icons.nights_stay_outlined, label: sunsetLabel!),
                ],
              ),
            if (sunriseLabel != null || sunsetLabel != null)
              const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '60 min before sunset · 8 PM sunrise preview',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.25),
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                ),
                GestureDetector(
                  onTap: onTest,
                  child: Text(
                    'Test',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 11,
                      letterSpacing: 1.5,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TimeChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white30),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
}

// ── Journal Tile ──────────────────────────────────────────────────────────────

class _JournalTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const JournalScreen()),
      ),
      child: _card(
        child: Row(
          children: [
            Icon(Icons.edit_note,
                color: Colors.white.withValues(alpha: 0.4), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Your Reflections',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            Icon(Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.2), size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Shared card wrapper ───────────────────────────────────────────────────────

Widget _card({required Widget child}) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
