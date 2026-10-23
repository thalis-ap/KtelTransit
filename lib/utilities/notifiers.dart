import 'package:flutter/cupertino.dart';

class CustomValueNotifier<T> extends ValueNotifier<T> {
  CustomValueNotifier(super._value);

  /// Forcefully call notifyListeners() in case the value was not changed
  /// and we need to rebuild (notify).
  void forceNotify() {
    notifyListeners();
  }
}
