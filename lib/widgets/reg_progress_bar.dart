import 'package:flutter/material.dart';
import 'package:alagahub/utils/app_theme.dart';

class RegProgressBar extends StatelessWidget {
  final int step;
  final int total;
  const RegProgressBar({super.key, required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: List.generate(total, (i) => Expanded(child: Container(
          height: 4,
          margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
          decoration: BoxDecoration(
            color: i < step ? AppTheme.primary : AppTheme.divider,
            borderRadius: BorderRadius.circular(2),
          ),
        )))),
        const SizedBox(height: 6),
        Text('Step $step of $total',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ]),
    );
  }
}
