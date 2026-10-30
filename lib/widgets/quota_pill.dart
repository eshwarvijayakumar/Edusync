import 'package:flutter/material.dart';
import '../constants/theme.dart';

class QuotaPill extends StatelessWidget {
  final int remaining;
  final int total;

  const QuotaPill({
    super.key,
    required this.remaining,
    this.total = 10,
  });

  @override
  Widget build(BuildContext context) {
    final isLow = remaining <= 2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isLow ? const Color(0xFFFEF2F2) : EduTheme.primaryIndigoLight,
        borderRadius: BorderRadius.circular(EduTheme.radiusFull),
        border: Border.all(
          color: isLow ? const Color(0xFFFCA5A5) : const Color(0xFFC7D2FE),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLow ? Icons.bolt : Icons.auto_awesome,
            size: 14,
            color: isLow ? EduTheme.errorRed : EduTheme.primaryIndigo,
          ),
          const SizedBox(width: 5),
          Text(
            '$remaining / $total free questions today',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isLow ? EduTheme.errorRed : EduTheme.primaryIndigoDark,
            ),
          ),
        ],
      ),
    );
  }
}
