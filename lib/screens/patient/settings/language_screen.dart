import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alagahub/utils/app_theme.dart';
import 'package:alagahub/utils/lang.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final s = S(lang);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(s.language),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.divider),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppTheme.primaryDark, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(
                s.isEn
                    ? 'Choose your preferred language for the app.'
                    : 'Piliin ang iyong gustong wika para sa app.',
                style: const TextStyle(
                    color: AppTheme.primaryDark, fontSize: 13),
              )),
            ]),
          ),
          const SizedBox(height: 20),

          // English
          _LangTile(
            flag: '\u{1F1FA}\u{1F1F8}',
            label: 'English',
            sublabel: 'English',
            selected: lang == 'en',
            onTap: () => ref.read(langProvider.notifier).setLang('en'),
          ),
          const SizedBox(height: 12),

          // Filipino
          _LangTile(
            flag: '\u{1F1F5}\u{1F1ED}',
            label: 'Filipino',
            sublabel: 'Wikang Filipino',
            selected: lang == 'tl',
            onTap: () => ref.read(langProvider.notifier).setLang('tl'),
          ),
          const SizedBox(height: 28),

          // Live preview toggle
          const Center(child: LangToggle()),
          const SizedBox(height: 12),
          Center(child: Text(
            s.isEn ? 'Currently: English' : 'Kasalukuyan: Filipino',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13),
          )),
        ],
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  final String flag, label, sublabel;
  final bool selected;
  final VoidCallback onTap;
  const _LangTile({required this.flag, required this.label,
      required this.sublabel, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.divider,
            width: selected ? 2 : 1),
        boxShadow: selected ? [BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.1),
            blurRadius: 10, offset: const Offset(0, 3))] : [],
      ),
      child: Row(children: [
        Text(flag, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 14),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 15,
              color: selected ? AppTheme.primary : AppTheme.textPrimary)),
          Text(sublabel, style: const TextStyle(
              fontSize: 12, color: AppTheme.textSecondary)),
        ])),
        if (selected)
          Container(
            width: 26, height: 26,
            decoration: const BoxDecoration(
                color: AppTheme.primary, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded,
                color: Colors.white, size: 16),
          )
        else
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.divider, width: 2)),
          ),
      ]),
    ),
  );
}
