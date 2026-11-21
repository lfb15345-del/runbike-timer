// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Laufrad-Timer';

  @override
  String get audioPreparing => 'Töne werden vorbereitet...';

  @override
  String get tapToStart => 'Zum Starten tippen';

  @override
  String get tapRequiredNote =>
      'Bitte einmal tippen, damit die App Töne abspielen kann';

  @override
  String get cannotSwitchTabWhileRecording =>
      'Während der Aufnahme kannst du den Tab nicht wechseln';

  @override
  String get tabMeasure => 'Timer';

  @override
  String get tabPractice => 'Training';

  @override
  String get tabAnalysis => 'Ergebnisse';

  @override
  String get tabCourse => 'Strecke';

  @override
  String get tabWhistle => 'Pfeife';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get save => 'Speichern';

  @override
  String timeSec(String time) {
    return '$time s';
  }

  @override
  String timeSecShort(String time) {
    return '${time}s';
  }

  @override
  String get notSelected => 'Nicht ausgewählt';

  @override
  String videoSavedToPhotos(String album) {
    return 'Video in Fotos gespeichert (Album „$album“)';
  }

  @override
  String get videoSavedInApp =>
      'Speichern in Fotos nicht möglich – das Video wurde in der App gespeichert';

  @override
  String get videoSaveFailed => 'Das Video konnte nicht gespeichert werden';

  @override
  String get cameraStartFailed => 'Die Kamera konnte nicht gestartet werden';

  @override
  String photoAccessDenied(String app) {
    return 'Das Video konnte nicht gespeichert werden, weil der Zugriff auf Fotos nicht erlaubt ist.\nÖffne Einstellungen → $app → Fotos und wähle „Voller Zugriff“.';
  }

  @override
  String get practiceRunningStopFirst =>
      'Das Training läuft. Beende es, bevor du den Timer startest.';

  @override
  String get cancelled => 'Abgebrochen';

  @override
  String get viewRecording => 'Video ansehen';

  @override
  String get registerChildFirst => 'Bitte zuerst ein Kind hinzufügen';

  @override
  String personalBest(String time) {
    return '$time s – neue Bestzeit!';
  }

  @override
  String recordSaved(String time) {
    return '$time s gespeichert!';
  }

  @override
  String get chooseChild => 'Kind auswählen';

  @override
  String get rename => 'Umbenennen';

  @override
  String get addNewChild => 'Neues Kind hinzufügen';

  @override
  String get change => 'Wechseln';

  @override
  String get deleteConfirmTitle => 'Löschen?';

  @override
  String deleteChildMessage(String name) {
    return '$name löschen?\nDie Fahrten werden dann nicht mehr angezeigt.';
  }

  @override
  String get enterChildName => 'Namen des Kindes eingeben';

  @override
  String get childNameHint => 'z. B. Max';

  @override
  String get add => 'Hinzufügen';

  @override
  String get modeSolo => 'Einzeln';

  @override
  String get modeTeam => 'Team';

  @override
  String get startSound => 'Startsignal';

  @override
  String get runBgm => 'Musik beim Fahren';

  @override
  String get recordVideo => 'Video aufnehmen';

  @override
  String get recordingNow => 'Aufnahme';

  @override
  String get abort => 'Stopp';

  @override
  String get goal => 'ZIEL!';

  @override
  String teamPlace(int rank, String time) {
    return '#$rank  ${time}s';
  }

  @override
  String get nextRace => 'Nächstes Rennen';

  @override
  String get btOffset => 'BT-Latenz';

  @override
  String get soundSilent => 'Stumm';

  @override
  String get soundBasic => 'Standard';

  @override
  String get soundFinal => 'Finale';

  @override
  String get soundSemi => 'Halbfinale';

  @override
  String get bgmNone => 'Keine';

  @override
  String get bgmSpeed => 'Speed';

  @override
  String get bgmRock => 'Rock';

  @override
  String get bgm8bit => '8-Bit';

  @override
  String practiceVideosSaved(int count, String album) {
    return '$count Fahrvideos in Fotos gespeichert (Album „$album“)';
  }

  @override
  String get measureRunningStopFirst =>
      'Der Timer läuft. Beende ihn, bevor du das Training startest.';

  @override
  String get intervalPractice => 'Intervalltraining';

  @override
  String get total => 'Gesamt';

  @override
  String get ride => 'Fahren';

  @override
  String get rest => 'Pause';

  @override
  String get rounds => 'Runden';

  @override
  String get unitSec => 's';

  @override
  String get unitTimes => 'x';

  @override
  String get bgmOff => 'Aus';

  @override
  String get bgmMetronome => 'Metronom';

  @override
  String get bgmUpbeat => 'Fröhlich';

  @override
  String get recordEachRide => 'Jede Fahrt aufnehmen';

  @override
  String get paused => 'Pausiert';

  @override
  String recordingSavedCount(int count) {
    return 'Aufnahme · $count gespeichert';
  }

  @override
  String savedCount(int count) {
    return '$count gespeichert';
  }

  @override
  String get captionReady => 'Nach dem Startsignal losfahren';

  @override
  String get captionLastOne => 'Letzte Fahrt!';

  @override
  String captionNext(int n) {
    return 'Als Nächstes: Fahrt $n';
  }

  @override
  String captionFinished(int total) {
    return '$total Fahrten geschafft. Super gemacht!';
  }

  @override
  String get resume => 'Weiter';

  @override
  String get pause => 'Pause';

  @override
  String speedRecordFor(String time) {
    return 'Tempo der Fahrt ($time s)';
  }

  @override
  String get maxSpeedKmh => 'Höchsttempo (km/h)';

  @override
  String get avgSpeedKmh => 'Durchschnittstempo (km/h)';

  @override
  String shareTitle(String name) {
    return 'Heutige Fahrten von $name';
  }

  @override
  String shareLine(int n, String time) {
    return 'Fahrt $n: $time s';
  }

  @override
  String topSpeedValue(String v) {
    return 'Max. $v km/h';
  }

  @override
  String avgSpeedValue(String v) {
    return 'Ø $v km/h';
  }

  @override
  String get shareBest => '★Bestzeit';

  @override
  String get resultsCopied => 'Ergebnisse kopiert!';

  @override
  String get selectChild => 'Kind:';

  @override
  String get todayCount => 'Fahrten heute';

  @override
  String get todayBest => 'Bestzeit heute';

  @override
  String get allTimeBest => 'Bestzeit gesamt';

  @override
  String get speedRecords => 'Tempo-Rekorde';

  @override
  String get bestTopSpeed => 'Bestes Höchsttempo';

  @override
  String get bestAvgSpeed => 'Bestes Durchschnittstempo';

  @override
  String get todayRides => 'Heutige Fahrten';

  @override
  String get tapSwipeHint => 'Tippen: Tempo eintragen / Wischen: löschen';

  @override
  String get noRidesToday => 'Heute noch keine Fahrten';

  @override
  String get deleteRideTitle => 'Fahrt löschen';

  @override
  String deleteRideMessage(String time) {
    return 'Die Fahrt mit $time s löschen?';
  }

  @override
  String get shareToday => 'Heutige Fahrten teilen';

  @override
  String get registerChildInTimer => 'Füge im Tab „Timer“ ein Kind hinzu';

  @override
  String get courseSaved => 'Strecke gespeichert';

  @override
  String get courseTitle => 'Strecke';

  @override
  String get savedChip => 'Gespeichert';

  @override
  String get courseIntro => 'Optional: die heutige Strecke notieren';

  @override
  String get courseName => 'Name der Strecke';

  @override
  String get courseNameHint => 'z. B. Runde im Park';

  @override
  String get courseLength => 'Länge (m)';

  @override
  String get firstStraight => 'Erste Gerade (m)';

  @override
  String exampleNumber(int n) {
    return 'z. B. $n';
  }

  @override
  String get curvesLabel => 'Kurven:';

  @override
  String get surfaceLabel => 'Belag:';

  @override
  String get weatherLabel => 'Wetter:';

  @override
  String get surfaceAsphalt => 'Asphalt';

  @override
  String get surfaceGrass => 'Rasen';

  @override
  String get surfaceIndoor => 'Halle';

  @override
  String get surfaceGravel => 'Schotter';

  @override
  String get surfaceOther => 'Sonstiges';

  @override
  String get weatherSunny => 'Sonnig';

  @override
  String get weatherCloudy => 'Bewölkt';

  @override
  String get weatherRain => 'Regen';

  @override
  String get weatherWindy => 'Windig';

  @override
  String get memo => 'Notizen';

  @override
  String get memoHint => 'Freie Notizen';

  @override
  String get saveCourse => 'Speichern';

  @override
  String get pastCourses => 'Frühere Strecken';

  @override
  String get pastCoursesNote => 'Gespeicherte Strecken nach Datum ansehen';

  @override
  String get todayChip => 'Heute';

  @override
  String get noName => '(Ohne Namen)';

  @override
  String courseLengthShort(String v) {
    return '$v m lang';
  }

  @override
  String courseStraightShort(String v) {
    return 'Gerade $v m';
  }

  @override
  String courseCurvesShort(int n) {
    return '$n Kurven';
  }

  @override
  String memoValue(String note) {
    return 'Notizen: $note';
  }

  @override
  String get bgNotificationText => 'Der Timer läuft (zum Zurückkehren tippen)';

  @override
  String get shareFooter =>
      '#LaufradTimer #Laufrad\nhttps://apps.apple.com/app/id6788356167';

  @override
  String get shareImage => 'Als Bild teilen';

  @override
  String get shareText => 'Text';

  @override
  String get cardPersonalBest => 'Neue Bestzeit!';

  @override
  String get cardShareButton => 'Dieses Bild teilen';

  @override
  String get cardFooter => 'Im App Store erhältlich';
}
