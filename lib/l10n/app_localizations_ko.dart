// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '런바이크 타이머';

  @override
  String get audioPreparing => '소리를 준비하는 중...';

  @override
  String get tapToStart => '탭하여 시작';

  @override
  String get tapRequiredNote => '소리를 재생하려면 먼저 한 번 탭하세요';

  @override
  String get cannotSwitchTabWhileRecording => '녹화 중에는 탭을 바꿀 수 없습니다';

  @override
  String get tabMeasure => '측정';

  @override
  String get tabPractice => '연습';

  @override
  String get tabAnalysis => '기록·공유';

  @override
  String get tabCourse => '코스';

  @override
  String get tabWhistle => '호루라기';

  @override
  String get cancel => '취소';

  @override
  String get delete => '삭제';

  @override
  String get save => '저장';

  @override
  String timeSec(String time) {
    return '$time초';
  }

  @override
  String timeSecShort(String time) {
    return '$time초';
  }

  @override
  String get notSelected => '선택 안 됨';

  @override
  String videoSavedToPhotos(String album) {
    return '동영상을 사진 앱에 저장했습니다 (앨범 \"$album\")';
  }

  @override
  String get videoSavedInApp => '사진 앱에 저장하지 못해 앱 안에 보관했습니다';

  @override
  String get videoSaveFailed => '동영상 저장에 실패했습니다';

  @override
  String get cameraStartFailed => '카메라를 시작할 수 없습니다';

  @override
  String photoAccessDenied(String app) {
    return '사진 접근이 허용되지 않아 동영상을 저장하지 못했습니다.\n설정 → $app → 사진에서 \'전체 접근\'을 선택하세요';
  }

  @override
  String get practiceRunningStopFirst => '연습이 진행 중입니다. 연습을 멈춘 뒤 시작하세요';

  @override
  String get cancelled => '취소했습니다';

  @override
  String get viewRecording => '녹화 보기';

  @override
  String get registerChildFirst => '먼저 아이를 등록하세요';

  @override
  String personalBest(String time) {
    return '$time초 — 개인 최고 기록 경신!';
  }

  @override
  String recordSaved(String time) {
    return '$time초를 기록했습니다!';
  }

  @override
  String get chooseChild => '아이 선택';

  @override
  String get rename => '이름 변경';

  @override
  String get addNewChild => '새 아이 추가';

  @override
  String get change => '변경';

  @override
  String get deleteConfirmTitle => '삭제 확인';

  @override
  String deleteChildMessage(String name) {
    return '$name을(를) 삭제할까요?\n기록도 더 이상 볼 수 없습니다.';
  }

  @override
  String get enterChildName => '아이 이름 입력';

  @override
  String get childNameHint => '예: 민준';

  @override
  String get add => '추가';

  @override
  String get modeSolo => '개인';

  @override
  String get modeTeam => '팀';

  @override
  String get startSound => '출발 소리';

  @override
  String get runBgm => '주행 중 음악';

  @override
  String get recordVideo => '녹화';

  @override
  String get recordingNow => '녹화 중';

  @override
  String get abort => '중지';

  @override
  String get goal => '골인!';

  @override
  String teamPlace(int rank, String time) {
    return '$rank위 $time초';
  }

  @override
  String get nextRace => '다음 레이스';

  @override
  String get btOffset => 'BT 보정';

  @override
  String get soundSilent => '무음';

  @override
  String get soundBasic => '기본';

  @override
  String get soundFinal => '결승';

  @override
  String get soundSemi => '준결승';

  @override
  String get bgmNone => '없음';

  @override
  String get bgmSpeed => '스피드';

  @override
  String get bgmRock => '록';

  @override
  String get bgm8bit => '8비트';

  @override
  String practiceVideosSaved(int count, String album) {
    return '주행 영상 $count개를 사진 앱에 저장했습니다 (앨범 \"$album\")';
  }

  @override
  String get measureRunningStopFirst => '측정이 진행 중입니다. 측정을 마친 뒤 시작하세요';

  @override
  String get intervalPractice => '인터벌 연습';

  @override
  String get total => '합계';

  @override
  String get ride => '달리기';

  @override
  String get rest => '휴식';

  @override
  String get rounds => '횟수';

  @override
  String get unitSec => '초';

  @override
  String get unitTimes => '회';

  @override
  String get bgmOff => '무음';

  @override
  String get bgmMetronome => '메트로놈';

  @override
  String get bgmUpbeat => '업템포';

  @override
  String get recordEachRide => '달릴 때마다 녹화';

  @override
  String get paused => '일시정지 중';

  @override
  String recordingSavedCount(int count) {
    return '녹화 중 · 저장 $count개';
  }

  @override
  String savedCount(int count) {
    return '저장 $count개';
  }

  @override
  String get captionReady => '출발 신호 후에 출발';

  @override
  String get captionLastOne => '마지막 한 번!';

  @override
  String captionNext(int n) {
    return '다음: $n번째';
  }

  @override
  String captionFinished(int total) {
    return '$total번 완주! 수고했어요!';
  }

  @override
  String get resume => '다시 시작';

  @override
  String get pause => '일시정지';

  @override
  String speedRecordFor(String time) {
    return '$time초 기록의 속도';
  }

  @override
  String get maxSpeedKmh => '최고 속도 (km/h)';

  @override
  String get avgSpeedKmh => '평균 속도 (km/h)';

  @override
  String shareTitle(String name) {
    return '$name의 오늘 기록';
  }

  @override
  String shareLine(int n, String time) {
    return '$n번째: $time초';
  }

  @override
  String topSpeedValue(String v) {
    return '최고 ${v}km/h';
  }

  @override
  String avgSpeedValue(String v) {
    return '평균 ${v}km/h';
  }

  @override
  String get shareBest => '★베스트';

  @override
  String get resultsCopied => '결과를 복사했습니다!';

  @override
  String get selectChild => '아이 선택:';

  @override
  String get todayCount => '오늘 횟수';

  @override
  String get todayBest => '오늘 최고';

  @override
  String get allTimeBest => '역대 최고';

  @override
  String get speedRecords => '속도 기록';

  @override
  String get bestTopSpeed => '역대 최고 속도';

  @override
  String get bestAvgSpeed => '역대 최고 평균 속도';

  @override
  String get todayRides => '오늘 주행 목록';

  @override
  String get tapSwipeHint => '탭: 속도 입력 / 밀어서 삭제';

  @override
  String get noRidesToday => '오늘 기록이 아직 없습니다';

  @override
  String get deleteRideTitle => '기록 삭제';

  @override
  String deleteRideMessage(String time) {
    return '$time초 기록을 삭제할까요?';
  }

  @override
  String get shareToday => '오늘 기록 공유';

  @override
  String get registerChildInTimer => '측정 탭에서 아이를 등록하세요';

  @override
  String get courseSaved => '코스를 저장했습니다';

  @override
  String get courseTitle => '코스 설정';

  @override
  String get savedChip => '저장됨';

  @override
  String get courseIntro => '오늘 연습 코스 정보를 입력할 수 있습니다 (선택)';

  @override
  String get courseName => '코스 이름';

  @override
  String get courseNameHint => '예: 공원 코스';

  @override
  String get courseLength => '코스 길이 (m)';

  @override
  String get firstStraight => '첫 직선 길이 (m)';

  @override
  String exampleNumber(int n) {
    return '예: $n';
  }

  @override
  String get curvesLabel => '커브 수:';

  @override
  String get surfaceLabel => '노면:';

  @override
  String get weatherLabel => '날씨:';

  @override
  String get surfaceAsphalt => '아스팔트';

  @override
  String get surfaceGrass => '잔디';

  @override
  String get surfaceIndoor => '실내';

  @override
  String get surfaceGravel => '자갈';

  @override
  String get surfaceOther => '기타';

  @override
  String get weatherSunny => '맑음';

  @override
  String get weatherCloudy => '흐림';

  @override
  String get weatherRain => '비';

  @override
  String get weatherWindy => '바람';

  @override
  String get memo => '메모';

  @override
  String get memoHint => '자유롭게 메모하세요';

  @override
  String get saveCourse => '저장하기';

  @override
  String get pastCourses => '지난 코스';

  @override
  String get pastCoursesNote => '저장한 코스를 날짜별로 볼 수 있습니다';

  @override
  String get todayChip => '오늘';

  @override
  String get noName => '(이름 없음)';

  @override
  String courseLengthShort(String v) {
    return '길이 ${v}m';
  }

  @override
  String courseStraightShort(String v) {
    return '직선 ${v}m';
  }

  @override
  String courseCurvesShort(int n) {
    return '커브 $n';
  }

  @override
  String memoValue(String note) {
    return '메모: $note';
  }

  @override
  String get bgNotificationText => '타이머 작동 중 (탭하여 돌아가기)';
}
