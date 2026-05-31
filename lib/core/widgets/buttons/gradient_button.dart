import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final double? width;
  final Widget? icon;

  const GradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.width,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: (onTap == null || isLoading)
                ? AppColors.lime.withValues(alpha: 0.5)
                : AppColors.lime,
            borderRadius: BorderRadius.circular(28),
            boxShadow: (onTap == null || isLoading) ? [] : [
              BoxShadow(
                color: AppColors.lime.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[icon!, const SizedBox(width: 8)],
                      Text(label,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.01,
                          )),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
