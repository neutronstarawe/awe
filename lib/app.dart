import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/audio_engine.dart';
import 'core/app_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/hub_screen.dart';

class AweApp extends StatefulWidget {
  final AppPreferences? preferences;

  const AweApp({super.key, this.preferences});

  @override
  State<AweApp> createState() => _AweAppState();
}

class _AweAppState extends State<AweApp> {
  late final AudioEngine _audioEngine;
  late final AppPreferences _preferences;
  bool _initialized = false;
  bool _hasSeenIntro = false;

  @override
  void initState() {
    super.initState();
    _audioEngine = AudioEngine();
    _preferences = widget.preferences ?? AppPreferences();
    _init();
  }

  Future<void> _init() async {
    await _preferences.init();
    final seen = await _preferences.hasSeenIntro;
    setState(() {
      _hasSeenIntro = seen;
      _initialized = true;
    });
  }

  @override
  void dispose() {
    _audioEngine.disposeEngine();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return ChangeNotifierProvider<AudioEngine>.value(
      value: _audioEngine,
      child: MaterialApp(
        title: 'awe',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
        ),
        home: _hasSeenIntro
            ? HubScreen(
                audioEngine: _audioEngine,
                preferences: _preferences,
              )
            : SplashScreen(
                audioEngine: _audioEngine,
                preferences: _preferences,
              ),
      ),
    );
  }
}
