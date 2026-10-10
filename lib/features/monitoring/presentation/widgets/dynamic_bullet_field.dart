import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class DynamicBulletField extends StatefulWidget {
  final String label;
  final List<String> items;
  final ValueChanged<List<String>> onItemsChanged;
  final String placeholderText;
  final Color accentColor;

  const DynamicBulletField({
    super.key,
    required this.label,
    required this.items,
    required this.onItemsChanged,
    this.placeholderText = 'Masukkan poin...',
    this.accentColor = AppColors.enterprisePrimary,
  });

  @override
  State<DynamicBulletField> createState() => _DynamicBulletFieldState();
}

class _DynamicBulletFieldState extends State<DynamicBulletField> {
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final list = widget.items.isEmpty ? [''] : widget.items;
    _controllers = list
        .map((item) => TextEditingController(text: item))
        .toList();
  }

  @override
  void didUpdateWidget(covariant DynamicBulletField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final list = widget.items.isEmpty ? [''] : widget.items;
    if (list.length != _controllers.length) {
      for (final controller in _controllers) {
        controller.dispose();
      }
      _controllers = list
          .map((item) => TextEditingController(text: item))
          .toList();
      return;
    }
    for (var i = 0; i < list.length; i++) {
      if (_controllers[i].text != list[i]) {
        _controllers[i].text = list[i];
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _notifyParent() {
    widget.onItemsChanged(
      _controllers.map((controller) => controller.text).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(
            widget.label,
            style: AppTextStyles.labelMedium.copyWith(
              fontFamily: AppTextStyles.enterpriseFontFamily,
              color: AppColors.enterpriseTextMain,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        ..._controllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          final hasText = controller.text.trim().isNotEmpty;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.only(left: 12, right: 4),
              decoration: BoxDecoration(
                color: AppColors.enterpriseCanvas,
                border: Border.all(color: AppColors.enterpriseBorder),
                borderRadius: AppRadii.small,
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasText
                          ? widget.accentColor
                          : AppColors.enterpriseBorder,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      minLines: 1,
                      maxLines: null,
                      onChanged: (_) {
                        setState(() {});
                        _notifyParent();
                      },
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontFamily: AppTextStyles.enterpriseFontFamily,
                        color: AppColors.enterpriseTextMain,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.placeholderText,
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          fontFamily: AppTextStyles.enterpriseFontFamily,
                          color: AppColors.enterpriseTextMuted,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_controllers.length > 1)
                    IconButton(
                      tooltip: 'Hapus poin',
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.enterpriseTextMuted,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          if (_controllers.length == 1) {
                            _controllers[index].clear();
                          } else {
                            _controllers[index].dispose();
                            _controllers.removeAt(index);
                          }
                        });
                        _notifyParent();
                      },
                    ),
                ],
              ),
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _controllers.add(TextEditingController());
              });
              _notifyParent();
            },
            icon: const Icon(
              Icons.add_circle_outline,
              size: 18,
              color: AppColors.enterprisePrimary,
            ),
            label: Text(
              '+ Tambah poin',
              style: AppTextStyles.labelMedium.copyWith(
                fontFamily: AppTextStyles.enterpriseFontFamily,
                color: AppColors.enterprisePrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
