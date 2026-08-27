// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class AppLocalizationsEl extends AppLocalizations {
  AppLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get appTitle => 'Τοπικά ΚΤΕΛ';

  @override
  String get welcomeTitle => 'Καλώς ήλθατε!';

  @override
  String get welcomeDescription =>
      'Εδώ θα βρείτε όλα τα τοπικά δρομολόγια ΚΤΕΛ και αστικών λεωφορείων για κάθε περιοχή της Ελλάδας.';

  @override
  String get readyToStart => 'Ξεκινάμε;';

  @override
  String get selectRegionHint =>
      'Επίλεξε την περιοχή που σε ενδιαφέρει. Μπορείς να την αλλάξεις ανά πάσα στιγμή από το αριστερό μενού της αρχικής σελίδας.';

  @override
  String get notChosen => 'Δεν έχει επιλεγεί';

  @override
  String get letGoButton => 'Φύγαμε';

  @override
  String get regionRequiredError =>
      'Πρέπει να επιλέξεις μια περιοχή για να συνεχίσεις!';

  @override
  String get searchDestinationHint => 'Αναζήτηση προορισμού...';

  @override
  String get selectStartHint => 'Επιλέξτε αφετηρία...';

  @override
  String get selectDestinationHint => 'Επιλέξτε προορισμό...';

  @override
  String get swapDirectionTooltip => 'Αλλαγή κατεύθυνσης';

  @override
  String get resetOrientationTooltip => 'Επαναφορά προσανατολισμού';

  @override
  String get originLabel => 'Αφετηρία';

  @override
  String get destinationLabel => 'Προορισμός';

  @override
  String get upcomingDeparturesToday => 'ΕΠΕΡΧΟΜΕΝΕΣ ΑΝΑΧΩΡΗΣΕΙΣ ΣΗΜΕΡΑ';

  @override
  String departuresOnDay(String day) {
    return 'ΑΝΑΧΩΡΗΣΕΙΣ $day';
  }

  @override
  String get tomorrow => 'ΑΥΡΙΟ';

  @override
  String get noDeparturesToday => 'Δεν υπάρχουν αναχωρήσεις σήμερα';

  @override
  String get noScheduledDepartures =>
      'Δεν υπάρχουν προγραμματισμένες αναχωρήσεις';

  @override
  String get settingsTitle => 'Ρυθμίσεις';

  @override
  String get appearanceSection => 'Εμφάνιση';

  @override
  String get systemDefaultTheme => 'Προεπιλογή συστήματος';

  @override
  String get lightTheme => 'Φωτεινό';

  @override
  String get darkTheme => 'Σκοτεινό';

  @override
  String get languageSection => 'Γλώσσα / Language';

  @override
  String get exitDialogTitle => 'Έξοδος';

  @override
  String get exitDialogMessage => 'Θέλετε σίγουρα να κλείσετε την εφαρμογή;';

  @override
  String get cancel => 'Ακύρωση';

  @override
  String get exit => 'Έξοδος';

  @override
  String get regionPrefix => 'Περιοχή: ';

  @override
  String get tapToChange => 'Πατήστε για αλλαγή';

  @override
  String get region => 'Περιοχή';

  @override
  String get routes => 'Δρομολόγια';

  @override
  String get info => 'Πληροφορίες';

  @override
  String get tickets => 'Εισιτήρια';

  @override
  String get allTrips => 'Όλα τα δρομολόγια';

  @override
  String get today => 'Σήμερα';

  @override
  String get noTripsForDateShowingNext =>
      'Δεν βρέθηκαν δρομολόγια λεωφορείων για την επιλεγμένη ημερομηνία. Εμφάνιση επόμενων διαθέσιμων.';

  @override
  String tripsForDate(String date) {
    return 'Δρομολόγια για: $date';
  }

  @override
  String get departed => 'Αναχώρησε';

  @override
  String get noTripsForRoute => 'Δεν βρέθηκαν δρομολόγια για αυτή τη διαδρομή.';

  @override
  String get noBusTripsForRoute =>
      'Δεν βρέθηκαν δρομολόγια λεωφορείων για αυτή τη διαδρομή.';

  @override
  String get costBreakdown => 'Ανάλυση κόστους';

  @override
  String get totalTicketCost => 'Συνολικό κόστος εισιτηρίων';

  @override
  String get transfer => 'ΜΕΤΕΠΙΒΙΒΑΣΗ';

  @override
  String departureFrom(String stop) {
    return 'Αναχώρηση από $stop:';
  }

  @override
  String arrivalAt(String stop) {
    return 'Εκτιμώμενη άφιξη σε $stop:';
  }

  @override
  String estimatedArrivalAt(String stop) {
    return 'Εκτιμώμενη άφιξη σε $stop:';
  }

  @override
  String waitingTime(String time) {
    return 'Αναμονή: $time';
  }

  @override
  String hoursMinutesFormat(int hours, int minutes) {
    return '$hoursω $minutesλ';
  }

  @override
  String minutesFormat(int minutes) {
    return '$minutes λεπ';
  }

  @override
  String departureLabel(String time) {
    return 'Αναχώρηση: $time';
  }

  @override
  String get changeButton => 'ΑΛΛΑΓΗ';

  @override
  String get daily => 'Καθημερινά';

  @override
  String get unknownDays => 'Άγνωστες ημέρες';

  @override
  String get searchRegionHint => 'Αναζήτηση περιοχής...';

  @override
  String get noRegionFound => 'Δεν βρέθηκε περιοχή.';

  @override
  String get searchStopHint => 'Αναζήτηση στάσης...';

  @override
  String get noStopFound => 'Δεν βρέθηκε στάση.';

  @override
  String durationHoursMinutes(int hours, String minutes) {
    return '$hours ώρ. $minutes λεπ.';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ώρες',
      one: '1 ώρα',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count λεπτά',
      one: '1 λεπτό',
    );
    return '$_temp0';
  }

  @override
  String get outbound => 'Μετάβαση';

  @override
  String get returnTrip => 'Επιστροφή';

  @override
  String get loadingStops => 'Φόρτωση στάσεων...';

  @override
  String get myLocation => 'Η τοποθεσία μου';

  @override
  String get locationDisabledTitle => 'Τοποθεσία ανενεργή';

  @override
  String get locationDisabledMessage =>
      'Παρακαλώ ενεργοποιήστε την τοποθεσία στη συσκευή σας για να δείτε τη θέση σας.';

  @override
  String get locationDeniedTitle => 'Δεν υπάρχει πρόσβαση';

  @override
  String get locationDeniedMessage =>
      'Η άδεια τοποθεσίας έχει απορριφθεί. Ανοίξτε τις ρυθμίσεις της εφαρμογής για να την ενεργοποιήσετε.';

  @override
  String get settingsButton => 'Ρυθμίσεις';

  @override
  String get maxWaitTime => 'Μέγιστη αναμονή μετεπιβίβασης';

  @override
  String get timeBasedTheme => 'Βάσει ώρας (Ημέρα/Νύχτα)';

  @override
  String get chosenPoint => 'Επιλεγμένο σημείο';

  @override
  String get searchingPoint => 'Αναζήτηση σημείου...';

  @override
  String get nearestStops => 'Πλησιέστερες στάσεις';

  @override
  String get calibrateCompassTitle => 'Βαθμονόμηση Πυξίδας';

  @override
  String get calibrateCompassDescription =>
      'Η πυξίδα της συσκευής σας είναι αυτή τη στιγμή αναξιόπιστη.\n\nΓια να βεβαιωθείτε ότι ο χάρτης δείχνει προς τη σωστή κατεύθυνση, κινήστε το τηλέφωνό σας στον αέρα σχηματίζοντας τον αριθμό \'8\' μερικές φορές.';

  @override
  String get gotItLabel => 'Το κατάλαβα';

  @override
  String get routeErrorTitle => 'Σφάλμα Διαδρομής';

  @override
  String routeErrorMessage(String stopName) {
    return 'Δεν ήταν δυνατός ο υπολογισμός της διαδρομής πεζών προς τη στάση $stopName. Παρακαλώ ελέγξτε τη σύνδεση σας και δοκιμάστε ξανά.';
  }

  @override
  String get retryButton => 'Δοκιμή ξανά';

  @override
  String get walking => 'Περπάτημα';

  @override
  String get walkFrom => 'Περπάτημα από';

  @override
  String get walkTo => 'Περπάτημα προς';

  @override
  String get walk => 'Περπατήστε';

  @override
  String get to => 'προς';

  @override
  String get pastTrips => 'Δρομολόγια που αναχώρησαν';

  @override
  String get availableRoutes => 'Διαθέσιμα δρομολόγια';

  @override
  String metersFormat(int meters) {
    return '$meters μ';
  }

  @override
  String kilometersFormat(String km) {
    return '$km χλμ';
  }

  @override
  String disembarkAt(String stop) {
    return 'Αποβίβαση: $stop';
  }

  @override
  String tripStopsCount(int count) {
    return 'Διαδρομή: $count στάσεις';
  }

  @override
  String get noInternetConnection =>
      'Δεν υπάρχει σύνδεση στο διαδίκτυο. Ελέγξτε το δίκτυό σας.';

  @override
  String get chooseInMap => 'Επιλέξτε στον χάρτη';

  @override
  String get chooseStartLocation => 'Επιλογή τοποθεσίας εκκίνησης';

  @override
  String get chooseDestinationLocation => 'Επιλογή τοποθεσίας προορισμού';

  @override
  String get setLocation => 'Ορισμός';

  @override
  String get routeFor => 'Δρομολόγιο για';

  @override
  String get resetToNow => 'Επαναφορά στο τώρα';

  @override
  String get autoSelectBestRoute =>
      'Αυτόματη εμφάνισης καλύτερης διαδρομής βάσει';

  @override
  String get minTotalTime => 'Μικρότερης συνολικής διάρκειας';

  @override
  String get minDepartTime => 'Νωρίτερης αναχώρησης';

  @override
  String get minArrivalTime => 'Νωρίτερης άφιξης';

  @override
  String get off => 'Ανενεργό';

  @override
  String get sortBy => 'Ταξινόμηση κατά';

  @override
  String get sortDirection => 'Φορά ταξινόμησης';

  @override
  String get ascending => 'Αύξουσα';

  @override
  String get descending => 'Φθίνουσα';

  @override
  String get sortByTransfers => 'Αριθμός μετεπιβιβάσεων';

  @override
  String get sortByWalkingTime => 'Διάρκεια πεζοπορίας';

  @override
  String get sortByCost => 'Κόστος';

  @override
  String get sortByTotalDuration => 'Συνολική διάρκεια';

  @override
  String get sortByTripDuration => 'Διάρκεια διαδρομής (μόνο λεωφορείο)';

  @override
  String get sortByArrivalTime => 'Ώρα άφιξης';

  @override
  String get sortByDepartureTime => 'Ώρα αναχώρησης';

  @override
  String get sortByWaitingTime => 'Διάρκεια αναμονής';

  @override
  String get filters => 'Φίλτρα';

  @override
  String get includeWalking => 'Χωρίς περπάτημα';

  @override
  String get includeDirectTripsOnly => 'Μόνο απευθείας διαδρομές';

  @override
  String get resetFilters => 'Επαναφορά φίλτρων';

  @override
  String get filtersActive => 'Φίλτρα ενεργά';

  @override
  String get apply => 'Εφαρμογή';

  @override
  String get sort => 'Ταξινόμηση';

  @override
  String get filter => 'Φίλτρο';

  @override
  String get loadingMap => 'Φορτώνεται ο χάρτης...';

  @override
  String get loadingRoutes => 'Φορτώνονται τα δρομολόγια...';
}
