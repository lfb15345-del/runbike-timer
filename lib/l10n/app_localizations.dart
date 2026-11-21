import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_th.dart';
import 'app_localizations_zh.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('th'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ja, this message translates to:
  /// **'ランバイクタイマー'**
  String get appTitle;

  /// No description provided for @audioPreparing.
  ///
  /// In ja, this message translates to:
  /// **'音声を準備中...'**
  String get audioPreparing;

  /// No description provided for @tapToStart.
  ///
  /// In ja, this message translates to:
  /// **'タップして開始'**
  String get tapToStart;

  /// No description provided for @tapRequiredNote.
  ///
  /// In ja, this message translates to:
  /// **'音を鳴らすために、最初に1回タップが必要です'**
  String get tapRequiredNote;

  /// No description provided for @cannotSwitchTabWhileRecording.
  ///
  /// In ja, this message translates to:
  /// **'録画中はタブを切り替えられません'**
  String get cannotSwitchTabWhileRecording;

  /// No description provided for @tabMeasure.
  ///
  /// In ja, this message translates to:
  /// **'計測'**
  String get tabMeasure;

  /// No description provided for @tabPractice.
  ///
  /// In ja, this message translates to:
  /// **'練習'**
  String get tabPractice;

  /// No description provided for @tabAnalysis.
  ///
  /// In ja, this message translates to:
  /// **'解析・共有'**
  String get tabAnalysis;

  /// No description provided for @tabCourse.
  ///
  /// In ja, this message translates to:
  /// **'コース設定'**
  String get tabCourse;

  /// No description provided for @tabWhistle.
  ///
  /// In ja, this message translates to:
  /// **'ホイッスル'**
  String get tabWhistle;

  /// No description provided for @cancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @timeSec.
  ///
  /// In ja, this message translates to:
  /// **'{time} 秒'**
  String timeSec(String time);

  /// No description provided for @timeSecShort.
  ///
  /// In ja, this message translates to:
  /// **'{time}秒'**
  String timeSecShort(String time);

  /// No description provided for @notSelected.
  ///
  /// In ja, this message translates to:
  /// **'未選択'**
  String get notSelected;

  /// No description provided for @videoSavedToPhotos.
  ///
  /// In ja, this message translates to:
  /// **'動画を写真アプリに保存しました（アルバム「{album}」）'**
  String videoSavedToPhotos(String album);

  /// No description provided for @videoSavedInApp.
  ///
  /// In ja, this message translates to:
  /// **'写真アプリに保存できなかったため、アプリ内に退避しました'**
  String get videoSavedInApp;

  /// No description provided for @videoSaveFailed.
  ///
  /// In ja, this message translates to:
  /// **'動画の保存に失敗しました'**
  String get videoSaveFailed;

  /// No description provided for @cameraStartFailed.
  ///
  /// In ja, this message translates to:
  /// **'カメラを起動できませんでした'**
  String get cameraStartFailed;

  /// No description provided for @photoAccessDenied.
  ///
  /// In ja, this message translates to:
  /// **'写真へのアクセスが許可されていないため、写真アプリに保存できませんでした。\n設定 → {app} → 写真 を「フルアクセス」にしてください'**
  String photoAccessDenied(String app);

  /// No description provided for @practiceRunningStopFirst.
  ///
  /// In ja, this message translates to:
  /// **'練習タブが実行中です。練習を止めてからスタートしてください'**
  String get practiceRunningStopFirst;

  /// No description provided for @cancelled.
  ///
  /// In ja, this message translates to:
  /// **'中止しました'**
  String get cancelled;

  /// No description provided for @viewRecording.
  ///
  /// In ja, this message translates to:
  /// **'録画を確認'**
  String get viewRecording;

  /// No description provided for @registerChildFirst.
  ///
  /// In ja, this message translates to:
  /// **'先に子どもを登録してください'**
  String get registerChildFirst;

  /// No description provided for @personalBest.
  ///
  /// In ja, this message translates to:
  /// **'{time} 秒　自己ベスト更新！'**
  String personalBest(String time);

  /// No description provided for @recordSaved.
  ///
  /// In ja, this message translates to:
  /// **'{time} 秒 を記録しました！'**
  String recordSaved(String time);

  /// No description provided for @chooseChild.
  ///
  /// In ja, this message translates to:
  /// **'子どもを選ぶ'**
  String get chooseChild;

  /// No description provided for @rename.
  ///
  /// In ja, this message translates to:
  /// **'名前を変更'**
  String get rename;

  /// No description provided for @addNewChild.
  ///
  /// In ja, this message translates to:
  /// **'新しい子どもを追加'**
  String get addNewChild;

  /// No description provided for @change.
  ///
  /// In ja, this message translates to:
  /// **'変更'**
  String get change;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In ja, this message translates to:
  /// **'削除の確認'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteChildMessage.
  ///
  /// In ja, this message translates to:
  /// **'{name} を削除しますか？\n記録データも見られなくなります。'**
  String deleteChildMessage(String name);

  /// No description provided for @enterChildName.
  ///
  /// In ja, this message translates to:
  /// **'子どもの名前を入力'**
  String get enterChildName;

  /// No description provided for @childNameHint.
  ///
  /// In ja, this message translates to:
  /// **'例: ゆうた'**
  String get childNameHint;

  /// No description provided for @add.
  ///
  /// In ja, this message translates to:
  /// **'追加'**
  String get add;

  /// No description provided for @modeSolo.
  ///
  /// In ja, this message translates to:
  /// **'個人'**
  String get modeSolo;

  /// No description provided for @modeTeam.
  ///
  /// In ja, this message translates to:
  /// **'チーム'**
  String get modeTeam;

  /// No description provided for @startSound.
  ///
  /// In ja, this message translates to:
  /// **'スタート音'**
  String get startSound;

  /// No description provided for @runBgm.
  ///
  /// In ja, this message translates to:
  /// **'走行中BGM'**
  String get runBgm;

  /// No description provided for @recordVideo.
  ///
  /// In ja, this message translates to:
  /// **'録画'**
  String get recordVideo;

  /// No description provided for @recordingNow.
  ///
  /// In ja, this message translates to:
  /// **'録画中'**
  String get recordingNow;

  /// No description provided for @abort.
  ///
  /// In ja, this message translates to:
  /// **'中止'**
  String get abort;

  /// No description provided for @goal.
  ///
  /// In ja, this message translates to:
  /// **'ゴール！'**
  String get goal;

  /// No description provided for @teamPlace.
  ///
  /// In ja, this message translates to:
  /// **'{rank}着 {time}秒'**
  String teamPlace(int rank, String time);

  /// No description provided for @nextRace.
  ///
  /// In ja, this message translates to:
  /// **'次のレースへ'**
  String get nextRace;

  /// No description provided for @btOffset.
  ///
  /// In ja, this message translates to:
  /// **'BT補正'**
  String get btOffset;

  /// No description provided for @soundSilent.
  ///
  /// In ja, this message translates to:
  /// **'サイレント'**
  String get soundSilent;

  /// No description provided for @soundBasic.
  ///
  /// In ja, this message translates to:
  /// **'基本'**
  String get soundBasic;

  /// No description provided for @soundFinal.
  ///
  /// In ja, this message translates to:
  /// **'決勝'**
  String get soundFinal;

  /// No description provided for @soundSemi.
  ///
  /// In ja, this message translates to:
  /// **'準決勝'**
  String get soundSemi;

  /// No description provided for @bgmNone.
  ///
  /// In ja, this message translates to:
  /// **'なし'**
  String get bgmNone;

  /// No description provided for @bgmSpeed.
  ///
  /// In ja, this message translates to:
  /// **'スピード'**
  String get bgmSpeed;

  /// No description provided for @bgmRock.
  ///
  /// In ja, this message translates to:
  /// **'ロック'**
  String get bgmRock;

  /// No description provided for @bgm8bit.
  ///
  /// In ja, this message translates to:
  /// **'8ビット'**
  String get bgm8bit;

  /// No description provided for @practiceVideosSaved.
  ///
  /// In ja, this message translates to:
  /// **'走りの動画を{count}本、写真アプリに保存しました（アルバム「{album}」）'**
  String practiceVideosSaved(int count, String album);

  /// No description provided for @measureRunningStopFirst.
  ///
  /// In ja, this message translates to:
  /// **'計測タブが実行中です。計測を終えてからスタートしてください'**
  String get measureRunningStopFirst;

  /// No description provided for @intervalPractice.
  ///
  /// In ja, this message translates to:
  /// **'インターバル練習'**
  String get intervalPractice;

  /// No description provided for @total.
  ///
  /// In ja, this message translates to:
  /// **'合計'**
  String get total;

  /// No description provided for @ride.
  ///
  /// In ja, this message translates to:
  /// **'走る'**
  String get ride;

  /// No description provided for @rest.
  ///
  /// In ja, this message translates to:
  /// **'休む'**
  String get rest;

  /// No description provided for @rounds.
  ///
  /// In ja, this message translates to:
  /// **'回数'**
  String get rounds;

  /// No description provided for @unitSec.
  ///
  /// In ja, this message translates to:
  /// **'秒'**
  String get unitSec;

  /// No description provided for @unitTimes.
  ///
  /// In ja, this message translates to:
  /// **'回'**
  String get unitTimes;

  /// No description provided for @bgmOff.
  ///
  /// In ja, this message translates to:
  /// **'無音'**
  String get bgmOff;

  /// No description provided for @bgmMetronome.
  ///
  /// In ja, this message translates to:
  /// **'メトロノーム'**
  String get bgmMetronome;

  /// No description provided for @bgmUpbeat.
  ///
  /// In ja, this message translates to:
  /// **'アップテンポ'**
  String get bgmUpbeat;

  /// No description provided for @recordEachRide.
  ///
  /// In ja, this message translates to:
  /// **'走るたびに録画'**
  String get recordEachRide;

  /// No description provided for @paused.
  ///
  /// In ja, this message translates to:
  /// **'一時停止中'**
  String get paused;

  /// No description provided for @recordingSavedCount.
  ///
  /// In ja, this message translates to:
  /// **'録画中 ・ 保存 {count}本'**
  String recordingSavedCount(int count);

  /// No description provided for @savedCount.
  ///
  /// In ja, this message translates to:
  /// **'保存 {count}本'**
  String savedCount(int count);

  /// No description provided for @captionReady.
  ///
  /// In ja, this message translates to:
  /// **'スタート音のあとに走り出す'**
  String get captionReady;

  /// No description provided for @captionLastOne.
  ///
  /// In ja, this message translates to:
  /// **'ラスト1本！'**
  String get captionLastOne;

  /// No description provided for @captionNext.
  ///
  /// In ja, this message translates to:
  /// **'つぎは {n}本目'**
  String captionNext(int n);

  /// No description provided for @captionFinished.
  ///
  /// In ja, this message translates to:
  /// **'{total}本 おつかれさま！'**
  String captionFinished(int total);

  /// No description provided for @resume.
  ///
  /// In ja, this message translates to:
  /// **'再開'**
  String get resume;

  /// No description provided for @pause.
  ///
  /// In ja, this message translates to:
  /// **'一時停止'**
  String get pause;

  /// No description provided for @speedRecordFor.
  ///
  /// In ja, this message translates to:
  /// **'{time}秒 のスピード記録'**
  String speedRecordFor(String time);

  /// No description provided for @maxSpeedKmh.
  ///
  /// In ja, this message translates to:
  /// **'最高速度 (km/h)'**
  String get maxSpeedKmh;

  /// No description provided for @avgSpeedKmh.
  ///
  /// In ja, this message translates to:
  /// **'平均速度 (km/h)'**
  String get avgSpeedKmh;

  /// No description provided for @shareTitle.
  ///
  /// In ja, this message translates to:
  /// **'{name} の今日の記録'**
  String shareTitle(String name);

  /// No description provided for @shareLine.
  ///
  /// In ja, this message translates to:
  /// **'{n}本目: {time}秒'**
  String shareLine(int n, String time);

  /// No description provided for @topSpeedValue.
  ///
  /// In ja, this message translates to:
  /// **'最高 {v}km/h'**
  String topSpeedValue(String v);

  /// No description provided for @avgSpeedValue.
  ///
  /// In ja, this message translates to:
  /// **'平均 {v}km/h'**
  String avgSpeedValue(String v);

  /// No description provided for @shareBest.
  ///
  /// In ja, this message translates to:
  /// **'★ベスト'**
  String get shareBest;

  /// No description provided for @resultsCopied.
  ///
  /// In ja, this message translates to:
  /// **'結果をコピーしました！'**
  String get resultsCopied;

  /// No description provided for @selectChild.
  ///
  /// In ja, this message translates to:
  /// **'子どもを選択:'**
  String get selectChild;

  /// No description provided for @todayCount.
  ///
  /// In ja, this message translates to:
  /// **'今日の本数'**
  String get todayCount;

  /// No description provided for @todayBest.
  ///
  /// In ja, this message translates to:
  /// **'今日のベスト'**
  String get todayBest;

  /// No description provided for @allTimeBest.
  ///
  /// In ja, this message translates to:
  /// **'歴代ベスト'**
  String get allTimeBest;

  /// No description provided for @speedRecords.
  ///
  /// In ja, this message translates to:
  /// **'スピード記録'**
  String get speedRecords;

  /// No description provided for @bestTopSpeed.
  ///
  /// In ja, this message translates to:
  /// **'歴代 最高速度'**
  String get bestTopSpeed;

  /// No description provided for @bestAvgSpeed.
  ///
  /// In ja, this message translates to:
  /// **'歴代 平均速度ベスト'**
  String get bestAvgSpeed;

  /// No description provided for @todayRides.
  ///
  /// In ja, this message translates to:
  /// **'今日の走行一覧'**
  String get todayRides;

  /// No description provided for @tapSwipeHint.
  ///
  /// In ja, this message translates to:
  /// **'タップで速度入力 / スワイプで削除'**
  String get tapSwipeHint;

  /// No description provided for @noRidesToday.
  ///
  /// In ja, this message translates to:
  /// **'まだ今日の記録がありません'**
  String get noRidesToday;

  /// No description provided for @deleteRideTitle.
  ///
  /// In ja, this message translates to:
  /// **'記録を削除'**
  String get deleteRideTitle;

  /// No description provided for @deleteRideMessage.
  ///
  /// In ja, this message translates to:
  /// **'{time}秒 の記録を削除しますか？'**
  String deleteRideMessage(String time);

  /// No description provided for @shareToday.
  ///
  /// In ja, this message translates to:
  /// **'今日の記録をシェア'**
  String get shareToday;

  /// No description provided for @registerChildInTimer.
  ///
  /// In ja, this message translates to:
  /// **'計測タブで子どもを登録してください'**
  String get registerChildInTimer;

  /// No description provided for @courseSaved.
  ///
  /// In ja, this message translates to:
  /// **'コース情報を保存しました'**
  String get courseSaved;

  /// No description provided for @courseTitle.
  ///
  /// In ja, this message translates to:
  /// **'コース設定'**
  String get courseTitle;

  /// No description provided for @savedChip.
  ///
  /// In ja, this message translates to:
  /// **'保存済み'**
  String get savedChip;

  /// No description provided for @courseIntro.
  ///
  /// In ja, this message translates to:
  /// **'今日の練習コースの情報を入力できます（任意）'**
  String get courseIntro;

  /// No description provided for @courseName.
  ///
  /// In ja, this message translates to:
  /// **'コース名'**
  String get courseName;

  /// No description provided for @courseNameHint.
  ///
  /// In ja, this message translates to:
  /// **'例: いつもの公園コース'**
  String get courseNameHint;

  /// No description provided for @courseLength.
  ///
  /// In ja, this message translates to:
  /// **'コース全長（m）'**
  String get courseLength;

  /// No description provided for @firstStraight.
  ///
  /// In ja, this message translates to:
  /// **'初回直線の長さ（m）'**
  String get firstStraight;

  /// No description provided for @exampleNumber.
  ///
  /// In ja, this message translates to:
  /// **'例: {n}'**
  String exampleNumber(int n);

  /// No description provided for @curvesLabel.
  ///
  /// In ja, this message translates to:
  /// **'カーブ数:'**
  String get curvesLabel;

  /// No description provided for @surfaceLabel.
  ///
  /// In ja, this message translates to:
  /// **'路面:'**
  String get surfaceLabel;

  /// No description provided for @weatherLabel.
  ///
  /// In ja, this message translates to:
  /// **'天気:'**
  String get weatherLabel;

  /// No description provided for @surfaceAsphalt.
  ///
  /// In ja, this message translates to:
  /// **'アスファルト'**
  String get surfaceAsphalt;

  /// No description provided for @surfaceGrass.
  ///
  /// In ja, this message translates to:
  /// **'芝生'**
  String get surfaceGrass;

  /// No description provided for @surfaceIndoor.
  ///
  /// In ja, this message translates to:
  /// **'室内'**
  String get surfaceIndoor;

  /// No description provided for @surfaceGravel.
  ///
  /// In ja, this message translates to:
  /// **'砂利'**
  String get surfaceGravel;

  /// No description provided for @surfaceOther.
  ///
  /// In ja, this message translates to:
  /// **'その他'**
  String get surfaceOther;

  /// No description provided for @weatherSunny.
  ///
  /// In ja, this message translates to:
  /// **'晴れ'**
  String get weatherSunny;

  /// No description provided for @weatherCloudy.
  ///
  /// In ja, this message translates to:
  /// **'くもり'**
  String get weatherCloudy;

  /// No description provided for @weatherRain.
  ///
  /// In ja, this message translates to:
  /// **'雨'**
  String get weatherRain;

  /// No description provided for @weatherWindy.
  ///
  /// In ja, this message translates to:
  /// **'風あり'**
  String get weatherWindy;

  /// No description provided for @memo.
  ///
  /// In ja, this message translates to:
  /// **'メモ'**
  String get memo;

  /// No description provided for @memoHint.
  ///
  /// In ja, this message translates to:
  /// **'自由にメモを書けます'**
  String get memoHint;

  /// No description provided for @saveCourse.
  ///
  /// In ja, this message translates to:
  /// **'保存する'**
  String get saveCourse;

  /// No description provided for @pastCourses.
  ///
  /// In ja, this message translates to:
  /// **'過去のコース'**
  String get pastCourses;

  /// No description provided for @pastCoursesNote.
  ///
  /// In ja, this message translates to:
  /// **'保存したコース情報を日付ごとに見直せます'**
  String get pastCoursesNote;

  /// No description provided for @todayChip.
  ///
  /// In ja, this message translates to:
  /// **'今日'**
  String get todayChip;

  /// No description provided for @noName.
  ///
  /// In ja, this message translates to:
  /// **'（名前なし）'**
  String get noName;

  /// No description provided for @courseLengthShort.
  ///
  /// In ja, this message translates to:
  /// **'全長{v}m'**
  String courseLengthShort(String v);

  /// No description provided for @courseStraightShort.
  ///
  /// In ja, this message translates to:
  /// **'直線{v}m'**
  String courseStraightShort(String v);

  /// No description provided for @courseCurvesShort.
  ///
  /// In ja, this message translates to:
  /// **'カーブ{n}'**
  String courseCurvesShort(int n);

  /// No description provided for @memoValue.
  ///
  /// In ja, this message translates to:
  /// **'メモ: {note}'**
  String memoValue(String note);

  /// No description provided for @bgNotificationText.
  ///
  /// In ja, this message translates to:
  /// **'タイマーが動いています（タップで戻る）'**
  String get bgNotificationText;

  /// シェアの最後に付けるハッシュタグとApp Storeのリンク
  ///
  /// In ja, this message translates to:
  /// **'#ランバイクタイマー #ランバイク\nhttps://apps.apple.com/app/id6788356167'**
  String get shareFooter;

  /// No description provided for @shareImage.
  ///
  /// In ja, this message translates to:
  /// **'画像でシェア'**
  String get shareImage;

  /// No description provided for @shareText.
  ///
  /// In ja, this message translates to:
  /// **'テキスト'**
  String get shareText;

  /// No description provided for @cardPersonalBest.
  ///
  /// In ja, this message translates to:
  /// **'自己ベスト！'**
  String get cardPersonalBest;

  /// No description provided for @cardShareButton.
  ///
  /// In ja, this message translates to:
  /// **'この画像をシェア'**
  String get cardShareButton;

  /// No description provided for @cardFooter.
  ///
  /// In ja, this message translates to:
  /// **'App Store で配信中'**
  String get cardFooter;
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
      <String>['en', 'ja', 'ko', 'th', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'th':
      return AppLocalizationsTh();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
