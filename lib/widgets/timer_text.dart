import 'package:flutter/material.dart';

/// タイマー用の数字表示ウィジェット。
/// 1文字ずつ固定幅のマスに入れて描くので、数字が高速で切り替わっても
/// 表示全体が「ぶるぶる震える」ことがない（フォントの数字幅の差を吸収する）。
class TimerText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const TimerText(this.text, {super.key, required this.style});

  @override
  Widget build(BuildContext context) {
    final fontSize = style.fontSize ?? 20;
    // Orbitronの数字はおよそ0.74em幅。記号（. :）は細めのマスにする
    final digitWidth = fontSize * 0.80;
    final symbolWidth = fontSize * 0.38;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final ch in text.split(''))
          SizedBox(
            width: '0123456789'.contains(ch) ? digitWidth : symbolWidth,
            child: Center(
              child: Text(
                ch,
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
                style: style,
              ),
            ),
          ),
      ],
    );
  }
}
