import 'dart:io';
import 'package:flutter/material.dart';
import 'package:alagahub/services/auth_service.dart';

import 'package:alagahub/screens/auth/login_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:alagahub/utils/app_theme.dart';
import 'package:alagahub/utils/lang.dart';
import 'package:alagahub/screens/patient/settings/notifications_screen.dart';
import 'package:alagahub/screens/patient/settings/language_screen.dart';
import 'package:alagahub/screens/patient/settings/help_screen.dart';
import 'package:alagahub/screens/patient/settings/about_screen.dart';
import 'package:alagahub/widgets/logout_dialog.dart';
import 'package:alagahub/screens/patient/patient_shell.dart';

class AccountTab extends ConsumerStatefulWidget {
  const AccountTab({super.key});
  @override
  ConsumerState<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends ConsumerState<AccountTab> {
  Map<String, String> _prefs = {};
  String? _photoUrl;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _prefs = {
        'name':          p.getString('patient_name')          ?? 'Pasyente',
        'patient_id':    p.getString('patient_id')            ?? '—',
        'barangay':      p.getString('patient_barangay')      ?? '—',
        'city':          p.getString('patient_city')          ?? '—',
        'health_center': p.getString('patient_health_center') ?? '—',
        'blood_type':    p.getString('patient_blood_type')    ?? '—',
        'phone':         p.getString('user_phone')            ?? '—',
        'firebase_uid':  p.getString('firebase_uid')          ?? '',
      };
      _photoUrl = p.getString('profile_photo_url');
    });
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 600, imageQuality: 80);
    if (picked == null) {
      return;
    }
    setState(() => _uploadingPhoto = true);
    try {
      final uid = _prefs['firebase_uid'] ?? '';
      final ref = FirebaseStorage.instance.ref('profile_photos/$uid.jpg');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_photo_url', url);
      try {
        await FirebaseDatabase.instance
            .ref('patients/${_prefs['patient_id']}')
            .update({'photoUrl': url});
      } catch (_) {}
      if (mounted) setState(() { _photoUrl = url; _uploadingPhoto = false; });
    } catch (e) {
      if (mounted) setState(() => _uploadingPhoto = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Photo upload failed. Try again.'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _editProfile() async {
    final s            = S(ref.read(langProvider));
    final nameCtrl     = TextEditingController(text: _prefs['name']);
    final phoneCtrl    = TextEditingController(text: _prefs['phone']);
    final barangayCtrl = TextEditingController(text: _prefs['barangay']);
    final cityCtrl     = TextEditingController(text: _prefs['city']);
    final hcCtrl       = TextEditingController(text: _prefs['health_center']);
    String bloodType   = _prefs['blood_type'] ?? '—';
    const bloodTypes   = ['A+','A-','B+','B-','AB+','AB-','O+','O-','—'];

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Text(s.isEn ? 'Edit Profile' : 'I-edit ang Profile',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              _EditField(ctrl: nameCtrl,
                  label: s.isEn ? 'Full Name' : 'Buong Pangalan',
                  icon: Icons.person_rounded),
              const SizedBox(height: 12),
              _EditField(ctrl: phoneCtrl,
                  label: s.isEn ? 'Phone Number' : 'Numero ng Telepono',
                  icon: Icons.phone_rounded,
                  type: TextInputType.phone),
              const SizedBox(height: 12),
              _EditField(ctrl: barangayCtrl,
                  label: 'Barangay',
                  icon: Icons.location_on_rounded),
              const SizedBox(height: 12),
              _EditField(ctrl: cityCtrl,
                  label: s.isEn ? 'City / Municipality' : 'Lungsod / Bayan',
                  icon: Icons.location_city_rounded),
              const SizedBox(height: 12),
              _EditField(ctrl: hcCtrl,
                  label: s.isEn ? 'Health Center' : 'Health Center',
                  icon: Icons.local_hospital_rounded),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: bloodTypes.contains(bloodType) ? bloodType : '—',
                decoration: InputDecoration(
                  labelText: s.isEn ? 'Blood Type' : 'Uri ng Dugo',
                  prefixIcon: const Icon(Icons.bloodtype_rounded,
                      color: AppTheme.primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppTheme.background,
                ),
                items: bloodTypes
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (v) => setSt(() => bloodType = v ?? '—'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50)),
                child: Text(s.isEn ? 'Save Changes' : 'I-save ang Pagbabago'),
              ),
              const SizedBox(height: 28),
            ]),
          ),
        ),
      ),
    );

    if (saved != true) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('patient_name',         nameCtrl.text.trim());
    await prefs.setString('user_phone',           phoneCtrl.text.trim());
    await prefs.setString('patient_barangay',     barangayCtrl.text.trim());
    await prefs.setString('patient_city',         cityCtrl.text.trim());
    await prefs.setString('patient_health_center', hcCtrl.text.trim());
    await prefs.setString('patient_blood_type',   bloodType);
    try {
      await FirebaseDatabase.instance
          .ref('patients/${_prefs['patient_id']}')
          .update({
        'fullName':     nameCtrl.text.trim(),
        'phone':        phoneCtrl.text.trim(),
        'barangay':     barangayCtrl.text.trim(),
        'city':         cityCtrl.text.trim(),
        'healthCenter': hcCtrl.text.trim(),
        'bloodType':    bloodType,
      });
    } catch (_) {}
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S(ref.read(langProvider)).isEn
            ? 'Profile updated!' : 'Na-update ang profile!'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _logout() async => showLogoutDialog(context, ref);

  Future<void> _deleteAccount() async {
    final s = S(ref.read(langProvider));
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Container(width: 56, height: 56,
              decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.delete_forever_rounded,
                  color: AppTheme.error, size: 28)),
          const SizedBox(height: 16),
          const Text('Delete Account?',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
              s.isEn
                  ? 'This will permanently delete your account and all your data. This cannot be undone.'
                  : 'Permanenteng mabubura ang iyong account at lahat ng datos. Hindi na ito mababawi.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 28),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(bCtx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: Text(s.isEn ? 'Delete Account' : 'Burahin ang Account',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
            )),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(bCtx, false),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: AppTheme.divider),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: Text(s.isEn ? 'Cancel' : 'Kanselahin',
                  style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600, fontSize: 16)),
            )),
        ]),
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final patientId = prefs.getString('patient_id') ?? '';
      final firebaseUid = prefs.getString('firebase_uid') ?? '';
      final db = FirebaseDatabase.instance;

      final futures = <Future>[];
      if (patientId.isNotEmpty) {
        futures.addAll([
          db.ref('patients/$patientId').remove(),
          db.ref('inbox/$patientId').remove(),
          db.ref('presence/$patientId').remove(),
          // Delete all consultations for this patient
          db.ref('consultations').get().then((snap) {
            if (!snap.exists || snap.value == null) return;
            final data = Map<String, dynamic>.from(snap.value as Map);
            data.forEach((key, val) {
              if (val is Map &&
                  ((val['patient_id'] ?? val['patientId'] ?? '')
                      == patientId)) {
                db.ref('consultations/$key').remove();
              }
            });
          }),
          // Delete all medicine requests
          db.ref('medicineRequests').get().then((snap) {
            if (!snap.exists || snap.value == null) return;
            final data = Map<String, dynamic>.from(snap.value as Map);
            data.forEach((key, val) {
              if (val is Map &&
                  ((val['patient_id'] ?? val['patientId'] ?? '')
                      == patientId)) {
                db.ref('medicineRequests/$key').remove();
              }
            });
          }),
          // Delete all conversations
          db.ref('conversations').get().then((snap) {
            if (!snap.exists || snap.value == null) return;
            final data = Map<String, dynamic>.from(snap.value as Map);
            data.forEach((key, val) {
              if (val is Map &&
                  (val['patientId'] ?? '') == patientId) {
                db.ref('conversations/$key').remove();
              }
            });
          }),
        ]);
      }
      if (firebaseUid.isNotEmpty) {
        futures.addAll([
          db.ref('users/$firebaseUid').remove(),
          db.ref('inbox/$firebaseUid').remove(),
          db.ref('presence/$firebaseUid').remove(),
        ]);
      }
      await Future.wait(futures);
      await FirebaseAuth.instance.currentUser?.delete();
    } catch (e) {
      debugPrint('Delete account error: $e');
    }

    final authService = ref.read(authServiceProvider);
    await authService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s       = S(ref.watch(langProvider));
    final name    = _prefs['name'] ?? 'P';
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          backgroundColor: AppTheme.primary,
          expandedHeight: 270,
          pinned: true,
          surfaceTintColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              tooltip: s.isEn ? 'Edit Profile' : 'I-edit',
              onPressed: _editProfile,
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: _pickAndUploadPhoto,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 88, height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 3),
                                color: Colors.white
                                    .withValues(alpha: 0.2),
                              ),
                              child: ClipOval(
                                child: _uploadingPhoto
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : _photoUrl != null
                                        ? CachedNetworkImage(
                                            imageUrl: _photoUrl!,
                                            fit: BoxFit.cover)
                                        : Center(
                                            child: Text(initials,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 30,
                                                    fontWeight:
                                                        FontWeight.w700))),
                              ),
                            ),
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppTheme.primary,
                                    width: 2),
                              ),
                              child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 14,
                                  color: AppTheme.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(_prefs['patient_id'] ?? '—',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12,
                              fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        SliverList(delegate: SliverChildListDelegate([
          const SizedBox(height: 20),

          _SectionHeader(
              s.isEn ? 'Health Info' : 'Impormasyon sa Kalusugan'),
          _Card(children: [
            _InfoRow(Icons.bloodtype_rounded,
                s.uriNgDugo, _prefs['blood_type'] ?? '—'),
            const Divider(height: 1, indent: 50),
            _InfoRow(Icons.phone_rounded,
                s.isEn ? 'Phone' : 'Telepono',
                _prefs['phone'] ?? '—'),
            const Divider(height: 1, indent: 50),
            _InfoRow(Icons.location_on_rounded,
                s.barangay, _prefs['barangay'] ?? '—'),
            const Divider(height: 1, indent: 50),
            _InfoRow(Icons.location_city_rounded,
                s.isEn ? 'City' : 'Lungsod',
                _prefs['city'] ?? '—'),
            const Divider(height: 1, indent: 50),
            _InfoRow(Icons.local_hospital_rounded,
                s.healthCenter,
                _prefs['health_center'] ?? '—',
                maxLines: 2),
          ]),
          const SizedBox(height: 16),

          _SectionHeader(s.mgaRekord),
          _Card(children: [
            _NavTile(Icons.calendar_month_rounded, s.mgaKonsultasyon,
                AppTheme.primary, () {
              ref.read(patientTabIndexProvider.notifier).state =
                  kTabConsultation;
            }),
            const Divider(height: 1, indent: 56),
            _NavTile(Icons.medication_rounded, s.mgaGamot,
                AppTheme.accent, () {
              ref.read(patientTabIndexProvider.notifier).state =
                  kTabMedicine;
            }),
          ]),
          const SizedBox(height: 16),

          _SectionHeader(s.mgaSetting),
          _Card(children: [
            _NavTile(Icons.notifications_rounded, s.mgaNotipikasyon,
                AppTheme.primary, () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen()))),
            const Divider(height: 1, indent: 56),
            _NavTile(Icons.language_rounded, s.language,
                const Color(0xFF2563EB), () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const LanguageScreen()))),
            const Divider(height: 1, indent: 56),
            _NavTile(Icons.help_outline_rounded, s.helpSupport,
                const Color(0xFF059669), () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const HelpScreen()))),
            const Divider(height: 1, indent: 56),
            _NavTile(Icons.info_outline_rounded, s.aboutApp,
                AppTheme.textSecondary, () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const AboutScreen()))),
          ]),
          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
              label: Text(s.logout),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: _deleteAccount,
              icon: const Icon(Icons.delete_forever_rounded,
                  color: AppTheme.error),
              label: const Text('Delete Account',
                  style: TextStyle(color: AppTheme.error)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.error),
                  minimumSize: const Size(double.infinity, 48)),
            ),
          ),
          const SizedBox(height: 40),
        ])),
      ]),
    );
  }
}

// ── Shared helper widgets ──────────────────────────────────────────────────

class _EditField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType type;
  const _EditField({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.type = TextInputType.text,
  });
  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: type,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: AppTheme.background,
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
    child: Text(title,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
            letterSpacing: 0.8)),
  );
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2))
      ],
    ),
    child: Column(children: children),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final int maxLines;
  const _InfoRow(this.icon, this.label, this.value, {this.maxLines = 1});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    child: Row(children: [
      Icon(icon, color: AppTheme.primary, size: 20),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    ]),
  );
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _NavTile(this.icon, this.label, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 20),
    ),
    title: Text(label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
    trailing: const Icon(Icons.chevron_right_rounded,
        color: AppTheme.textHint, size: 20),
    dense: true,
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
  );
}
