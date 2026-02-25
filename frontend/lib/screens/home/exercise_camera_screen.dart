import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/pose_detection_service.dart';
import '../../l10n/app_localizations.dart';
import 'pose_painter.dart';

/// Экран камеры для AI-трекинга упражнений.
///
/// Отображает превью камеры, рисует скелет, считает повторения.
class ExerciseCameraScreen extends StatefulWidget {
  final ExerciseType exerciseType;
  final int currentCount;

  const ExerciseCameraScreen({
    super.key,
    required this.exerciseType,
    this.currentCount = 0,
  });

  @override
  State<ExerciseCameraScreen> createState() => _ExerciseCameraScreenState();
}

class _ExerciseCameraScreenState extends State<ExerciseCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _isFrontCamera = true;

  final PoseDetectionService _poseService = PoseDetectionService();
  List<Pose> _poses = [];
  bool _isProcessing = false;
  bool _isInitialized = false;
  bool _permissionDenied = false;

  int _repCount = 0;
  double _currentAngle = 0;
  bool _isTracking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _poseService.setExerciseType(widget.exerciseType);
    _poseService.onRepCounted = (count) {
      if (mounted) {
        setState(() => _repCount = count);
        // Вибрация при каждом повторении
        HapticFeedback.mediumImpact();
      }
    };
    _poseService.onAngleUpdated = (angle) {
      if (mounted) {
        setState(() => _currentAngle = angle);
      }
    };
    _initCamera();
  }

  Future<void> _initCamera() async {
    // Запрашиваем разрешение на камеру
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _permissionDenied = true);
      return;
    }

    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    // Ищем фронтальную камеру
    _cameraIndex = _cameras.indexWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
    );
    if (_cameraIndex == -1) {
      _cameraIndex = 0;
      _isFrontCamera = false;
    }

    await _startCamera(_cameraIndex);
  }

  Future<void> _startCamera(int index) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    _cameraController = CameraController(
      _cameras[index],
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
        _cameraController!.startImageStream(_processImage);
      }
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  void _processImage(CameraImage image) {
    if (_isProcessing || !_isTracking) return;
    _isProcessing = true;

    final inputImage = _convertCameraImage(image);
    if (inputImage == null) {
      _isProcessing = false;
      return;
    }

    _poseService.processImage(inputImage).then((poses) {
      if (mounted) {
        setState(() => _poses = poses);
      }
      _isProcessing = false;
    }).catchError((e) {
      _isProcessing = false;
    });
  }

  InputImage? _convertCameraImage(CameraImage image) {
    final camera = _cameras[_cameraIndex];

    final rotation = InputImageRotationValue.fromRawValue(
      camera.sensorOrientation,
    );
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    // По спецификации ML Kit нужен только первый plane для NV21 / BGRA
    if (image.planes.isEmpty) return null;

    return InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  void _toggleCamera() async {
    if (_cameras.length < 2) return;

    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    _isFrontCamera = _cameras[_cameraIndex].lensDirection == CameraLensDirection.front;

    setState(() => _isInitialized = false);
    await _startCamera(_cameraIndex);
  }

  void _toggleTracking() {
    setState(() => _isTracking = !_isTracking);
  }

  void _resetCount() {
    setState(() {
      _repCount = 0;
      _poseService.reset();
    });
  }

  Future<void> _saveAndExit() async {
    if (_repCount == 0) {
      Navigator.of(context).pop();
      return;
    }

    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.user;
    if (currentUser == null) {
      Navigator.of(context).pop();
      return;
    }

    try {
      if (widget.exerciseType == ExerciseType.pushUps) {
        final newValue = currentUser.pushUps + _repCount;
        await userProvider.updateProgress(pushUps: newValue);
      } else {
        final newValue = currentUser.squats + _repCount;
        await userProvider.updateProgress(squats: newValue);
      }

      if (mounted) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('+$_repCount ${loc.translate('saved')}!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _startCamera(_cameraIndex);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _poseService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final accentColor = Theme.of(context).colorScheme.primary;
    final exerciseName = widget.exerciseType == ExerciseType.pushUps
        ? loc.translate('push_ups')
        : loc.translate('squats');

    if (_permissionDenied) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt, size: 80, color: Colors.white54),
                const SizedBox(height: 24),
                Text(
                  loc.translate('camera_permission_needed'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => openAppSettings(),
                  child: Text(loc.translate('open_settings')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized || _cameraController == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: accentColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Камера
          CameraPreview(_cameraController!),

          // Скелет
          if (_poses.isNotEmpty && _cameraController!.value.isInitialized)
            CustomPaint(
              painter: PosePainter(
                poses: _poses,
                imageSize: Size(
                  _cameraController!.value.previewSize!.height,
                  _cameraController!.value.previewSize!.width,
                ),
                rotation: InputImageRotation.rotation0deg,
                isFrontCamera: _isFrontCamera,
              ),
            ),

          // Верхняя панель
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Кнопка закрытия
                _buildCircleButton(
                  Icons.close,
                  () => Navigator.pop(context),
                ),
                // Название упражнения
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.smart_toy, color: accentColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'AI $exerciseName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Переключение камеры
                _buildCircleButton(
                  Icons.cameraswitch,
                  _cameras.length > 1 ? _toggleCamera : null,
                ),
              ],
            ),
          ),

          // Счётчик повторений — крупный по центру
          Positioned(
            bottom: 180,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: accentColor.withOpacity(0.5), width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_repCount',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      loc.translate('reps'),
                      style: TextStyle(
                        color: accentColor.withOpacity(0.8),
                        fontSize: 16,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Нижняя панель с кнопками
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Сброс
                _buildActionButton(
                  Icons.refresh,
                  loc.translate('reset'),
                  _resetCount,
                  Colors.orangeAccent,
                ),
                // Пауза / Продолжить
                _buildActionButton(
                  _isTracking ? Icons.pause : Icons.play_arrow,
                  _isTracking ? loc.translate('pause') : loc.translate('resume'),
                  _toggleTracking,
                  Colors.white,
                ),
                // Сохранить
                _buildActionButton(
                  Icons.check,
                  loc.translate('save'),
                  _saveAndExit,
                  accentColor,
                ),
              ],
            ),
          ),

          // Статус трекинга
          if (!_isTracking)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    loc.translate('paused'),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black54,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onTap,
    Color color,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
