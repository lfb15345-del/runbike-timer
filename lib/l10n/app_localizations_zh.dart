// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '滑步車計時器';

  @override
  String get audioPreparing => '正在準備音效…';

  @override
  String get tapToStart => '點一下開始';

  @override
  String get tapRequiredNote => '為了播放聲音，請先點一下畫面';

  @override
  String get cannotSwitchTabWhileRecording => '錄影中無法切換分頁';

  @override
  String get tabMeasure => '計時';

  @override
  String get tabPractice => '練習';

  @override
  String get tabAnalysis => '紀錄・分享';

  @override
  String get tabCourse => '賽道';

  @override
  String get tabWhistle => '哨子';

  @override
  String get cancel => '取消';

  @override
  String get delete => '刪除';

  @override
  String get save => '儲存';

  @override
  String timeSec(String time) {
    return '$time 秒';
  }

  @override
  String timeSecShort(String time) {
    return '$time秒';
  }

  @override
  String get notSelected => '未選擇';

  @override
  String videoSavedToPhotos(String album) {
    return '影片已儲存到照片（相簿「$album」）';
  }

  @override
  String get videoSavedInApp => '無法儲存到照片，已先保存在 App 內';

  @override
  String get videoSaveFailed => '影片儲存失敗';

  @override
  String get cameraStartFailed => '無法啟動相機';

  @override
  String photoAccessDenied(String app) {
    return '未允許取用照片，無法儲存影片。\n請到「設定 → $app → 照片」選擇「完整取用權限」';
  }

  @override
  String get practiceRunningStopFirst => '練習正在進行中，請先停止練習再開始';

  @override
  String get cancelled => '已中止';

  @override
  String get viewRecording => '查看錄影';

  @override
  String get registerChildFirst => '請先新增小騎士';

  @override
  String personalBest(String time) {
    return '$time 秒　刷新個人最佳！';
  }

  @override
  String recordSaved(String time) {
    return '已記錄 $time 秒！';
  }

  @override
  String get chooseChild => '選擇小騎士';

  @override
  String get rename => '修改名稱';

  @override
  String get addNewChild => '新增小騎士';

  @override
  String get change => '變更';

  @override
  String get deleteConfirmTitle => '確認刪除';

  @override
  String deleteChildMessage(String name) {
    return '要刪除 $name 嗎？\n紀錄也將無法查看。';
  }

  @override
  String get enterChildName => '輸入小騎士的名字';

  @override
  String get childNameHint => '例：小安';

  @override
  String get add => '新增';

  @override
  String get modeSolo => '個人';

  @override
  String get modeTeam => '團隊';

  @override
  String get startSound => '起跑音效';

  @override
  String get runBgm => '騎乘中音樂';

  @override
  String get recordVideo => '錄影';

  @override
  String get recordingNow => '錄影中';

  @override
  String get abort => '中止';

  @override
  String get goal => '終點！';

  @override
  String teamPlace(int rank, String time) {
    return '第$rank名 $time秒';
  }

  @override
  String get nextRace => '下一場';

  @override
  String get btOffset => '藍牙延遲';

  @override
  String get soundSilent => '無聲';

  @override
  String get soundBasic => '基本';

  @override
  String get soundFinal => '決賽';

  @override
  String get soundSemi => '準決賽';

  @override
  String get bgmNone => '無';

  @override
  String get bgmSpeed => '速度';

  @override
  String get bgmRock => '搖滾';

  @override
  String get bgm8bit => '8位元';

  @override
  String practiceVideosSaved(int count, String album) {
    return '已將 $count 段騎乘影片儲存到照片（相簿「$album」）';
  }

  @override
  String get measureRunningStopFirst => '計時正在進行中，請先結束計時再開始';

  @override
  String get intervalPractice => '間歇訓練';

  @override
  String get total => '合計';

  @override
  String get ride => '騎乘';

  @override
  String get rest => '休息';

  @override
  String get rounds => '次數';

  @override
  String get unitSec => '秒';

  @override
  String get unitTimes => '次';

  @override
  String get bgmOff => '無聲';

  @override
  String get bgmMetronome => '節拍器';

  @override
  String get bgmUpbeat => '輕快';

  @override
  String get recordEachRide => '每次騎乘都錄影';

  @override
  String get paused => '已暫停';

  @override
  String recordingSavedCount(int count) {
    return '錄影中・已存 $count 段';
  }

  @override
  String savedCount(int count) {
    return '已存 $count 段';
  }

  @override
  String get captionReady => '聽到起跑音後出發';

  @override
  String get captionLastOne => '最後一趟！';

  @override
  String captionNext(int n) {
    return '下一趟：第 $n 趟';
  }

  @override
  String captionFinished(int total) {
    return '完成 $total 趟，辛苦了！';
  }

  @override
  String get resume => '繼續';

  @override
  String get pause => '暫停';

  @override
  String speedRecordFor(String time) {
    return '$time秒 的速度紀錄';
  }

  @override
  String get maxSpeedKmh => '最高速度 (km/h)';

  @override
  String get avgSpeedKmh => '平均速度 (km/h)';

  @override
  String shareTitle(String name) {
    return '$name 今天的紀錄';
  }

  @override
  String shareLine(int n, String time) {
    return '第$n趟：$time秒';
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
  String get shareBest => '★最佳';

  @override
  String get resultsCopied => '已複製結果！';

  @override
  String get selectChild => '選擇小騎士：';

  @override
  String get todayCount => '今日次數';

  @override
  String get todayBest => '今日最佳';

  @override
  String get allTimeBest => '歷史最佳';

  @override
  String get speedRecords => '速度紀錄';

  @override
  String get bestTopSpeed => '歷史最高速度';

  @override
  String get bestAvgSpeed => '歷史最佳平均速度';

  @override
  String get todayRides => '今日騎乘紀錄';

  @override
  String get tapSwipeHint => '點一下輸入速度／滑動刪除';

  @override
  String get noRidesToday => '今天還沒有紀錄';

  @override
  String get deleteRideTitle => '刪除紀錄';

  @override
  String deleteRideMessage(String time) {
    return '要刪除 $time秒 的紀錄嗎？';
  }

  @override
  String get shareToday => '分享今日紀錄';

  @override
  String get registerChildInTimer => '請在「計時」分頁新增小騎士';

  @override
  String get courseSaved => '已儲存賽道資訊';

  @override
  String get courseTitle => '賽道設定';

  @override
  String get savedChip => '已儲存';

  @override
  String get courseIntro => '可輸入今天練習賽道的資訊（選填）';

  @override
  String get courseName => '賽道名稱';

  @override
  String get courseNameHint => '例：公園賽道';

  @override
  String get courseLength => '賽道全長（m）';

  @override
  String get firstStraight => '起跑直線長度（m）';

  @override
  String exampleNumber(int n) {
    return '例：$n';
  }

  @override
  String get curvesLabel => '彎道數：';

  @override
  String get surfaceLabel => '路面：';

  @override
  String get weatherLabel => '天氣：';

  @override
  String get surfaceAsphalt => '柏油';

  @override
  String get surfaceGrass => '草地';

  @override
  String get surfaceIndoor => '室內';

  @override
  String get surfaceGravel => '碎石';

  @override
  String get surfaceOther => '其他';

  @override
  String get weatherSunny => '晴天';

  @override
  String get weatherCloudy => '陰天';

  @override
  String get weatherRain => '雨天';

  @override
  String get weatherWindy => '有風';

  @override
  String get memo => '備註';

  @override
  String get memoHint => '可自由填寫備註';

  @override
  String get saveCourse => '儲存';

  @override
  String get pastCourses => '過去的賽道';

  @override
  String get pastCoursesNote => '可依日期查看已儲存的賽道';

  @override
  String get todayChip => '今天';

  @override
  String get noName => '（未命名）';

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
    return '$n個彎道';
  }

  @override
  String memoValue(String note) {
    return '備註：$note';
  }

  @override
  String get bgNotificationText => '計時進行中（點一下返回）';

  @override
  String get shareFooter =>
      '#滑步車計時器 #滑步車\nhttps://apps.apple.com/app/id6788356167';

  @override
  String get shareImage => '分享圖片';

  @override
  String get shareText => '文字';

  @override
  String get cardPersonalBest => '個人最佳！';

  @override
  String get cardShareButton => '分享這張圖片';

  @override
  String get cardFooter => 'App Store 上架中';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appTitle => '滑步車計時器';

  @override
  String get audioPreparing => '正在準備音效…';

  @override
  String get tapToStart => '點一下開始';

  @override
  String get tapRequiredNote => '為了播放聲音，請先點一下畫面';

  @override
  String get cannotSwitchTabWhileRecording => '錄影中無法切換分頁';

  @override
  String get tabMeasure => '計時';

  @override
  String get tabPractice => '練習';

  @override
  String get tabAnalysis => '紀錄・分享';

  @override
  String get tabCourse => '賽道';

  @override
  String get tabWhistle => '哨子';

  @override
  String get cancel => '取消';

  @override
  String get delete => '刪除';

  @override
  String get save => '儲存';

  @override
  String timeSec(String time) {
    return '$time 秒';
  }

  @override
  String timeSecShort(String time) {
    return '$time秒';
  }

  @override
  String get notSelected => '未選擇';

  @override
  String videoSavedToPhotos(String album) {
    return '影片已儲存到照片（相簿「$album」）';
  }

  @override
  String get videoSavedInApp => '無法儲存到照片，已先保存在 App 內';

  @override
  String get videoSaveFailed => '影片儲存失敗';

  @override
  String get cameraStartFailed => '無法啟動相機';

  @override
  String photoAccessDenied(String app) {
    return '未允許取用照片，無法儲存影片。\n請到「設定 → $app → 照片」選擇「完整取用權限」';
  }

  @override
  String get practiceRunningStopFirst => '練習正在進行中，請先停止練習再開始';

  @override
  String get cancelled => '已中止';

  @override
  String get viewRecording => '查看錄影';

  @override
  String get registerChildFirst => '請先新增小騎士';

  @override
  String personalBest(String time) {
    return '$time 秒　刷新個人最佳！';
  }

  @override
  String recordSaved(String time) {
    return '已記錄 $time 秒！';
  }

  @override
  String get chooseChild => '選擇小騎士';

  @override
  String get rename => '修改名稱';

  @override
  String get addNewChild => '新增小騎士';

  @override
  String get change => '變更';

  @override
  String get deleteConfirmTitle => '確認刪除';

  @override
  String deleteChildMessage(String name) {
    return '要刪除 $name 嗎？\n紀錄也將無法查看。';
  }

  @override
  String get enterChildName => '輸入小騎士的名字';

  @override
  String get childNameHint => '例：小安';

  @override
  String get add => '新增';

  @override
  String get modeSolo => '個人';

  @override
  String get modeTeam => '團隊';

  @override
  String get startSound => '起跑音效';

  @override
  String get runBgm => '騎乘中音樂';

  @override
  String get recordVideo => '錄影';

  @override
  String get recordingNow => '錄影中';

  @override
  String get abort => '中止';

  @override
  String get goal => '終點！';

  @override
  String teamPlace(int rank, String time) {
    return '第$rank名 $time秒';
  }

  @override
  String get nextRace => '下一場';

  @override
  String get btOffset => '藍牙延遲';

  @override
  String get soundSilent => '無聲';

  @override
  String get soundBasic => '基本';

  @override
  String get soundFinal => '決賽';

  @override
  String get soundSemi => '準決賽';

  @override
  String get bgmNone => '無';

  @override
  String get bgmSpeed => '速度';

  @override
  String get bgmRock => '搖滾';

  @override
  String get bgm8bit => '8位元';

  @override
  String practiceVideosSaved(int count, String album) {
    return '已將 $count 段騎乘影片儲存到照片（相簿「$album」）';
  }

  @override
  String get measureRunningStopFirst => '計時正在進行中，請先結束計時再開始';

  @override
  String get intervalPractice => '間歇訓練';

  @override
  String get total => '合計';

  @override
  String get ride => '騎乘';

  @override
  String get rest => '休息';

  @override
  String get rounds => '次數';

  @override
  String get unitSec => '秒';

  @override
  String get unitTimes => '次';

  @override
  String get bgmOff => '無聲';

  @override
  String get bgmMetronome => '節拍器';

  @override
  String get bgmUpbeat => '輕快';

  @override
  String get recordEachRide => '每次騎乘都錄影';

  @override
  String get paused => '已暫停';

  @override
  String recordingSavedCount(int count) {
    return '錄影中・已存 $count 段';
  }

  @override
  String savedCount(int count) {
    return '已存 $count 段';
  }

  @override
  String get captionReady => '聽到起跑音後出發';

  @override
  String get captionLastOne => '最後一趟！';

  @override
  String captionNext(int n) {
    return '下一趟：第 $n 趟';
  }

  @override
  String captionFinished(int total) {
    return '完成 $total 趟，辛苦了！';
  }

  @override
  String get resume => '繼續';

  @override
  String get pause => '暫停';

  @override
  String speedRecordFor(String time) {
    return '$time秒 的速度紀錄';
  }

  @override
  String get maxSpeedKmh => '最高速度 (km/h)';

  @override
  String get avgSpeedKmh => '平均速度 (km/h)';

  @override
  String shareTitle(String name) {
    return '$name 今天的紀錄';
  }

  @override
  String shareLine(int n, String time) {
    return '第$n趟：$time秒';
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
  String get shareBest => '★最佳';

  @override
  String get resultsCopied => '已複製結果！';

  @override
  String get selectChild => '選擇小騎士：';

  @override
  String get todayCount => '今日次數';

  @override
  String get todayBest => '今日最佳';

  @override
  String get allTimeBest => '歷史最佳';

  @override
  String get speedRecords => '速度紀錄';

  @override
  String get bestTopSpeed => '歷史最高速度';

  @override
  String get bestAvgSpeed => '歷史最佳平均速度';

  @override
  String get todayRides => '今日騎乘紀錄';

  @override
  String get tapSwipeHint => '點一下輸入速度／滑動刪除';

  @override
  String get noRidesToday => '今天還沒有紀錄';

  @override
  String get deleteRideTitle => '刪除紀錄';

  @override
  String deleteRideMessage(String time) {
    return '要刪除 $time秒 的紀錄嗎？';
  }

  @override
  String get shareToday => '分享今日紀錄';

  @override
  String get registerChildInTimer => '請在「計時」分頁新增小騎士';

  @override
  String get courseSaved => '已儲存賽道資訊';

  @override
  String get courseTitle => '賽道設定';

  @override
  String get savedChip => '已儲存';

  @override
  String get courseIntro => '可輸入今天練習賽道的資訊（選填）';

  @override
  String get courseName => '賽道名稱';

  @override
  String get courseNameHint => '例：公園賽道';

  @override
  String get courseLength => '賽道全長（m）';

  @override
  String get firstStraight => '起跑直線長度（m）';

  @override
  String exampleNumber(int n) {
    return '例：$n';
  }

  @override
  String get curvesLabel => '彎道數：';

  @override
  String get surfaceLabel => '路面：';

  @override
  String get weatherLabel => '天氣：';

  @override
  String get surfaceAsphalt => '柏油';

  @override
  String get surfaceGrass => '草地';

  @override
  String get surfaceIndoor => '室內';

  @override
  String get surfaceGravel => '碎石';

  @override
  String get surfaceOther => '其他';

  @override
  String get weatherSunny => '晴天';

  @override
  String get weatherCloudy => '陰天';

  @override
  String get weatherRain => '雨天';

  @override
  String get weatherWindy => '有風';

  @override
  String get memo => '備註';

  @override
  String get memoHint => '可自由填寫備註';

  @override
  String get saveCourse => '儲存';

  @override
  String get pastCourses => '過去的賽道';

  @override
  String get pastCoursesNote => '可依日期查看已儲存的賽道';

  @override
  String get todayChip => '今天';

  @override
  String get noName => '（未命名）';

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
    return '$n個彎道';
  }

  @override
  String memoValue(String note) {
    return '備註：$note';
  }

  @override
  String get bgNotificationText => '計時進行中（點一下返回）';

  @override
  String get shareFooter =>
      '#滑步車計時器 #滑步車\nhttps://apps.apple.com/app/id6788356167';

  @override
  String get shareImage => '分享圖片';

  @override
  String get shareText => '文字';

  @override
  String get cardPersonalBest => '個人最佳！';

  @override
  String get cardShareButton => '分享這張圖片';

  @override
  String get cardFooter => 'App Store 上架中';
}
