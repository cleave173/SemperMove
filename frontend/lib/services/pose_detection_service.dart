import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Тип упражнения для AI-трекинга
enum ExerciseType { pushUps, squats }

/// Фаза движения
enum _MovementPhase { up, down }

/// Сервис для анализа поз и подсчёта упражнений.
///
/// Использует Google ML Kit Pose Detection для определения 33 точек тела.
/// Для каждого упражнения отслеживает углы в ключевых суставах:
/// - Отжимания: угол в локте (плечо → локоть → запястье)
/// - Приседания: угол в колене (бедро → колено → лодыжка)
class PoseDetectionService {
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base,
    ),
  );

  ExerciseType _exerciseType = ExerciseType.pushUps;
  _MovementPhase _phase = _MovementPhase.up;
  int _repCount = 0;

  /// Callback вызывается при каждом новом повторении
  void Function(int count)? onRepCounted;

  /// Callback вызывается при обновлении угла (для отладки/UI)
  void Function(double angle)? onAngleUpdated;

  int get repCount => _repCount;
  ExerciseType get exerciseType => _exerciseType;

  void setExerciseType(ExerciseType type) {
    _exerciseType = type;
    reset();
  }

  void reset() {
    _repCount = 0;
    _phase = _MovementPhase.up;
  }

  /// Обработать кадр из камеры
  Future<List<Pose>> processImage(InputImage inputImage) async {
    final poses = await _poseDetector.processImage(inputImage);

    if (poses.isNotEmpty) {
      _analyzePose(poses.first);
    }

    return poses;
  }

  /// Анализ позы и подсчёт повторений
  void _analyzePose(Pose pose) {
    double? angle;

    switch (_exerciseType) {
      case ExerciseType.pushUps:
        angle = _analyzePushUp(pose);
        break;
      case ExerciseType.squats:
        angle = _analyzeSquat(pose);
        break;
    }

    if (angle != null) {
      onAngleUpdated?.call(angle);
    }
  }

  /// Анализ отжиманий по углу в локте
  double? _analyzePushUp(Pose pose) {
    // Берём точки — пробуем левую сторону, если не видна — правую
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];

    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    double? angle;

    // Используем сторону с наибольшим likelihood
    if (leftElbow != null && leftShoulder != null && leftWrist != null &&
        rightElbow != null && rightShoulder != null && rightWrist != null) {
      final leftLikelihood = (leftElbow.likelihood + leftShoulder.likelihood + leftWrist.likelihood) / 3;
      final rightLikelihood = (rightElbow.likelihood + rightShoulder.likelihood + rightWrist.likelihood) / 3;

      if (leftLikelihood >= rightLikelihood) {
        angle = _calculateAngle(leftShoulder, leftElbow, leftWrist);
      } else {
        angle = _calculateAngle(rightShoulder, rightElbow, rightWrist);
      }
    } else if (leftElbow != null && leftShoulder != null && leftWrist != null) {
      angle = _calculateAngle(leftShoulder, leftElbow, leftWrist);
    } else if (rightElbow != null && rightShoulder != null && rightWrist != null) {
      angle = _calculateAngle(rightShoulder, rightElbow, rightWrist);
    }

    if (angle == null) return null;

    // Логика подсчёта: вверх (>150°) → вниз (<90°) → вверх = 1 повторение
    if (_phase == _MovementPhase.up && angle < 90) {
      _phase = _MovementPhase.down;
    } else if (_phase == _MovementPhase.down && angle > 150) {
      _phase = _MovementPhase.up;
      _repCount++;
      onRepCounted?.call(_repCount);
    }

    return angle;
  }

  /// Анализ приседаний по углу в колене
  double? _analyzeSquat(Pose pose) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];

    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    double? angle;

    if (leftKnee != null && leftHip != null && leftAnkle != null &&
        rightKnee != null && rightHip != null && rightAnkle != null) {
      final leftLikelihood = (leftKnee.likelihood + leftHip.likelihood + leftAnkle.likelihood) / 3;
      final rightLikelihood = (rightKnee.likelihood + rightHip.likelihood + rightAnkle.likelihood) / 3;

      if (leftLikelihood >= rightLikelihood) {
        angle = _calculateAngle(leftHip, leftKnee, leftAnkle);
      } else {
        angle = _calculateAngle(rightHip, rightKnee, rightAnkle);
      }
    } else if (leftKnee != null && leftHip != null && leftAnkle != null) {
      angle = _calculateAngle(leftHip, leftKnee, leftAnkle);
    } else if (rightKnee != null && rightHip != null && rightAnkle != null) {
      angle = _calculateAngle(rightHip, rightKnee, rightAnkle);
    }

    if (angle == null) return null;

    // Логика подсчёта: стоя (>160°) → присед (<90°) → стоя = 1 повторение
    if (_phase == _MovementPhase.up && angle < 90) {
      _phase = _MovementPhase.down;
    } else if (_phase == _MovementPhase.down && angle > 160) {
      _phase = _MovementPhase.up;
      _repCount++;
      onRepCounted?.call(_repCount);
    }

    return angle;
  }

  /// Вычисляет угол между тремя точками (в градусах)
  /// point1 — первая точка, vertex — вершина угла, point3 — третья точка
  double _calculateAngle(PoseLandmark point1, PoseLandmark vertex, PoseLandmark point3) {
    final radians = atan2(point3.y - vertex.y, point3.x - vertex.x) -
        atan2(point1.y - vertex.y, point1.x - vertex.x);

    var angle = radians * 180.0 / pi;

    if (angle < 0) angle += 360;
    if (angle > 180) angle = 360 - angle;

    return angle;
  }

  /// Освобождение ресурсов
  Future<void> dispose() async {
    await _poseDetector.close();
  }
}
