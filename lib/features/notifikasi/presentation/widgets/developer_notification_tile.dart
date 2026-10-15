import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/notifikasi_model.dart';

class DeveloperNotificationTile extends StatelessWidget {
  const DeveloperNotificationTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  final NotifikasiModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Keep the Pengembang palette local: other roles use the existing model.
    final (color, surface) = switch (item.jenis) {
      JenisNotifikasi.pengajuanBaru || JenisNotifikasi.reminderSurvey => (
        AppColors.statusSurveyText,
        AppColors.statusSurveySurface,
      ),
      JenisNotifikasi.dokumenDiunggahUlang => (
        AppColors.statusWarningText,
        AppColors.statusWarningSurface,
      ),
      JenisNotifikasi.deadlineVerifikasi => (
        AppColors.statusUrgentText,
        AppColors.statusUrgentSurface,
      ),
    };
    final iconColor = item.isRead ? const Color(0xFF64748B) : color;
    final iconSurface = item.isRead ? const Color(0xFFF1F5F9) : surface;

    return Semantics(
      label: item.isRead ? 'Sudah dibaca' : 'Belum dibaca',
      button: true,
      child: Material(
        color: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: item.isRead
                ? const Color(0xFFE2E8F0)
                : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.isRead)
                  Semantics(
                    container: true,
                    label: 'Sudah dibaca',
                    child: const SizedBox.shrink(),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: iconSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.jenis.icon, color: iconColor, size: 19),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.judul,
                                  style: AppTextStyles.titleMedium.copyWith(
                                    fontSize: 14,
                                    fontWeight: item.isRead
                                        ? FontWeight.w600
                                        : FontWeight.w800,
                                    color: item.isRead
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFF0F172A),
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              if (!item.isRead) ...[
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Container(
                                    key: const ValueKey('unread-indicator'),
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryRed,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.deskripsi,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 13,
                              color: const Color(0xFF475569),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('dd/MM/yyyy • HH:mm').format(item.waktu),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
