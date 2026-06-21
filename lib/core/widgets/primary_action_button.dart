import 'package:flutter/material.dart';

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon = Icons.arrow_forward_rounded,
    this.isLoading = false,
    this.expand = true,
    this.color = kPrimaryActionColor,
    this.borderRadius = 24,
    this.height = 64,
    this.fontSize = 22,
    this.iconSize = 24,
  });

  /// Text shown in the center of the button.
  final String label;

  /// Tapped callback. When null (or [isLoading] is true) the button is disabled.
  final VoidCallback? onPressed;

  /// Icon rendered after the label. Pass null to hide it.
  final IconData? trailingIcon;

  /// Replaces the content with a spinner and disables interaction.
  final bool isLoading;

  /// Stretches the button to the full available width when true.
  final bool expand;

  /// Background color of the button.
  final Color color;

  /// Corner radius of the button.
  final double borderRadius;

  /// Fixed height of the button.
  final double height;

  /// Font size of the label.
  final double fontSize;

  /// Size of the trailing icon.
  final double iconSize;

  static const Color kPrimaryActionColor = Color(0xFFFF6A00);

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null && !isLoading;
    final radius = BorderRadius.circular(borderRadius);

    final button = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: isEnabled ? color : color.withValues(alpha: 0.5),
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: isEnabled ? onPressed : null,
          child: SizedBox(
            height: height,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (trailingIcon != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            trailingIcon,
                            color: Colors.white,
                            size: iconSize,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
