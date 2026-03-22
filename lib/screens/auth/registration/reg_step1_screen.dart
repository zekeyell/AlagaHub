import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:alagahub/utils/app_theme.dart';
import 'package:alagahub/utils/lang.dart';
import 'package:alagahub/widgets/app_bar_widget.dart';
import 'package:alagahub/widgets/reg_progress_bar.dart';
import 'package:alagahub/services/registration_provider.dart';
import 'package:alagahub/screens/auth/registration/reg_step2_screen.dart';

class RegStep1Screen extends ConsumerStatefulWidget {
  final String role;
  const RegStep1Screen({super.key, this.role = 'patient'});
  @override
  ConsumerState<RegStep1Screen> createState() => _RegStep1ScreenState();
}

class _RegStep1ScreenState extends ConsumerState<RegStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName, _middleName, _lastName;
  String _sex = '';
  String _civilStatus = '';
  DateTime? _birthdate;

  final _sexOptions = ['Male', 'Female', 'Other'];
  final _civilStatusOptions = ['Single', 'Married', 'Widowed', 'Separated'];

  @override
  void initState() {
    super.initState();
    // Always reset registration data when starting a new registration
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(registrationProvider.notifier).reset();
    });
    // Start with empty controllers for a fresh form
    _firstName  = TextEditingController();
    _middleName = TextEditingController();
    _lastName   = TextEditingController();
    _sex = '';
    _civilStatus = '';
    _birthdate = null;
  }

  @override
  void dispose() {
    _firstName.dispose(); _middleName.dispose(); _lastName.dispose();
    super.dispose();
  }

  void _next() {
    final s = S(ref.read(langProvider));
    if (!_formKey.currentState!.validate()) return;
    if (_sex.isEmpty) { _showError(s.selectSex); return; }
    if (_birthdate == null) { _showError(s.selectBirthdate); return; }
    ref.read(registrationProvider.notifier).update((d) => d.copyWith(
      firstName: _firstName.text.trim(),
      middleName: _middleName.text.trim(),
      lastName: _lastName.text.trim(),
      sex: _sex, civilStatus: _civilStatus, birthdate: _birthdate,
    ));
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => RegStep2Screen(role: widget.role)));
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error));

  Future<void> _pickBirthdate() async {
    final s = S(ref.read(langProvider));
    DateTime tempDate = _birthdate ?? DateTime(1990, 1, 1);
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.divider))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(s.cancel,
                      style: const TextStyle(color: AppTheme.textSecondary))),
              Text(s.dateOfBirth,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              TextButton(
                  onPressed: () {
                    setState(() => _birthdate = tempDate);
                    Navigator.pop(ctx);
                  },
                  child: Text(s.done,
                      style: const TextStyle(
                          color: AppTheme.primary, fontWeight: FontWeight.w700))),
            ]),
          ),
          SizedBox(height: 200,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: tempDate,
                minimumDate: DateTime(1900),
                maximumDate: DateTime.now(),
                onDateTimeChanged: (d) => tempDate = d,
              )),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S(ref.watch(langProvider));
    return Scaffold(
      appBar: buildAppBar(context, s.createAccountTitle),
      body: Column(children: [
        const RegProgressBar(step: 1, total: 4),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(key: _formKey, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.step1Title, style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 24),
              _buildField(_firstName, '${s.firstName} *', required: true),
              const SizedBox(height: 16),
              _buildField(_middleName, s.middleName),
              const SizedBox(height: 16),
              _buildField(_lastName, '${s.lastName} *', required: true),
              const SizedBox(height: 16),

              // Date picker — no icon, just a clean tap target
              GestureDetector(
                onTap: _pickBirthdate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppTheme.divider),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${s.dateOfBirth} *',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        _birthdate != null
                            ? DateFormat('MMMM d, yyyy').format(_birthdate!)
                            : s.pickDate,
                        style: TextStyle(fontSize: 15,
                            color: _birthdate != null ? AppTheme.textPrimary : AppTheme.textHint,
                            fontWeight: FontWeight.w500),
                      ),
                    ])),
                    const Icon(Icons.expand_more_rounded, color: AppTheme.textSecondary),
                  ]),
                ),
              ),
              const SizedBox(height: 16),

              Text('${s.sexGender} *',
                  style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: _sexOptions.map((sx) => ChoiceChip(
                label: Text(sx), selected: _sex == sx,
                selectedColor: AppTheme.primaryLight,
                labelStyle: TextStyle(
                    color: _sex == sx ? AppTheme.primaryDark : AppTheme.textSecondary,
                    fontWeight: FontWeight.w500),
                onSelected: (_) => setState(() => _sex = sx),
              )).toList()),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _civilStatus.isEmpty ? null : _civilStatus,
                decoration: InputDecoration(labelText: s.civilStatus),
                items: _civilStatusOptions.map((cs) =>
                    DropdownMenuItem(value: cs, child: Text(cs))).toList(),
                onChanged: (v) => setState(() => _civilStatus = v ?? ''),
              ),
              const SizedBox(height: 40),
              ElevatedButton(onPressed: _next,
                  child: Text('${s.next} →')),
              const SizedBox(height: 24),
            ],
          )),
        )),
      ]),
    );
  }

  Widget _buildField(TextEditingController c, String label, {bool required = false}) =>
      TextFormField(
        controller: c,
        decoration: InputDecoration(labelText: label),
        validator: required ? (v) => (v?.isEmpty ?? true) ? S(ref.read(langProvider)).required : null : null,
        textCapitalization: TextCapitalization.words,
      );
}
