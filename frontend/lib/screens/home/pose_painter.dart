import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// CustomPainter для отрисовки скелета поверх камеры
class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;
  final InputImageRotation rotation;
  final bool isFrontCamera;

  PosePainter({
    required this.poses,
    required this.imageSize,
    required this.rotation,
    this.isFrontCamera = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = const Color(0xFF00FF88);

    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF00FF88);

    final redDotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.redAccent;

    // Соединения для отрисовки скелета
    final connections = <List<PoseLandmarkType>>[
      // Торс
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      // Левая рука
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
      [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
      // Правая рука
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
      [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
      // Левая нога
      [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
      [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
      // Правая нога
      [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
      [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
    ];

    // Ключевые точки для выделения (суставы, которые участвуют в подсчёте)
    final keyJoints = <PoseLandmarkType>{
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
    };

    for (final pose in poses) {
      // Рисуем соединения
      for (final connection in connections) {
        final from = pose.landmarks[connection[0]];
        final to = pose.landmarks[connection[1]];
        if (from != null && to != null) {
          canvas.drawLine(
            _translatePoint(from, size),
            _translatePoint(to, size),
            paint,
          );
        }
      }

      // Рисуем точки
      for (final landmark in pose.landmarks.values) {
        final point = _translatePoint(landmark, size);
        final isKey = keyJoints.contains(landmark.type);
        canvas.drawCircle(point, isKey ? 8 : 5, isKey ? redDotPaint : dotPaint);
      }
    }
  }

  Offset _translatePoint(PoseLandmark landmark, Size canvasSize) {
    // Масштабируем координаты из размера изображения в размер канваса
    double x = landmark.x;
    double y = landmark.y;

    // Масштаб
    final scaleX = canvasSize.width / imageSize.width;
    final scaleY = canvasSize.height / imageSize.height;

    // Для фронтальной камеры зеркалим по X
    if (isFrontCamera) {
      x = imageSize.width - x;
    }

    return Offset(x * scaleX, y * scaleY);
  }

  @override
  bool shouldRepaint(PosePainter oldDelegate) => true;
}
