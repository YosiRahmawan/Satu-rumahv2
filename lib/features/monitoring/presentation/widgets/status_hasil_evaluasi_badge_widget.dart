import 'package:flutter/material.dart';
import '../../data/models/status_hasil_evaluasi.dart';

class StatusHasilEvaluasiBadgeWidget extends StatelessWidget {
  final StatusHasilEvaluasi status;
  final bool isCompact;
  final bool showIcon;

  const StatusHasilEvaluasiBadgeWidget({
    super.key,
    required this.status,
    this.isCompact = false,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8.5 : 10,
        vertical: isCompact ? 3.5 : 5,
      ),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(status.icon, size: isCompact ? 12 : 14, color: status.color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              status.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isCompact ? 10.5 : 12,
                fontWeight: FontWeight.w700,
                color: status.color,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
