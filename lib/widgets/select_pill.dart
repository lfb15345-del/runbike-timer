import 'package:flutter/material.dart';
import '../theme.dart';

/// 選択ボタン（スタート音・BGM・個人/チームなどの「どれか1つ選ぶ」用）。
/// 選択中は墨色ベタに白文字、未選択は白地に枠線。
class SelectPill extends StatelessWidget {
  final String label;
  final bool selected;

  /// null のとき操作不可（薄く表示）
  final VoidCallback? onTap;
  final IconData? icon;

  /// true で一回り小さくする
  final bool compact;

  const SelectPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AppTheme.ink;
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 7 : 10,
          ),
          decoration: BoxDecoration(
            color: selected ? AppTheme.ink : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppTheme.ink : AppTheme.line,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: compact ? 14 : 16,
                    color: selected ? AppTheme.volt : AppTheme.muted),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.bold,
                  color: foreground,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
