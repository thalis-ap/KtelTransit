import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';

/// Handles compass events and exposes the current heading.
class CompassService extends ChangeNotifier {
  StreamSubscription<CompassEvent>? _subscription;
  double? _heading;
  bool _needsCalibration = false;
  bool _hasShownCalibrationDialog = false;

  /// Current device heading in degrees (0 = North, 90 = East, etc.)
  double? get heading => _heading;

  /// Whether the compass needs calibration (accuracy is unreliable).
  bool get needsCalibration => _needsCalibration;

  /// Whether the calibration dialog has already been shown this session.
  bool get hasShownCalibrationDialog => _hasShownCalibrationDialog;

  /// Starts listening to compass events.
  void startListening() {
    if (_subscription != null) return;

    _subscription = FlutterCompass.events?.listen((CompassEvent event) {
      bool shouldNotify = false;

      // Update heading
      if (event.heading != null && _heading != event.heading) {
        _heading = event.heading;
        shouldNotify = true;
      }

      // Check calibration status
      // 0.0 is Android's "Unreliable" status. < 0 is iOS's "Invalid" status.
      if (event.accuracy != null &&
          (event.accuracy == 0.0 || event.accuracy! < 0)) {
        if (!_needsCalibration) {
          _needsCalibration = true;
          shouldNotify = true;
        }
      } else {
        if (_needsCalibration) {
          _needsCalibration = false;
          shouldNotify = true;
        }
      }

      if (shouldNotify) {
        notifyListeners();
      }
    });
  }

  /// Stops listening to compass events.
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _heading = null;
    _needsCalibration = false;
    _hasShownCalibrationDialog = false;
    notifyListeners();
  }

  /// Marks the calibration dialog as shown.
  void markCalibrationDialogShown() {
    _hasShownCalibrationDialog = true;
    _needsCalibration = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}