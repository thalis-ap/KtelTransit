import 'package:flutter/material.dart';

class CustomSnackBar {
  static void show(
      BuildContext context, {
        required String message,
        required Color color,
        Duration duration = const Duration(seconds: 3),
      }) {
    final overlay = Overlay.of(context);

    late OverlayEntry entry;

    final animationController = AnimationController(
      vsync: Navigator.of(context),
      duration: const Duration(milliseconds: 350),
      reverseDuration: const Duration(milliseconds: 250),
    );

    final animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: Material(
            color: Colors.transparent,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1.5),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(
                opacity: animation,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      // only exception with colors (not using colorScheme)
                      // since we don't know the bg color of the snackbar
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(entry);

    animationController.forward();

    Future.delayed(duration, () async {
      await animationController.reverse();
      entry.remove();
      animationController.dispose();
    });
  }
}
