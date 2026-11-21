// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Runbike Timer';

  @override
  String get audioPreparing => 'Preparing sounds...';

  @override
  String get tapToStart => 'Tap to start';

  @override
  String get tapRequiredNote => 'Tap once first so the app can play sounds';

  @override
  String get cannotSwitchTabWhileRecording =>
      'You can\'t switch tabs while recording';

  @override
  String get tabMeasure => 'Timer';

  @override
  String get tabPractice => 'Practice';

  @override
  String get tabAnalysis => 'Results';

  @override
  String get tabCourse => 'Course';

  @override
  String get tabWhistle => 'Whistle';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String timeSec(String time) {
    return '$time s';
  }

  @override
  String timeSecShort(String time) {
    return '${time}s';
  }

  @override
  String get notSelected => 'Not selected';

  @override
  String videoSavedToPhotos(String album) {
    return 'Video saved to Photos (album \"$album\")';
  }

  @override
  String get videoSavedInApp =>
      'Couldn\'t save to Photos, so the video was kept inside the app';

  @override
  String get videoSaveFailed => 'Couldn\'t save the video';

  @override
  String get cameraStartFailed => 'Couldn\'t start the camera';

  @override
  String photoAccessDenied(String app) {
    return 'The video couldn\'t be saved because photo access isn\'t allowed.\nGo to Settings → $app → Photos and choose \"Full Access\".';
  }

  @override
  String get practiceRunningStopFirst =>
      'Practice is running. Stop it before starting the timer.';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get viewRecording => 'View video';

  @override
  String get registerChildFirst => 'Please add a rider first';

  @override
  String personalBest(String time) {
    return '$time s — New personal best!';
  }

  @override
  String recordSaved(String time) {
    return 'Saved $time s!';
  }

  @override
  String get chooseChild => 'Choose rider';

  @override
  String get rename => 'Rename';

  @override
  String get addNewChild => 'Add a new rider';

  @override
  String get change => 'Change';

  @override
  String get deleteConfirmTitle => 'Delete?';

  @override
  String deleteChildMessage(String name) {
    return 'Delete $name?\nTheir rides will no longer be shown.';
  }

  @override
  String get enterChildName => 'Enter rider\'s name';

  @override
  String get childNameHint => 'e.g. Alex';

  @override
  String get add => 'Add';

  @override
  String get modeSolo => 'Solo';

  @override
  String get modeTeam => 'Team';

  @override
  String get startSound => 'Start sound';

  @override
  String get runBgm => 'Music while riding';

  @override
  String get recordVideo => 'Record video';

  @override
  String get recordingNow => 'Recording';

  @override
  String get abort => 'Stop';

  @override
  String get goal => 'FINISH!';

  @override
  String teamPlace(int rank, String time) {
    return '#$rank  ${time}s';
  }

  @override
  String get nextRace => 'Next race';

  @override
  String get btOffset => 'BT delay';

  @override
  String get soundSilent => 'Silent';

  @override
  String get soundBasic => 'Basic';

  @override
  String get soundFinal => 'Final';

  @override
  String get soundSemi => 'Semi-final';

  @override
  String get bgmNone => 'None';

  @override
  String get bgmSpeed => 'Speed';

  @override
  String get bgmRock => 'Rock';

  @override
  String get bgm8bit => '8-bit';

  @override
  String practiceVideosSaved(int count, String album) {
    return 'Saved $count ride videos to Photos (album \"$album\")';
  }

  @override
  String get measureRunningStopFirst =>
      'The timer is running. Finish it before starting practice.';

  @override
  String get intervalPractice => 'Interval training';

  @override
  String get total => 'Total';

  @override
  String get ride => 'Ride';

  @override
  String get rest => 'Rest';

  @override
  String get rounds => 'Rounds';

  @override
  String get unitSec => 's';

  @override
  String get unitTimes => 'x';

  @override
  String get bgmOff => 'Off';

  @override
  String get bgmMetronome => 'Metronome';

  @override
  String get bgmUpbeat => 'Upbeat';

  @override
  String get recordEachRide => 'Record each ride';

  @override
  String get paused => 'Paused';

  @override
  String recordingSavedCount(int count) {
    return 'Recording · $count saved';
  }

  @override
  String savedCount(int count) {
    return '$count saved';
  }

  @override
  String get captionReady => 'Go after the start signal';

  @override
  String get captionLastOne => 'Last one!';

  @override
  String captionNext(int n) {
    return 'Next: ride $n';
  }

  @override
  String captionFinished(int total) {
    return '$total rides done. Great job!';
  }

  @override
  String get resume => 'Resume';

  @override
  String get pause => 'Pause';

  @override
  String speedRecordFor(String time) {
    return 'Speed for the ${time}s ride';
  }

  @override
  String get maxSpeedKmh => 'Top speed (km/h)';

  @override
  String get avgSpeedKmh => 'Average speed (km/h)';

  @override
  String shareTitle(String name) {
    return '$name\'s rides today';
  }

  @override
  String shareLine(int n, String time) {
    return 'Ride $n: ${time}s';
  }

  @override
  String topSpeedValue(String v) {
    return 'Top $v km/h';
  }

  @override
  String avgSpeedValue(String v) {
    return 'Avg $v km/h';
  }

  @override
  String get shareBest => '★Best';

  @override
  String get resultsCopied => 'Results copied!';

  @override
  String get selectChild => 'Rider:';

  @override
  String get todayCount => 'Rides today';

  @override
  String get todayBest => 'Today\'s best';

  @override
  String get allTimeBest => 'All-time best';

  @override
  String get speedRecords => 'Speed records';

  @override
  String get bestTopSpeed => 'Best top speed';

  @override
  String get bestAvgSpeed => 'Best average speed';

  @override
  String get todayRides => 'Today\'s rides';

  @override
  String get tapSwipeHint => 'Tap to add speed / swipe to delete';

  @override
  String get noRidesToday => 'No rides yet today';

  @override
  String get deleteRideTitle => 'Delete ride';

  @override
  String deleteRideMessage(String time) {
    return 'Delete the ${time}s ride?';
  }

  @override
  String get shareToday => 'Share today\'s rides';

  @override
  String get registerChildInTimer => 'Add a rider in the Timer tab';

  @override
  String get courseSaved => 'Course saved';

  @override
  String get courseTitle => 'Course';

  @override
  String get savedChip => 'Saved';

  @override
  String get courseIntro => 'Optional: note today\'s course';

  @override
  String get courseName => 'Course name';

  @override
  String get courseNameHint => 'e.g. Park loop';

  @override
  String get courseLength => 'Length (m)';

  @override
  String get firstStraight => 'First straight (m)';

  @override
  String exampleNumber(int n) {
    return 'e.g. $n';
  }

  @override
  String get curvesLabel => 'Curves:';

  @override
  String get surfaceLabel => 'Surface:';

  @override
  String get weatherLabel => 'Weather:';

  @override
  String get surfaceAsphalt => 'Asphalt';

  @override
  String get surfaceGrass => 'Grass';

  @override
  String get surfaceIndoor => 'Indoor';

  @override
  String get surfaceGravel => 'Gravel';

  @override
  String get surfaceOther => 'Other';

  @override
  String get weatherSunny => 'Sunny';

  @override
  String get weatherCloudy => 'Cloudy';

  @override
  String get weatherRain => 'Rain';

  @override
  String get weatherWindy => 'Windy';

  @override
  String get memo => 'Notes';

  @override
  String get memoHint => 'Write anything you like';

  @override
  String get saveCourse => 'Save';

  @override
  String get pastCourses => 'Past courses';

  @override
  String get pastCoursesNote => 'Review saved courses by date';

  @override
  String get todayChip => 'Today';

  @override
  String get noName => '(No name)';

  @override
  String courseLengthShort(String v) {
    return '$v m long';
  }

  @override
  String courseStraightShort(String v) {
    return 'straight $v m';
  }

  @override
  String courseCurvesShort(int n) {
    return '$n curves';
  }

  @override
  String memoValue(String note) {
    return 'Notes: $note';
  }

  @override
  String get bgNotificationText => 'Timer is running (tap to return)';

  @override
  String get shareFooter =>
      '#RunbikeTimer #balancebike\nhttps://apps.apple.com/app/id6788356167';

  @override
  String get shareImage => 'Share image';

  @override
  String get shareText => 'Text';

  @override
  String get cardPersonalBest => 'Personal best!';

  @override
  String get cardShareButton => 'Share this image';

  @override
  String get cardFooter => 'Available on the App Store';
}
