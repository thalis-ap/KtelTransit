import 'package:flutter/material.dart';

/// Keys used to identify the different sheets.
class SheetKeys {
  static const String tripInfo = 'trip';
  static const String droppedPin = 'pin';
  static const String stop = 'stop';
}

class SheetSizes {
  static const double closed = 0.0;
  static const double low = 0.1;
  static const double middle = 0.45;
  static const double high = 0.85;
}

/// Manages the state, ordering, and animation of bottom sheets.
class SheetManagerService extends ChangeNotifier {
  // Controllers for each sheet
  final DraggableScrollableController tripInfoController = DraggableScrollableController();
  final DraggableScrollableController droppedPinController = DraggableScrollableController();
  final DraggableScrollableController stopController = DraggableScrollableController();

  // Stack order (last = top)
  final List<String> _stackOrder = [
    SheetKeys.tripInfo,
    SheetKeys.stop,
    SheetKeys.droppedPin,
  ];

  List<String> get stackOrder => _stackOrder;

  String? getTopmostOpenSheet() {
    for (final sheetName in stackOrder.reversed) {
      if (isSheetOpen(sheetName)) {
        return sheetName;
      }
    }
    return null;
  }


  /// Returns true if the specified sheet is currently visible (size > 0).
  bool isSheetOpen(String sheetName) {
    final controller = _getController(sheetName);
    return controller != null && controller.isAttached && controller.size > SheetSizes.closed;
  }

  /// Brings a sheet to the front of the stack (last in the list).
  void bringToFront(String sheetName) {
    if (_stackOrder.remove(sheetName)) {
      _stackOrder.add(sheetName);
      notifyListeners();
    }
  }

  /// Animate a specific sheet to a given size.
  Future<void> animateTo(String sheetName, double size, {Duration duration = const Duration(milliseconds: 300)}) {
    final controller = _getController(sheetName);
    if (controller == null || !controller.isAttached) return Future.value();

    // If it's the same value, just return to avoid unnecessary animation
    if (controller.size == size) return Future.value();

    return controller.animateTo(size, duration: duration, curve: Curves.easeOutCubic);
  }

  /// Convenience: Show a sheet (bring to front + animate to SheetSizes.middle).
  Future<void> showSheet(String sheetName, {double size = SheetSizes.middle}) {
    bringToFront(sheetName);
    return animateTo(sheetName, size);
  }

  /// Convenience: Close a specific sheet (animate to SheetSized.closed).
  Future<void> closeSheet(String sheetName) {
    return animateTo(sheetName, SheetSizes.closed);
  }

  /// Dismiss all sheets (animate all to SheetSizes.closed).
  Future<void> dismissAll() async {
    await Future.wait([
      animateTo(SheetKeys.tripInfo, SheetSizes.closed),
      animateTo(SheetKeys.droppedPin, SheetSizes.closed),
      animateTo(SheetKeys.stop, SheetSizes.closed),
    ]);
  }

  /// Get the controller for a specific sheet key.
  DraggableScrollableController? _getController(String sheetName) {
    switch (sheetName) {
      case SheetKeys.tripInfo:
        return tripInfoController;
      case SheetKeys.droppedPin:
        return droppedPinController;
      case SheetKeys.stop:
        return stopController;
      default:
        return null;
    }
  }

  @override
  void dispose() {
    tripInfoController.dispose();
    droppedPinController.dispose();
    stopController.dispose();
    super.dispose();
  }
}