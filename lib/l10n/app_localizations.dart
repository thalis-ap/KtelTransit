import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_el.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('el'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In el, this message translates to:
  /// **'Τοπικά ΚΤΕΛ'**
  String get appTitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In el, this message translates to:
  /// **'Καλώς ήλθατε!'**
  String get welcomeTitle;

  /// No description provided for @welcomeDescription.
  ///
  /// In el, this message translates to:
  /// **'Εδώ θα βρείτε όλα τα τοπικά δρομολόγια ΚΤΕΛ και αστικών λεωφορείων για κάθε περιοχή της Ελλάδας.'**
  String get welcomeDescription;

  /// No description provided for @readyToStart.
  ///
  /// In el, this message translates to:
  /// **'Ξεκινάμε;'**
  String get readyToStart;

  /// No description provided for @selectRegionHint.
  ///
  /// In el, this message translates to:
  /// **'Επίλεξε την περιοχή που σε ενδιαφέρει. Μπορείς να την αλλάξεις ανά πάσα στιγμή από το αριστερό μενού της αρχικής σελίδας.'**
  String get selectRegionHint;

  /// No description provided for @notChosen.
  ///
  /// In el, this message translates to:
  /// **'Δεν έχει επιλεγεί'**
  String get notChosen;

  /// No description provided for @letGoButton.
  ///
  /// In el, this message translates to:
  /// **'Φύγαμε'**
  String get letGoButton;

  /// No description provided for @regionRequiredError.
  ///
  /// In el, this message translates to:
  /// **'Πρέπει να επιλέξεις μια περιοχή για να συνεχίσεις!'**
  String get regionRequiredError;

  /// No description provided for @searchDestinationHint.
  ///
  /// In el, this message translates to:
  /// **'Αναζήτηση προορισμού...'**
  String get searchDestinationHint;

  /// No description provided for @selectStartHint.
  ///
  /// In el, this message translates to:
  /// **'Επιλέξτε αφετηρία...'**
  String get selectStartHint;

  /// No description provided for @selectDestinationHint.
  ///
  /// In el, this message translates to:
  /// **'Επιλέξτε προορισμό...'**
  String get selectDestinationHint;

  /// No description provided for @swapDirectionTooltip.
  ///
  /// In el, this message translates to:
  /// **'Αλλαγή κατεύθυνσης'**
  String get swapDirectionTooltip;

  /// No description provided for @resetOrientationTooltip.
  ///
  /// In el, this message translates to:
  /// **'Επαναφορά προσανατολισμού'**
  String get resetOrientationTooltip;

  /// No description provided for @originLabel.
  ///
  /// In el, this message translates to:
  /// **'Αφετηρία'**
  String get originLabel;

  /// No description provided for @destinationLabel.
  ///
  /// In el, this message translates to:
  /// **'Προορισμός'**
  String get destinationLabel;

  /// No description provided for @upcomingDeparturesToday.
  ///
  /// In el, this message translates to:
  /// **'ΕΠΕΡΧΟΜΕΝΕΣ ΑΝΑΧΩΡΗΣΕΙΣ ΣΗΜΕΡΑ'**
  String get upcomingDeparturesToday;

  /// No description provided for @departuresOnDay.
  ///
  /// In el, this message translates to:
  /// **'ΑΝΑΧΩΡΗΣΕΙΣ {day}'**
  String departuresOnDay(String day);

  /// No description provided for @tomorrow.
  ///
  /// In el, this message translates to:
  /// **'ΑΥΡΙΟ'**
  String get tomorrow;

  /// No description provided for @noDeparturesToday.
  ///
  /// In el, this message translates to:
  /// **'Δεν υπάρχουν αναχωρήσεις σήμερα'**
  String get noDeparturesToday;

  /// No description provided for @noScheduledDepartures.
  ///
  /// In el, this message translates to:
  /// **'Δεν υπάρχουν προγραμματισμένες αναχωρήσεις'**
  String get noScheduledDepartures;

  /// No description provided for @settingsTitle.
  ///
  /// In el, this message translates to:
  /// **'Ρυθμίσεις'**
  String get settingsTitle;

  /// No description provided for @appearanceSection.
  ///
  /// In el, this message translates to:
  /// **'ΕΜΦΑΝΙΣΗ'**
  String get appearanceSection;

  /// No description provided for @systemDefaultTheme.
  ///
  /// In el, this message translates to:
  /// **'Προεπιλογή συστήματος'**
  String get systemDefaultTheme;

  /// No description provided for @lightTheme.
  ///
  /// In el, this message translates to:
  /// **'Φωτεινό'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In el, this message translates to:
  /// **'Σκοτεινό'**
  String get darkTheme;

  /// No description provided for @languageSection.
  ///
  /// In el, this message translates to:
  /// **'ΓΛΩΣΣΑ / LANGUAGE'**
  String get languageSection;

  /// No description provided for @exitDialogTitle.
  ///
  /// In el, this message translates to:
  /// **'Έξοδος'**
  String get exitDialogTitle;

  /// No description provided for @exitDialogMessage.
  ///
  /// In el, this message translates to:
  /// **'Θέλετε σίγουρα να κλείσετε την εφαρμογή;'**
  String get exitDialogMessage;

  /// No description provided for @cancel.
  ///
  /// In el, this message translates to:
  /// **'Ακύρωση'**
  String get cancel;

  /// No description provided for @exit.
  ///
  /// In el, this message translates to:
  /// **'Έξοδος'**
  String get exit;

  /// No description provided for @regionPrefix.
  ///
  /// In el, this message translates to:
  /// **'Περιοχή: '**
  String get regionPrefix;

  /// No description provided for @tapToChange.
  ///
  /// In el, this message translates to:
  /// **'Πατήστε για αλλαγή'**
  String get tapToChange;

  /// No description provided for @region.
  ///
  /// In el, this message translates to:
  /// **'Περιοχή'**
  String get region;

  /// No description provided for @routes.
  ///
  /// In el, this message translates to:
  /// **'Δρομολόγια'**
  String get routes;

  /// No description provided for @info.
  ///
  /// In el, this message translates to:
  /// **'Πληροφορίες'**
  String get info;

  /// No description provided for @tickets.
  ///
  /// In el, this message translates to:
  /// **'Εισιτήρια'**
  String get tickets;

  /// No description provided for @allTrips.
  ///
  /// In el, this message translates to:
  /// **'Όλα τα δρομολόγια'**
  String get allTrips;

  /// No description provided for @today.
  ///
  /// In el, this message translates to:
  /// **'Σήμερα'**
  String get today;

  /// No description provided for @noTripsForDateShowingNext.
  ///
  /// In el, this message translates to:
  /// **'Δεν βρέθηκαν δρομολόγια λεωφορείων για την επιλεγμένη ημερομηνία. Εμφάνιση επόμενων διαθέσιμων.'**
  String get noTripsForDateShowingNext;

  /// No description provided for @tripsForDate.
  ///
  /// In el, this message translates to:
  /// **'Δρομολόγια για: {date}'**
  String tripsForDate(String date);

  /// No description provided for @departed.
  ///
  /// In el, this message translates to:
  /// **'Αναχώρησε'**
  String get departed;

  /// No description provided for @noTripsForRoute.
  ///
  /// In el, this message translates to:
  /// **'Δεν βρέθηκαν δρομολόγια για αυτή τη διαδρομή.'**
  String get noTripsForRoute;

  /// No description provided for @noBusTripsForRoute.
  ///
  /// In el, this message translates to:
  /// **'Δεν βρέθηκαν δρομολόγια λεωφορείων για αυτή τη διαδρομή.'**
  String get noBusTripsForRoute;

  /// No description provided for @costBreakdown.
  ///
  /// In el, this message translates to:
  /// **'Ανάλυση κόστους'**
  String get costBreakdown;

  /// No description provided for @totalTicketCost.
  ///
  /// In el, this message translates to:
  /// **'Συνολικό κόστος εισιτηρίων'**
  String get totalTicketCost;

  /// No description provided for @transfer.
  ///
  /// In el, this message translates to:
  /// **'ΜΕΤΕΠΙΒΙΒΑΣΗ'**
  String get transfer;

  /// No description provided for @departureFrom.
  ///
  /// In el, this message translates to:
  /// **'Αναχώρηση από {stop}:'**
  String departureFrom(String stop);

  /// No description provided for @arrivalAt.
  ///
  /// In el, this message translates to:
  /// **'Εκτιμώμενη άφιξη σε {stop}:'**
  String arrivalAt(String stop);

  /// No description provided for @estimatedArrivalAt.
  ///
  /// In el, this message translates to:
  /// **'Εκτιμώμενη άφιξη σε {stop}:'**
  String estimatedArrivalAt(String stop);

  /// No description provided for @waitingTime.
  ///
  /// In el, this message translates to:
  /// **'Αναμονή: {time}'**
  String waitingTime(String time);

  /// No description provided for @hoursMinutesFormat.
  ///
  /// In el, this message translates to:
  /// **'{hours}ω {minutes}λ'**
  String hoursMinutesFormat(int hours, int minutes);

  /// No description provided for @minutesFormat.
  ///
  /// In el, this message translates to:
  /// **'{minutes}λ'**
  String minutesFormat(int minutes);

  /// No description provided for @departureLabel.
  ///
  /// In el, this message translates to:
  /// **'Αναχώρηση: {time}'**
  String departureLabel(String time);

  /// No description provided for @changeButton.
  ///
  /// In el, this message translates to:
  /// **'ΑΛΛΑΓΗ'**
  String get changeButton;

  /// No description provided for @daily.
  ///
  /// In el, this message translates to:
  /// **'Καθημερινά'**
  String get daily;

  /// No description provided for @unknownDays.
  ///
  /// In el, this message translates to:
  /// **'Άγνωστες ημέρες'**
  String get unknownDays;

  /// No description provided for @searchRegionHint.
  ///
  /// In el, this message translates to:
  /// **'Αναζήτηση περιοχής...'**
  String get searchRegionHint;

  /// No description provided for @noRegionFound.
  ///
  /// In el, this message translates to:
  /// **'Δεν βρέθηκε περιοχή.'**
  String get noRegionFound;

  /// No description provided for @searchStopHint.
  ///
  /// In el, this message translates to:
  /// **'Αναζήτηση στάσης...'**
  String get searchStopHint;

  /// No description provided for @noStopFound.
  ///
  /// In el, this message translates to:
  /// **'Δεν βρέθηκε στάση.'**
  String get noStopFound;

  /// No description provided for @durationHoursMinutes.
  ///
  /// In el, this message translates to:
  /// **'{hours} ώρ. {minutes} λεπ.'**
  String durationHoursMinutes(int hours, String minutes);

  /// No description provided for @durationHours.
  ///
  /// In el, this message translates to:
  /// **'{count, plural, =1{1 ώρα} other{{count} ώρες}}'**
  String durationHours(int count);

  /// No description provided for @durationMinutes.
  ///
  /// In el, this message translates to:
  /// **'{count, plural, =1{1 λεπτό} other{{count} λεπτά}}'**
  String durationMinutes(int count);

  /// No description provided for @outbound.
  ///
  /// In el, this message translates to:
  /// **'Μετάβαση'**
  String get outbound;

  /// No description provided for @returnTrip.
  ///
  /// In el, this message translates to:
  /// **'Επιστροφή'**
  String get returnTrip;

  /// No description provided for @loadingStops.
  ///
  /// In el, this message translates to:
  /// **'Φόρτωση στάσεων...'**
  String get loadingStops;

  /// No description provided for @locationDisabledTitle.
  ///
  /// In el, this message translates to:
  /// **'Τοποθεσία ανενεργή'**
  String get locationDisabledTitle;

  /// No description provided for @locationDisabledMessage.
  ///
  /// In el, this message translates to:
  /// **'Παρακαλώ ενεργοποιήστε την τοποθεσία στη συσκευή σας για να δείτε τη θέση σας.'**
  String get locationDisabledMessage;

  /// No description provided for @locationDeniedTitle.
  ///
  /// In el, this message translates to:
  /// **'Δεν υπάρχει πρόσβαση'**
  String get locationDeniedTitle;

  /// No description provided for @locationDeniedMessage.
  ///
  /// In el, this message translates to:
  /// **'Η άδεια τοποθεσίας έχει απορριφθεί. Ανοίξτε τις ρυθμίσεις της εφαρμογής για να την ενεργοποιήσετε.'**
  String get locationDeniedMessage;

  /// No description provided for @settingsButton.
  ///
  /// In el, this message translates to:
  /// **'Ρυθμίσεις'**
  String get settingsButton;

  /// No description provided for @maxWaitTime.
  ///
  /// In el, this message translates to:
  /// **'Μέγιστη αναμονή μετεπιβίβασης'**
  String get maxWaitTime;

  /// No description provided for @timeBasedTheme.
  ///
  /// In el, this message translates to:
  /// **'Βάσει ώρας (Ημέρα/Νύχτα)'**
  String get timeBasedTheme;

  /// No description provided for @chosenPoint.
  ///
  /// In el, this message translates to:
  /// **'Επιλεγμένο σημείο'**
  String get chosenPoint;

  /// No description provided for @searchingPoint.
  ///
  /// In el, this message translates to:
  /// **'Αναζήτηση σημείου...'**
  String get searchingPoint;

  /// No description provided for @nearestStops.
  ///
  /// In el, this message translates to:
  /// **'Πλησιέστερες στάσεις'**
  String get nearestStops;

  /// No description provided for @calibrateCompassTitle.
  ///
  /// In el, this message translates to:
  /// **'Βαθμονόμηση Πυξίδας'**
  String get calibrateCompassTitle;

  /// No description provided for @calibrateCompassDescription.
  ///
  /// In el, this message translates to:
  /// **'Η πυξίδα της συσκευής σας είναι αυτή τη στιγμή αναξιόπιστη.\n\nΓια να βεβαιωθείτε ότι ο χάρτης δείχνει προς τη σωστή κατεύθυνση, κινήστε το τηλέφωνό σας στον αέρα σχηματίζοντας τον αριθμό \'8\' μερικές φορές.'**
  String get calibrateCompassDescription;

  /// No description provided for @gotItLabel.
  ///
  /// In el, this message translates to:
  /// **'Το κατάλαβα'**
  String get gotItLabel;

  /// No description provided for @routeErrorTitle.
  ///
  /// In el, this message translates to:
  /// **'Σφάλμα Διαδρομής'**
  String get routeErrorTitle;

  /// No description provided for @routeErrorMessage.
  ///
  /// In el, this message translates to:
  /// **'Δεν ήταν δυνατός ο υπολογισμός της διαδρομής πεζών προς τη στάση {stopName}. Παρακαλώ ελέγξτε τη σύνδεση σας και δοκιμάστε ξανά.'**
  String routeErrorMessage(String stopName);

  /// No description provided for @retryButton.
  ///
  /// In el, this message translates to:
  /// **'Δοκιμή ξανά'**
  String get retryButton;

  /// No description provided for @walking.
  ///
  /// In el, this message translates to:
  /// **'Περπάτημα'**
  String get walking;

  /// No description provided for @walkFrom.
  ///
  /// In el, this message translates to:
  /// **'Περπάτημα από'**
  String get walkFrom;

  /// No description provided for @walkTo.
  ///
  /// In el, this message translates to:
  /// **'Περπάτημα προς'**
  String get walkTo;

  /// No description provided for @walk.
  ///
  /// In el, this message translates to:
  /// **'Περπατήστε'**
  String get walk;

  /// No description provided for @to.
  ///
  /// In el, this message translates to:
  /// **'προς'**
  String get to;

  /// No description provided for @pastTrips.
  ///
  /// In el, this message translates to:
  /// **'Δρομολόγια που αναχώρησαν'**
  String get pastTrips;

  /// No description provided for @availableRoutes.
  ///
  /// In el, this message translates to:
  /// **'Διαθέσιμα δρομολόγια'**
  String get availableRoutes;

  /// No description provided for @metersFormat.
  ///
  /// In el, this message translates to:
  /// **'{meters} μ'**
  String metersFormat(int meters);

  /// No description provided for @kilometersFormat.
  ///
  /// In el, this message translates to:
  /// **'{km} χλμ'**
  String kilometersFormat(String km);

  /// No description provided for @disembarkAt.
  ///
  /// In el, this message translates to:
  /// **'Αποβίβαση: {stop}'**
  String disembarkAt(String stop);

  /// No description provided for @tripStopsCount.
  ///
  /// In el, this message translates to:
  /// **'Διαδρομή: {count} στάσεις'**
  String tripStopsCount(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['el', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'el':
      return AppLocalizationsEl();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
