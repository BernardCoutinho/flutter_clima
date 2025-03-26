import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';

class OrientationService {
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  Stream<bool> get pointingUpStream => _controller.stream;
  late StreamSubscription<AccelerometerEvent> _subscription;

  void start() {
    _subscription = accelerometerEvents.listen((event) {
      // Calcula o ângulo de inclinação em relação ao eixo Z
      double zAngle = math.atan2(event.z, math.sqrt(event.x * event.x + event.y * event.y)) * (180 / math.pi);

      // Define um intervalo de ângulo para considerar que o dispositivo está apontando para cima
      final isUp = zAngle < -30; // Ajuste este valor conforme necessário

      _controller.add(isUp);
    });
  }

  void dispose() {
    _subscription.cancel();
    _controller.close();
  }
}
