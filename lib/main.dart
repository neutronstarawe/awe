import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/ambient_audio_service.dart';
import 'core/circadian_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await AmbientAudioService().init();
  await CircadianService().init();
  // Re-schedule circadian notifications if previously enabled.
  if (await CircadianService().isEnabled) {
    CircadianService().scheduleForNextDays();
  }
  runApp(const AweApp());
}
