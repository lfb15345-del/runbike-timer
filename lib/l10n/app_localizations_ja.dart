// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'ランバイクタイマー';

  @override
  String get audioPreparing => '音声を準備中...';

  @override
  String get tapToStart => 'タップして開始';

  @override
  String get tapRequiredNote => '音を鳴らすために、最初に1回タップが必要です';

  @override
  String get cannotSwitchTabWhileRecording => '録画中はタブを切り替えられません';

  @override
  String get tabMeasure => '計測';

  @override
  String get tabPractice => '練習';

  @override
  String get tabAnalysis => '解析・共有';

  @override
  String get tabCourse => 'コース設定';

  @override
  String get tabWhistle => 'ホイッスル';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get save => '保存';

  @override
  String timeSec(String time) {
    return '$time 秒';
  }

  @override
  String timeSecShort(String time) {
    return '$time秒';
  }

  @override
  String get notSelected => '未選択';

  @override
  String videoSavedToPhotos(String album) {
    return '動画を写真アプリに保存しました（アルバム「$album」）';
  }

  @override
  String get videoSavedInApp => '写真アプリに保存できなかったため、アプリ内に退避しました';

  @override
  String get videoSaveFailed => '動画の保存に失敗しました';

  @override
  String get cameraStartFailed => 'カメラを起動できませんでした';

  @override
  String photoAccessDenied(String app) {
    return '写真へのアクセスが許可されていないため、写真アプリに保存できませんでした。\n設定 → $app → 写真 を「フルアクセス」にしてください';
  }

  @override
  String get practiceRunningStopFirst => '練習タブが実行中です。練習を止めてからスタートしてください';

  @override
  String get cancelled => '中止しました';

  @override
  String get viewRecording => '録画を確認';

  @override
  String get registerChildFirst => '先に子どもを登録してください';

  @override
  String personalBest(String time) {
    return '$time 秒　自己ベスト更新！';
  }

  @override
  String recordSaved(String time) {
    return '$time 秒 を記録しました！';
  }

  @override
  String get chooseChild => '子どもを選ぶ';

  @override
  String get rename => '名前を変更';

  @override
  String get addNewChild => '新しい子どもを追加';

  @override
  String get change => '変更';

  @override
  String get deleteConfirmTitle => '削除の確認';

  @override
  String deleteChildMessage(String name) {
    return '$name を削除しますか？\n記録データも見られなくなります。';
  }

  @override
  String get enterChildName => '子どもの名前を入力';

  @override
  String get childNameHint => '例: ゆうた';

  @override
  String get add => '追加';

  @override
  String get modeSolo => '個人';

  @override
  String get modeTeam => 'チーム';

  @override
  String get startSound => 'スタート音';

  @override
  String get runBgm => '走行中BGM';

  @override
  String get recordVideo => '録画';

  @override
  String get recordingNow => '録画中';

  @override
  String get abort => '中止';

  @override
  String get goal => 'ゴール！';

  @override
  String teamPlace(int rank, String time) {
    return '$rank着 $time秒';
  }

  @override
  String get nextRace => '次のレースへ';

  @override
  String get btOffset => 'BT補正';

  @override
  String get soundSilent => 'サイレント';

  @override
  String get soundBasic => '基本';

  @override
  String get soundFinal => '決勝';

  @override
  String get soundSemi => '準決勝';

  @override
  String get bgmNone => 'なし';

  @override
  String get bgmSpeed => 'スピード';

  @override
  String get bgmRock => 'ロック';

  @override
  String get bgm8bit => '8ビット';

  @override
  String practiceVideosSaved(int count, String album) {
    return '走りの動画を$count本、写真アプリに保存しました（アルバム「$album」）';
  }

  @override
  String get measureRunningStopFirst => '計測タブが実行中です。計測を終えてからスタートしてください';

  @override
  String get intervalPractice => 'インターバル練習';

  @override
  String get total => '合計';

  @override
  String get ride => '走る';

  @override
  String get rest => '休む';

  @override
  String get rounds => '回数';

  @override
  String get unitSec => '秒';

  @override
  String get unitTimes => '回';

  @override
  String get bgmOff => '無音';

  @override
  String get bgmMetronome => 'メトロノーム';

  @override
  String get bgmUpbeat => 'アップテンポ';

  @override
  String get recordEachRide => '走るたびに録画';

  @override
  String get paused => '一時停止中';

  @override
  String recordingSavedCount(int count) {
    return '録画中 ・ 保存 $count本';
  }

  @override
  String savedCount(int count) {
    return '保存 $count本';
  }

  @override
  String get captionReady => 'スタート音のあとに走り出す';

  @override
  String get captionLastOne => 'ラスト1本！';

  @override
  String captionNext(int n) {
    return 'つぎは $n本目';
  }

  @override
  String captionFinished(int total) {
    return '$total本 おつかれさま！';
  }

  @override
  String get resume => '再開';

  @override
  String get pause => '一時停止';

  @override
  String speedRecordFor(String time) {
    return '$time秒 のスピード記録';
  }

  @override
  String get maxSpeedKmh => '最高速度 (km/h)';

  @override
  String get avgSpeedKmh => '平均速度 (km/h)';

  @override
  String shareTitle(String name) {
    return '$name の今日の記録';
  }

  @override
  String shareLine(int n, String time) {
    return '$n本目: $time秒';
  }

  @override
  String topSpeedValue(String v) {
    return '最高 ${v}km/h';
  }

  @override
  String avgSpeedValue(String v) {
    return '平均 ${v}km/h';
  }

  @override
  String get shareBest => '★ベスト';

  @override
  String get resultsCopied => '結果をコピーしました！';

  @override
  String get selectChild => '子どもを選択:';

  @override
  String get todayCount => '今日の本数';

  @override
  String get todayBest => '今日のベスト';

  @override
  String get allTimeBest => '歴代ベスト';

  @override
  String get speedRecords => 'スピード記録';

  @override
  String get bestTopSpeed => '歴代 最高速度';

  @override
  String get bestAvgSpeed => '歴代 平均速度ベスト';

  @override
  String get todayRides => '今日の走行一覧';

  @override
  String get tapSwipeHint => 'タップで速度入力 / スワイプで削除';

  @override
  String get noRidesToday => 'まだ今日の記録がありません';

  @override
  String get deleteRideTitle => '記録を削除';

  @override
  String deleteRideMessage(String time) {
    return '$time秒 の記録を削除しますか？';
  }

  @override
  String get shareToday => '今日の記録をシェア';

  @override
  String get registerChildInTimer => '計測タブで子どもを登録してください';

  @override
  String get courseSaved => 'コース情報を保存しました';

  @override
  String get courseTitle => 'コース設定';

  @override
  String get savedChip => '保存済み';

  @override
  String get courseIntro => '今日の練習コースの情報を入力できます（任意）';

  @override
  String get courseName => 'コース名';

  @override
  String get courseNameHint => '例: いつもの公園コース';

  @override
  String get courseLength => 'コース全長（m）';

  @override
  String get firstStraight => '初回直線の長さ（m）';

  @override
  String exampleNumber(int n) {
    return '例: $n';
  }

  @override
  String get curvesLabel => 'カーブ数:';

  @override
  String get surfaceLabel => '路面:';

  @override
  String get weatherLabel => '天気:';

  @override
  String get surfaceAsphalt => 'アスファルト';

  @override
  String get surfaceGrass => '芝生';

  @override
  String get surfaceIndoor => '室内';

  @override
  String get surfaceGravel => '砂利';

  @override
  String get surfaceOther => 'その他';

  @override
  String get weatherSunny => '晴れ';

  @override
  String get weatherCloudy => 'くもり';

  @override
  String get weatherRain => '雨';

  @override
  String get weatherWindy => '風あり';

  @override
  String get memo => 'メモ';

  @override
  String get memoHint => '自由にメモを書けます';

  @override
  String get saveCourse => '保存する';

  @override
  String get pastCourses => '過去のコース';

  @override
  String get pastCoursesNote => '保存したコース情報を日付ごとに見直せます';

  @override
  String get todayChip => '今日';

  @override
  String get noName => '（名前なし）';

  @override
  String courseLengthShort(String v) {
    return '全長${v}m';
  }

  @override
  String courseStraightShort(String v) {
    return '直線${v}m';
  }

  @override
  String courseCurvesShort(int n) {
    return 'カーブ$n';
  }

  @override
  String memoValue(String note) {
    return 'メモ: $note';
  }

  @override
  String get bgNotificationText => 'タイマーが動いています（タップで戻る）';
}
