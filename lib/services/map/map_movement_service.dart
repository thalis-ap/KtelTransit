import 'dart:math';

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

  /// This function returns the target zoom needed to be able to fit both start
  /// and dest points in the map viewport. Adjust paddingFactor if needed to
  /// include padding when zooming. For example 75% percent padding means that
  /// the target zoom will be just enough to show the 2 points inside the
  /// 75% of the viewport's dimensions
  double getTargetZoom(LatLng start, LatLng dest, {double paddingFactor = 0.75}) {
    final MapCamera mapCamera = mapController.camera;

    double currentZoom = mapCamera.zoom;
    Rect bounds = mapCamera.pixelBounds;

    Offset startOffset = mapCamera.latLngToScreenOffset(start);
    Offset destOffset = mapCamera.latLngToScreenOffset(dest);

    // Current screen distance between the two points
    double requiredWidth = (startOffset.dx - destOffset.dx).abs();
    double requiredHeight = (startOffset.dy - destOffset.dy).abs();

    // Available viewport size
    double viewWidth = bounds.width;
    double viewHeight = bounds.height;

    double scaleX = requiredWidth / (viewWidth * paddingFactor);
    double scaleY = requiredHeight / (viewHeight * paddingFactor);

    // The larger scale factor determines the zoom change
    double maxScale = max(scaleX, scaleY);

    // Convert scale to zoom delta (assuming zoom doubles per step)
    double zoomDelta = log(maxScale) / ln2; // natural logarithm

    double targetZoom =
        currentZoom - zoomDelta; // zoom out if scale > 1, in if < 1

    return targetZoom;
  }

  /// Moves the map to a new location and zoom with a smooth animation.
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