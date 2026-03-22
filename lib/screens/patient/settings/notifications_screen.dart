import 'package:flutter/material.dart';
import 'package:alagahub/utils/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _pushEnabled = true;
  bool _smsEnabled = true;
  bool _consultationReminders = true;
  bool _medicineUpdates = true;
  bool _healthTips = false;
  bool _announcements = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Mga Notipikasyon'),
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
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionLabel('Paraan ng Notipikasyon'),
          _SettingSwitch(
            icon: Icons.notifications_rounded,
            iconColor: AppTheme.primary,
            title: 'Push Notifications',
            subtitle: 'Makatanggap ng alerto sa iyong telepono',
            value: _pushEnabled,
            onChanged: (v) => setState(() => _pushEnabled = v),
          ),
          _SettingSwitch(
            icon: Icons.sms_rounded,
            iconColor: const Color(0xFF2563EB),
            title: 'SMS Notifications',
            subtitle: 'Makatanggap ng alerto via text message',
            value: _smsEnabled,
            onChanged: (v) => setState(() => _smsEnabled = v),
          ),
          const SizedBox(height: 16),
          const _SectionLabel('Uri ng Notipikasyon'),
          _SettingSwitch(
            icon: Icons.calendar_month_rounded,
            iconColor: AppTheme.accent,
            title: 'Mga Paalala sa Konsultasyon',
            subtitle: 'Alerto bago ang iyong appointment',
            value: _consultationReminders,
            onChanged: (v) => setState(() => _consultationReminders = v),
          ),
          _SettingSwitch(
            icon: Icons.medication_rounded,
            iconColor: const Color(0xFF7C3AED),
            title: 'Mga Update sa Gamot',
            subtitle: 'Status ng iyong mga hiling na gamot',
            value: _medicineUpdates,
            onChanged: (v) => setState(() => _medicineUpdates = v),
          ),
          _SettingSwitch(
            icon: Icons.tips_and_updates_rounded,
            iconColor: AppTheme.primary,
            title: 'Health Tips',
            subtitle: 'Bagong mga tip para sa kalusugan',
            value: _healthTips,
            onChanged: (v) => setState(() => _healthTips = v),
          ),
          _SettingSwitch(
            icon: Icons.campaign_rounded,
            iconColor: const Color(0xFF059669),
            title: 'Mga Anunsyo',
            subtitle: 'Balita mula sa iyong health center',
            value: _announcements,
            onChanged: (v) => setState(() => _announcements = v),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4, left: 4),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 0.8)),
      );
}

class _SettingSwitch extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SettingSwitch(
      {required this.icon,
      required this.iconColor,
      required this.title,
      required this.subtitle,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
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
        child: ListTile(
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle,
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          trailing: Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primary,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
      );
}
