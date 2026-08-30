// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Local KTEL';

  @override
  String get welcomeTitle => 'Welcome!';

  @override
  String get welcomeDescription =>
      'Here you will find all local KTEL and urban bus schedules for every region in Greece.';

  @override
  String get readyToStart => 'Ready?';

  @override
  String get selectRegionHint =>
      'Select your region of interest. You can change it anytime from the left side drawer menu.';

  @override
  String get notChosen => 'Not selected';

  @override
  String get letGoButton => 'Let\'s go';

  @override
  String get regionRequiredError => 'You must select a region to proceed!';

  @override
  String get searchDestinationHint => 'Search destination...';

  @override
  String get selectStartHint => 'Select origin...';

  @override
  String get selectDestinationHint => 'Select destination...';

  @override
  String get swapDirectionTooltip => 'Swap direction';

  @override
  String get resetOrientationTooltip => 'Reset orientation';

  @override
  String get originLabel => 'Origin';

  @override
  String get destinationLabel => 'Destination';

  @override
  String get upcomingDeparturesToday => 'UPCOMING DEPARTURES TODAY';

  @override
  String departuresOnDay(String day) {
    return 'DEPARTURES $day';
  }

  @override
  String get tomorrow => 'TOMORROW';

  @override
  String get noDeparturesToday => 'No departures scheduled today';

  @override
  String get noScheduledDepartures => 'No scheduled departures';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearanceSection => 'Appearance';

  @override
  String get systemDefaultTheme => 'System default';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get languageSection => 'Language / Γλώσσα';

  @override
  String get exitDialogTitle => 'Exit';

  @override
  String get exitDialogMessage => 'Are you sure you want to close the app?';

  @override
  String get cancel => 'Cancel';

  @override
  String get exit => 'Exit';

  @override
  String get regionPrefix => 'Region: ';

  @override
  String get tapToChange => 'Tap to change';

  @override
  String get region => 'Region';

  @override
  String get routes => 'Routes';

  @override
  String get info => 'Information';

  @override
  String get tickets => 'Tickets';

  @override
  String get allTrips => 'All trips';

  @override
  String get today => 'Today';

  @override
  String get noTripsForDateShowingNext =>
      'No bus departures found for the selected date. Showing next available.';

  @override
  String tripsForDate(String date) {
    return 'Departures for: $date';
  }

  @override
  String get departed => 'Departed';

  @override
  String get noTripsForRoute => 'No departures found for this route.';

  @override
  String get noBusTripsForRoute => 'No bus departures found for this route.';

  @override
  String get costBreakdown => 'Fare breakdown';

  @override
  String get totalTicketCost => 'Total ticket fare';

  @override
  String get transfer => 'TRANSFER';

  @override
  String departureFrom(String stop) {
    return 'Departure from $stop:';
  }

  @override
  String arrivalAt(String stop) {
    return 'Estimated arrival at $stop:';
  }

  @override
  String estimatedArrivalAt(String stop) {
    return 'Estimated arrival at $stop:';
  }

  @override
  String waitingTime(String time) {
    return 'Wait time: $time';
  }

  @override
  String hoursMinutesFormat(int hours, int minutes) {
    return '${hours}h ${minutes}min';
  }

  @override
  String minutesFormat(int minutes) {
    return '$minutes min';
  }

  @override
  String departureLabel(String time) {
    return 'Departure: $time';
  }

  @override
  String get changeButton => 'CHANGE';

  @override
  String get daily => 'Daily';

  @override
  String get unknownDays => 'Unknown days';

  @override
  String get searchRegionHint => 'Search region...';

  @override
  String get noRegionFound => 'No region found.';

  @override
  String get searchStopHint => 'Search stop...';

  @override
  String get noStopFound => 'No stop found.';

  @override
  String durationHoursMinutes(int hours, String minutes) {
    return '$hours hr $minutes min';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get outbound => 'Outbound';

  @override
  String get returnTrip => 'Return';

  @override
  String get loadingStops => 'Loading stops...';

  @override
  String get myLocation => 'My location';

  @override
  String get locationDisabledTitle => 'Location disabled';

  @override
  String get locationDisabledMessage =>
      'Please enable location services on your device to see your position.';

  @override
  String get locationDeniedTitle => 'Access denied';

  @override
  String get locationDeniedMessage =>
      'Location permission is denied. Please open app settings to enable it.';

  @override
  String get settingsButton => 'Settings';

  @override
  String get maxWaitTime => 'Max wait time';

  @override
  String get timeBasedTheme => 'Time-based (Day/Night)';

  @override
  String get chosenPoint => 'Dropped pin';

  @override
  String get searchingPoint => 'Searching point...';

  @override
  String get nearestStops => 'Nearest stops';

  @override
  String get calibrateCompassTitle => 'Calibrate Compass';

  @override
  String get calibrateCompassDescription =>
      'Your device\'s compass is currently unreliable.\n\nTo ensure the map points in the correct direction, please wave your phone in a large \'Figure 8\' motion a few times.';

  @override
  String get gotItLabel => 'Got it';

  @override
  String get routeErrorTitle => 'Route Error';

  @override
  String routeErrorMessage(String stopName) {
    return 'Could not calculate the walking route to $stopName. Please check your internet connection and try again.';
  }

  @override
  String get retryButton => 'Retry';

  @override
  String get walking => 'Walking';

  @override
  String get walkFrom => 'Walk from';

  @override
  String get walkTo => 'Walk to';

  @override
  String get walk => 'Walk';

  @override
  String get to => 'to';

  @override
  String get pastTrips => 'Past trips';

  @override
  String get availableRoutes => 'Available routes';

  @override
  String metersFormat(int meters) {
    return '$meters m';
  }

  @override
  String kilometersFormat(String km) {
    return '$km km';
  }

  @override
  String disembarkAt(String stop) {
    return 'Disembark at $stop';
  }

  @override
  String tripStopsCount(int count) {
    return 'Trip: $count stops';
  }

  @override
  String get noInternetConnection =>
      'No internet connection. Please check your network.';

  @override
  String get chooseInMap => 'Select on the map';

  @override
  String get chooseStartLocation => 'Choose start location';

  @override
  String get chooseDestinationLocation => 'Choose destination location';

  @override
  String get setLocation => 'Set location';

  @override
  String get routeFor => 'Route for';

  @override
  String get resetToNow => 'Reset to now';

  @override
  String get autoSelectBestRoute => 'Auto show best route based on';

  @override
  String get minTotalTime => 'Least total duration';

  @override
  String get minDepartTime => 'Earliest departure time';

  @override
  String get minArrivalTime => 'Earliest arrival time';

  @override
  String get off => 'Off';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortDirection => 'Sort direction';

  @override
  String get ascending => 'Ascending';

  @override
  String get descending => 'Descending';

  @override
  String get sortByTransfers => 'Number of transfers';

  @override
  String get sortByWalkingTime => 'Walking time';

  @override
  String get sortByCost => 'Cost';

  @override
  String get sortByTotalDuration => 'Total duration';

  @override
  String get sortByTripDuration => 'Trip duration (bus only)';

  @override
  String get sortByArrivalTime => 'Arrival time';

  @override
  String get sortByDepartureTime => 'Departure time';

  @override
  String get sortByWaitingTime => 'Waiting time';

  @override
  String get filters => 'Filters';

  @override
  String get includeWalking => 'No walking';

  @override
  String get includeDirectTripsOnly => 'Direct trips only';

  @override
  String get resetFilters => 'Reset filters';

  @override
  String get filtersActive => 'Filters active';

  @override
  String get apply => 'Apply';

  @override
  String get sort => 'Sort';

  @override
  String get filter => 'Filter';

  @override
  String get loadingMap => 'Loading the map...';

  @override
  String get loadingRoutes => 'Loading routes...';

  @override
  String get loadingMapRoute => 'Loading map route...';

  @override
  String get loadingPreciseLocation => 'Loading precise location...';
}
