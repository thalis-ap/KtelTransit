import 'dart:io';
import 'package:flutter/material.dart';

class ConnectionService extends ChangeNotifier {
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

  bool _isConnected = true;

  bool get isConnected => _isConnected;

  /// Check connectivity and update state
  Future<void> checkConnection() async {
    final previous = _isConnected;
    _isConnected = await _checkInternet();
    if (previous != _isConnected) {
      notifyListeners();
    }
  }

  static Future<bool> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  /// Start periodic checking (optional – call this once)
  void startMonitoring({Duration interval = const Duration(seconds: 10)}) {
    checkConnection();
    Future.doWhile(() async {
      await Future.delayed(interval);
      await checkConnection();
      return true;
    });
  }
}