import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class StepperHeader extends StatelessWidget {
  final int currentStep; // 1 to 5
  final List<String> stepTitles;

  static const List<String> defaultTitles = [
    'Data PT',
    'Berkas PT',
    'Perumahan',
    'Teknis',
    'Review',
  ];

  const StepperHeader({
    super.key,
    required this.currentStep,
    this.stepTitles = defaultTitles,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(stepTitles.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Line separator aligned with circle centers
            final lineIndex = index ~/ 2;
            final isPassed = lineIndex + 1 < currentStep;
            return Expanded(
              child: Container(
                height: 32,
                alignment: Alignment.center,
                child: Container(
                  height: 2.5,
                  color: isPassed ? AppColors.statusSuccess : AppColors.grey300,
                ),
              ),
            );
          } else {
            // Step bubble
            final stepIndex = index ~/ 2;
            final stepNum = stepIndex + 1;
            final isActive = stepNum == currentStep;
            final isPassed = stepNum < currentStep;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isPassed
                        ? AppColors.statusSuccess
                        : isActive
                        ? AppColors.primaryRed
                        : AppColors.grey200,
                    shape: BoxShape.circle,
                    boxShadow: isActive
                        ? const [
                            BoxShadow(
                              color: Color(0xFFFEE2E2),
                              spreadRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: isPassed
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          '$stepNum',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: isActive || isPassed
                                ? Colors.white
                                : AppColors.grey600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 5),
                SizedBox(
                  width: 52,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      stepTitles[stepIndex],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 10.5,
                        color: isPassed
                            ? AppColors.statusSuccess
                            : isActive
                            ? AppColors.primaryRed
                            : AppColors.grey600,
                        fontWeight: (isActive || isPassed)
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        }),
      ),
    );
  }
}
