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

/// 1行の切り替えボタンの選択肢（key = 保存用の値、label = 画面に出す文字）
class SegmentOption {
  final String key;
  final String label;
  final IconData? icon;
  const SegmentOption(this.key, this.label, {this.icon});
}

/// 選択肢を「1行」に等分して並べる切り替えボタン（折り返さない）。
/// 文字が長い言語（タイ語など）でも、自動で少し小さくして必ず1行に収める。
class SegmentedPills extends StatelessWidget {
  final List<SegmentOption> options;
  final String selectedKey;

  /// null のとき操作不可（薄く表示）
  final ValueChanged<String>? onChanged;

  /// true で一回り小さくする
  final bool compact;

  const SegmentedPills({
    super.key,
    required this.options,
    required this.selectedKey,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final height = compact ? 34.0 : 42.0;
    return Opacity(
      opacity: onChanged == null ? 0.45 : 1,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppTheme.line, width: 1.5),
        ),
        child: Row(
          children: options.map((option) {
            final selected = option.key == selectedKey;
            final foreground = selected ? Colors.white : AppTheme.ink;
            return Expanded(
              child: GestureDetector(
                onTap: onChanged == null ? null : () => onChanged!(option.key),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOut,
                  height: height,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.ink : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  // 長い文字は自動で縮めて1行に収める
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (option.icon != null) ...[
                          Icon(option.icon,
                              size: compact ? 14 : 16,
                              color: selected ? AppTheme.volt : AppTheme.muted),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          option.label,
                          maxLines: 1,
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
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
