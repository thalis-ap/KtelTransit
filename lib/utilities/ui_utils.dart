import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../widgets/common/custom_snackbar.dart';

class SnackbarUtils {
  static void showUnknownError(BuildContext context) {
    CustomSnackBar.show(
      context,
      message: AppLocalizations.of(context)!.unknownError,
      color: Theme.of(context).colorScheme.error,
    );
  }

  static void showInternetAvailable(BuildContext context) {
    CustomSnackBar.show(
      context,
      message: AppLocalizations.of(context)!.internetConnection,
      color: Theme.of(context).colorScheme.secondary,
    );
  }

  static void showNoInternet(BuildContext context) {
    CustomSnackBar.show(
      context,
      message: AppLocalizations.of(context)!.noInternetConnection,
      color: Theme.of(context).colorScheme.error,
    );
  }
}
