import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

/// The phone's hardware step counter (needs the "Physical activity"
/// permission on Android 10+). Readings never leave the phone.
class StepCounter {
  Future<bool> granted() async => (await Permission.activityRecognition.status).isGranted;

  Future<bool> request() async => (await Permission.activityRecognition.request()).isGranted;

  /// Steps since the phone booted; errors when the phone has no step sensor.
  Stream<int> readings() => Pedometer.stepCountStream.map((e) => e.steps);
}
