import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

abstract class SensorService {
  Stream<GyroscopeEvent> get gyroscopeStream;
  void dispose();
}

class RealSensorService implements SensorService {
  StreamSubscription<GyroscopeEvent>? _subscription;

  @override
  Stream<GyroscopeEvent> get gyroscopeStream => gyroscopeEventStream();

  @override
  void dispose() {
    _subscription?.cancel();
  }
}

class FakeSensorService implements SensorService {
  final StreamController<GyroscopeEvent> _controller =
      StreamController<GyroscopeEvent>.broadcast();

  @override
  Stream<GyroscopeEvent> get gyroscopeStream => _controller.stream;

  void emit(double x, double y, double z) {
    _controller.add(GyroscopeEvent(x, y, z));
  }

  @override
  void dispose() {
    _controller.close();
  }
}
