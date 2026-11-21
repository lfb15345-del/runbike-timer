// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'Runbike Timer';

  @override
  String get audioPreparing => 'กำลังเตรียมเสียง...';

  @override
  String get tapToStart => 'แตะเพื่อเริ่ม';

  @override
  String get tapRequiredNote => 'แตะหนึ่งครั้งก่อน เพื่อให้แอปเล่นเสียงได้';

  @override
  String get cannotSwitchTabWhileRecording =>
      'ไม่สามารถสลับแท็บระหว่างบันทึกวิดีโอได้';

  @override
  String get tabMeasure => 'จับเวลา';

  @override
  String get tabPractice => 'ฝึกซ้อม';

  @override
  String get tabAnalysis => 'ผลลัพธ์';

  @override
  String get tabCourse => 'สนาม';

  @override
  String get tabWhistle => 'นกหวีด';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get delete => 'ลบ';

  @override
  String get save => 'บันทึก';

  @override
  String timeSec(String time) {
    return '$time วินาที';
  }

  @override
  String timeSecShort(String time) {
    return '$time วิ';
  }

  @override
  String get notSelected => 'ยังไม่ได้เลือก';

  @override
  String videoSavedToPhotos(String album) {
    return 'บันทึกวิดีโอลงในรูปภาพแล้ว (อัลบั้ม \"$album\")';
  }

  @override
  String get videoSavedInApp => 'บันทึกลงรูปภาพไม่ได้ จึงเก็บวิดีโอไว้ในแอปแทน';

  @override
  String get videoSaveFailed => 'บันทึกวิดีโอไม่สำเร็จ';

  @override
  String get cameraStartFailed => 'เปิดกล้องไม่ได้';

  @override
  String photoAccessDenied(String app) {
    return 'ไม่ได้รับอนุญาตให้เข้าถึงรูปภาพ จึงบันทึกวิดีโอไม่ได้\nไปที่ การตั้งค่า → $app → รูปภาพ แล้วเลือก \"เข้าถึงทั้งหมด\"';
  }

  @override
  String get practiceRunningStopFirst =>
      'กำลังฝึกซ้อมอยู่ กรุณาหยุดก่อนเริ่มจับเวลา';

  @override
  String get cancelled => 'ยกเลิกแล้ว';

  @override
  String get viewRecording => 'ดูวิดีโอ';

  @override
  String get registerChildFirst => 'กรุณาเพิ่มนักปั่นก่อน';

  @override
  String personalBest(String time) {
    return '$time วินาที — สถิติใหม่!';
  }

  @override
  String recordSaved(String time) {
    return 'บันทึก $time วินาทีแล้ว!';
  }

  @override
  String get chooseChild => 'เลือกนักปั่น';

  @override
  String get rename => 'เปลี่ยนชื่อ';

  @override
  String get addNewChild => 'เพิ่มนักปั่นใหม่';

  @override
  String get change => 'เปลี่ยน';

  @override
  String get deleteConfirmTitle => 'ยืนยันการลบ';

  @override
  String deleteChildMessage(String name) {
    return 'ลบ $name หรือไม่?\nจะไม่สามารถดูบันทึกของนักปั่นคนนี้ได้อีก';
  }

  @override
  String get enterChildName => 'ใส่ชื่อนักปั่น';

  @override
  String get childNameHint => 'เช่น น้องเอ';

  @override
  String get add => 'เพิ่ม';

  @override
  String get modeSolo => 'เดี่ยว';

  @override
  String get modeTeam => 'ทีม';

  @override
  String get startSound => 'เสียงปล่อยตัว';

  @override
  String get runBgm => 'เพลงระหว่างปั่น';

  @override
  String get recordVideo => 'บันทึกวิดีโอ';

  @override
  String get recordingNow => 'กำลังบันทึก';

  @override
  String get abort => 'หยุด';

  @override
  String get goal => 'เข้าเส้นชัย!';

  @override
  String teamPlace(int rank, String time) {
    return 'อันดับ $rank  $time วิ';
  }

  @override
  String get nextRace => 'รอบต่อไป';

  @override
  String get btOffset => 'ชดเชย BT';

  @override
  String get soundSilent => 'เงียบ';

  @override
  String get soundBasic => 'พื้นฐาน';

  @override
  String get soundFinal => 'รอบชิง';

  @override
  String get soundSemi => 'รอบรอง';

  @override
  String get bgmNone => 'ไม่มี';

  @override
  String get bgmSpeed => 'สปีด';

  @override
  String get bgmRock => 'ร็อก';

  @override
  String get bgm8bit => '8 บิต';

  @override
  String practiceVideosSaved(int count, String album) {
    return 'บันทึกวิดีโอ $count คลิปลงในรูปภาพแล้ว (อัลบั้ม \"$album\")';
  }

  @override
  String get measureRunningStopFirst =>
      'กำลังจับเวลาอยู่ กรุณาจบก่อนเริ่มฝึกซ้อม';

  @override
  String get intervalPractice => 'ฝึกแบบอินเทอร์วัล';

  @override
  String get total => 'รวม';

  @override
  String get ride => 'ปั่น';

  @override
  String get rest => 'พัก';

  @override
  String get rounds => 'จำนวนรอบ';

  @override
  String get unitSec => 'วิ';

  @override
  String get unitTimes => 'รอบ';

  @override
  String get bgmOff => 'ปิด';

  @override
  String get bgmMetronome => 'เมโทรนอม';

  @override
  String get bgmUpbeat => 'จังหวะเร็ว';

  @override
  String get recordEachRide => 'บันทึกวิดีโอทุกรอบ';

  @override
  String get paused => 'หยุดชั่วคราว';

  @override
  String recordingSavedCount(int count) {
    return 'กำลังบันทึก · บันทึกแล้ว $count';
  }

  @override
  String savedCount(int count) {
    return 'บันทึกแล้ว $count';
  }

  @override
  String get captionReady => 'ออกตัวหลังเสียงสัญญาณ';

  @override
  String get captionLastOne => 'รอบสุดท้าย!';

  @override
  String captionNext(int n) {
    return 'ต่อไป: รอบที่ $n';
  }

  @override
  String captionFinished(int total) {
    return 'ครบ $total รอบแล้ว เก่งมาก!';
  }

  @override
  String get resume => 'ทำต่อ';

  @override
  String get pause => 'หยุดชั่วคราว';

  @override
  String speedRecordFor(String time) {
    return 'ความเร็วของรอบ $time วิ';
  }

  @override
  String get maxSpeedKmh => 'ความเร็วสูงสุด (กม./ชม.)';

  @override
  String get avgSpeedKmh => 'ความเร็วเฉลี่ย (กม./ชม.)';

  @override
  String shareTitle(String name) {
    return 'บันทึกวันนี้ของ $name';
  }

  @override
  String shareLine(int n, String time) {
    return 'รอบที่ $n: $time วิ';
  }

  @override
  String topSpeedValue(String v) {
    return 'สูงสุด $v กม./ชม.';
  }

  @override
  String avgSpeedValue(String v) {
    return 'เฉลี่ย $v กม./ชม.';
  }

  @override
  String get shareBest => '★ดีที่สุด';

  @override
  String get resultsCopied => 'คัดลอกผลแล้ว!';

  @override
  String get selectChild => 'นักปั่น:';

  @override
  String get todayCount => 'รอบวันนี้';

  @override
  String get todayBest => 'ดีที่สุดวันนี้';

  @override
  String get allTimeBest => 'ดีที่สุดตลอดกาล';

  @override
  String get speedRecords => 'สถิติความเร็ว';

  @override
  String get bestTopSpeed => 'ความเร็วสูงสุดตลอดกาล';

  @override
  String get bestAvgSpeed => 'ความเร็วเฉลี่ยดีที่สุด';

  @override
  String get todayRides => 'รอบวันนี้ทั้งหมด';

  @override
  String get tapSwipeHint => 'แตะเพื่อใส่ความเร็ว / ปัดเพื่อลบ';

  @override
  String get noRidesToday => 'วันนี้ยังไม่มีบันทึก';

  @override
  String get deleteRideTitle => 'ลบบันทึก';

  @override
  String deleteRideMessage(String time) {
    return 'ลบบันทึก $time วิ หรือไม่?';
  }

  @override
  String get shareToday => 'แชร์บันทึกวันนี้';

  @override
  String get registerChildInTimer => 'เพิ่มนักปั่นในแท็บจับเวลา';

  @override
  String get courseSaved => 'บันทึกข้อมูลสนามแล้ว';

  @override
  String get courseTitle => 'ตั้งค่าสนาม';

  @override
  String get savedChip => 'บันทึกแล้ว';

  @override
  String get courseIntro => 'ใส่ข้อมูลสนามที่ซ้อมวันนี้ได้ (ไม่บังคับ)';

  @override
  String get courseName => 'ชื่อสนาม';

  @override
  String get courseNameHint => 'เช่น สนามในสวน';

  @override
  String get courseLength => 'ความยาวสนาม (ม.)';

  @override
  String get firstStraight => 'ทางตรงแรก (ม.)';

  @override
  String exampleNumber(int n) {
    return 'เช่น $n';
  }

  @override
  String get curvesLabel => 'จำนวนโค้ง:';

  @override
  String get surfaceLabel => 'พื้นผิว:';

  @override
  String get weatherLabel => 'สภาพอากาศ:';

  @override
  String get surfaceAsphalt => 'ยางมะตอย';

  @override
  String get surfaceGrass => 'หญ้า';

  @override
  String get surfaceIndoor => 'ในร่ม';

  @override
  String get surfaceGravel => 'กรวด';

  @override
  String get surfaceOther => 'อื่น ๆ';

  @override
  String get weatherSunny => 'แดดออก';

  @override
  String get weatherCloudy => 'มีเมฆ';

  @override
  String get weatherRain => 'ฝนตก';

  @override
  String get weatherWindy => 'ลมแรง';

  @override
  String get memo => 'โน้ต';

  @override
  String get memoHint => 'เขียนโน้ตได้ตามสะดวก';

  @override
  String get saveCourse => 'บันทึก';

  @override
  String get pastCourses => 'สนามที่ผ่านมา';

  @override
  String get pastCoursesNote => 'ดูสนามที่บันทึกไว้ตามวันที่';

  @override
  String get todayChip => 'วันนี้';

  @override
  String get noName => '(ไม่มีชื่อ)';

  @override
  String courseLengthShort(String v) {
    return 'ยาว $v ม.';
  }

  @override
  String courseStraightShort(String v) {
    return 'ทางตรง $v ม.';
  }

  @override
  String courseCurvesShort(int n) {
    return '$n โค้ง';
  }

  @override
  String memoValue(String note) {
    return 'โน้ต: $note';
  }

  @override
  String get bgNotificationText => 'กำลังจับเวลาอยู่ (แตะเพื่อกลับ)';

  @override
  String get shareFooter =>
      '#RunbikeTimer #จักรยานขาไถ\nhttps://apps.apple.com/app/id6788356167';

  @override
  String get shareImage => 'แชร์รูปภาพ';

  @override
  String get shareText => 'ข้อความ';

  @override
  String get cardPersonalBest => 'สถิติที่ดีที่สุด!';

  @override
  String get cardShareButton => 'แชร์รูปนี้';

  @override
  String get cardFooter => 'ดาวน์โหลดได้ที่ App Store';
}
