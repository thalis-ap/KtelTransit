import 'package:flutter/material.dart';

import '../../services/ui/sheet_manager_service.dart';


class BottomSheetWrapper extends StatelessWidget {
  /// Fires whenever the internal ScrollController is created / rebuilt.
  /// Use this to capture the controller that DraggableScrollableSheet
  /// creates internally so the parent can scroll it programmatically when
  /// we need to restore a scroll position
  final ValueChanged<ScrollController>? onScrollControllerCreated;

  final DraggableScrollableController controller;
  final VoidCallback onClose;

  /// Title area (e.g. Text, or a Row with a back button)
  final Widget title;

  /// Widgets to the right of the title, before the close button
  final List<Widget> titleTrailing;

  /// Full-width widgets under the title row
  final List<Widget> underTitle;

  /// Scrollable body
  final Widget child;

  /// Enables drag-from-header resize (previous trip_info_sheet behavior)
  final bool dragHandleEnabled;

  final double initialSize, minSize, maxSize;
  final List<double> snapSizes;

  const BottomSheetWrapper({
    super.key,
    required this.controller,
    required this.onClose,
    required this.title,
    required this.child,
    this.onScrollControllerCreated,
    this.titleTrailing = const [],
    this.underTitle = const [],
    this.dragHandleEnabled = true,
    this.initialSize = SheetSizes.middle,
    this.minSize = SheetSizes.low,
    this.maxSize = SheetSizes.high,
    this.snapSizes = const [SheetSizes.middle],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: DraggableScrollableSheet(
        controller: controller,
        initialChildSize: initialSize,
        minChildSize: minSize,
        maxChildSize: maxSize,
        snap: true,
        snapSizes: snapSizes,
        shouldCloseOnMinExtent: false,
        builder: (context, scrollController) {
          onScrollControllerCreated?.call(scrollController);
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: const [BoxShadow(blurRadius: 16, spreadRadius: 2)],
            ),
            child: Column(
              children: [
                // Stationary header (drag handle + title + close)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: dragHandleEnabled
                      ? (d) => _onDragUpdate(d, screenHeight)
                      : null,
                  onVerticalDragEnd: dragHandleEnabled
                      ? (d) => _onDragEnd(d, screenHeight)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 12, left: 24, right: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(child: _handle(colorScheme)),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: title,
                                  ),
                                  ...titleTrailing,
                                ],
                              ),
                            ),
                            _closeButton(context),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (underTitle.isNotEmpty) ...[
                          ...underTitle,
                          const SizedBox(height: 12),
                        ]

                      ],
                    ),
                  ),
                ),

                // Scrollable body
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: child,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _handle(ColorScheme cs) => Container(
    width: 48,
    height: 5,
    decoration: BoxDecoration(
      color: cs.onSurfaceVariant.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(3),
    ),
  );

  Widget _closeButton(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: cs.onSurfaceVariant.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(Icons.close, size: 22, color: cs.onSurfaceVariant),
        onPressed: onClose,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  // Drag helpers to make title (stationary) widgets draggable
  void _onDragUpdate(DragUpdateDetails details, double availableHeight) {
    if (!controller.isAttached) return;
    final delta = (details.primaryDelta ?? 0) / availableHeight;
    final newSize = (controller.size - delta).clamp(minSize, maxSize);
    controller.jumpTo(newSize);
  }

  void _onDragEnd(DragEndDetails details, double availableHeight) {
    if (!controller.isAttached) return;
    final currentSize = controller.size;
    final velocity = details.velocity.pixelsPerSecond.dy / availableHeight;

    double target;
    if (velocity.abs() > 1.0) {
      target = velocity < 0
          ? _snapPoints.firstWhere(
            (s) => s > currentSize + 0.01,
        orElse: () => maxSize,
      )
          : _snapPoints.lastWhere(
            (s) => s < currentSize - 0.01,
        orElse: () => minSize,
      );
    } else {
      target = _snapPoints.reduce(
            (a, b) => (a - currentSize).abs() < (b - currentSize).abs() ? a : b,
      );
    }

    controller.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  /// Includes min/max so we always have valid targets
  List<double> get _snapPoints =>
      ({minSize, maxSize, ...snapSizes}.toList()..sort());
}