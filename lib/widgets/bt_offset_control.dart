import 'package:flutter/material.dart';
import '../services/app_settings.dart';

/// Bluetooth遅延補正の ± コントロール
/// （これまで計測画面と練習画面に同じコードが重複していたのを共通化）
class BtOffsetControl extends StatelessWidget {
  /// false のとき操作不可（計測中など）
  final bool enabled;

  /// 値が変わったとき親画面を再描画させるためのコールバック
  final VoidCallback onChanged;

  const BtOffsetControl({
    super.key,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final offsetMs = AppSettings.bluetoothOffsetMs;
    final isActive = offsetMs > 0;
    final activeColor = isActive ? Colors.blue : Colors.grey;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.bluetooth, size: 18, color: activeColor),
        const SizedBox(width: 4),
        Text('BT補正', style: TextStyle(fontSize: 13, color: activeColor)),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 20,
            onPressed: enabled && offsetMs > 0
                ? () {
                    AppSettings.bluetoothOffsetMs =
                        (offsetMs - AppSettings.btOffsetStep)
                            .clamp(0, AppSettings.btOffsetMax);
                    onChanged();
                  }
                : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
        ),
        Container(
          width: 72,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.blue.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '+${offsetMs}ms',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: activeColor,
            ),
          ),
        ),
        SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 20,
            onPressed: enabled && offsetMs < AppSettings.btOffsetMax
                ? () {
                    AppSettings.bluetoothOffsetMs =
                        (offsetMs + AppSettings.btOffsetStep)
                            .clamp(0, AppSettings.btOffsetMax);
                    onChanged();
                  }
                : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ),
      ],
    );
  }
}
