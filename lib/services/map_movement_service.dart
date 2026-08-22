import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

/// Handles map movement, rotation, and animation.
class MapMovementService {
  final MapController mapController;
  final TickerProvider vsync;

  // Rotation state
  double _mapRotation = 0.0;
  double get mapRotation => _mapRotation;
  set mapRotation(double value) {
    _mapRotation = value;
    mapController.rotate(value * 180 / math.pi);
  }

  // Animation controller for rotation
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;
  bool _isAnimating = false;

  MapMovementService({
    required this.mapController,
    required this.vsync,
  }) {
    _rotationController = AnimationController(vsync: vsync);
    _rotationAnimation = const AlwaysStoppedAnimation(0);
    _rotationController.addListener(_onRotationAnimationTick);
  }

  void _onRotationAnimationTick() {
    mapRotation = _rotationAnimation.value;
  }

  /// Moves the map to a new location with a smooth animation.
  void animatedMove(LatLng destLocation, double destZoom, {Duration duration = const Duration(milliseconds: 500)}) {
    final latTween = Tween<double>(
      begin: mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: mapController.camera.zoom,
      end: destZoom,
    );

    final animationController = AnimationController(
      duration: duration,
      vsync: vsync,
    );

    final Animation<double> animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.fastOutSlowIn,
    );

    animationController.addListener(() {
      mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        animationController.dispose();
      }
    });

    animationController.forward();
  }

  /// Resets the map rotation to north (0 degrees) with a smooth animation.
  void resetRotation({double minDuration = 150, double maxDuration = 1000}) {
    if (_isAnimating) {
      _rotationController.stop();
    }

    final currentDegrees = mapRotation.abs() * 180 / math.pi;
    const degreesPerSecond = 360.0;
    final durationMs = (currentDegrees / degreesPerSecond * 1000)
        .clamp(minDuration, maxDuration)
        .round();

    _rotationController.duration = Duration(milliseconds: durationMs);
    _rotationAnimation = Tween<double>(
      begin: mapRotation,
      end: 0.0,
    ).animate(_rotationController);

    _isAnimating = true;
    _rotationController.forward(from: 0).then((_) {
      _isAnimating = false;
    });
  }

  /// Updates the map rotation to a specific value (in radians).
  void setRotation(double radians) {
    if (!_isAnimating) {
      mapRotation = radians;
    }
  }

  /// Disposes the animation controller.
  void dispose() {
    _rotationController.dispose();
  }
}