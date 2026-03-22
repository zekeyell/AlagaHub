import 'package:flutter/material.dart';
import 'package:alagahub/utils/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Tungkol sa App'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const SizedBox(height: 16),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8))
              ],
            ),
            child: const Icon(Icons.local_hospital_rounded,
                color: Colors.white, size: 56),
          ),
          const SizedBox(height: 16),
          const Text('AlagaHub',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          const Text('Healthcare kahit saan',
              style: TextStyle(fontSize: 15, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Version 1.0.0',
                style: TextStyle(
                    color: AppTheme.primaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 32),
          const _InfoCard(children: [
            _AboutRow('Layunin',
                'Nagbibigay ng accessible na healthcare sa mga rural at malalayong komunidad sa Pilipinas.'),
            Divider(height: 1, indent: 16),
            _AboutRow('Platform', 'Android 8.0+ at iOS'),
            Divider(height: 1, indent: 16),
            _AboutRow('Wika', 'Filipino at English'),
            Divider(height: 1, indent: 16),
            _AboutRow('Architecture', 'Offline-first na may cloud sync'),
          ]),
          const SizedBox(height: 16),
          const _InfoCard(children: [
            _AboutRow('SDG 3', 'Good Health & Well-being'),
            Divider(height: 1, indent: 16),
            _AboutRow('SDG 10', 'Reduced Inequalities'),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mga Feature',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                SizedBox(height: 12),
                _FeatureItem(Icons.wifi_off_rounded, 'Gumagana kahit offline'),
                _FeatureItem(
                    Icons.sms_rounded, 'Native SMS — walang dagdag na gastos'),
                _FeatureItem(
                    Icons.sync_rounded, 'Auto-sync kapag may koneksyon'),
                _FeatureItem(
                    Icons.security_rounded, 'Ligtas na pag-iingat ng data'),
                _FeatureItem(
                    Icons.language_rounded, 'Bilingual: Filipino / English'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text('© 2025 AlagaHub. Lahat ng karapatan ay nakalaan.',
              style: TextStyle(fontSize: 12, color: AppTheme.textHint),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('Ginawa para sa mga komunidad ng Pilipinas 🇵🇭',
              style: TextStyle(fontSize: 12, color: AppTheme.textHint),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(children: children),
      );
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;
  const _AboutRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ]),
      );
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureItem(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Icon(icon, color: AppTheme.primary, size: 18),
          const SizedBox(width: 10),
          Text(text,
              style:
                  const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ]),
      );
}
