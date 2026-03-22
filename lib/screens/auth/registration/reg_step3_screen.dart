import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alagahub/utils/app_theme.dart';
import 'package:alagahub/utils/lang.dart';
import 'package:alagahub/widgets/app_bar_widget.dart';
import 'package:alagahub/widgets/reg_progress_bar.dart';
import 'package:alagahub/services/registration_provider.dart';
import 'package:alagahub/screens/auth/registration/reg_step4_screen.dart';

class RegStep3Screen extends ConsumerStatefulWidget {
  final String role;
  const RegStep3Screen({super.key, this.role = 'patient'});
  @override
  ConsumerState<RegStep3Screen> createState() => _RegStep3ScreenState();
}

class _RegStep3ScreenState extends ConsumerState<RegStep3Screen> {
  String _bloodType = '';
  List<String> _allergies = [];
  List<String> _conditions = [];
  bool _hasSurgeries = false;
  final _surgeriesCtrl = TextEditingController();
  final _medsCtrl = TextEditingController();
  List<String> _familyHistory = [];
  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();
  final _emergencyRelation = TextEditingController();

  final _bloodTypes = ['A+','A-','B+','B-','AB+','AB-','O+','O-','Unknown'];
  final _allergyOpts   = ['Wala / None','Penicillin','Aspirin','Sulfa','Codeine','NSAIDs','Latex','Food','Others'];
  final _conditionOpts = ['Wala / None','Diabetes','Hypertension','Asthma','Heart Disease','Kidney Disease','Thyroid','Arthritis','Others'];
  final _familyOpts    = ['Wala / None','Diabetes','Hypertension','Cancer','Heart Disease','Stroke','Mental Health','Others'];

  @override
  void initState() {
    super.initState();
    final d = ref.read(registrationProvider);
    _bloodType = d.bloodType;
    _allergies = List.from(d.allergies);
    _conditions = List.from(d.conditions);
    _hasSurgeries = d.hasSurgeries;
    _surgeriesCtrl.text = d.surgeriesDetail;
    _medsCtrl.text = d.currentMedications;
    _familyHistory = List.from(d.familyHistory);
    _emergencyName.text = d.emergencyName;
    _emergencyPhone.text = d.emergencyPhone;
    _emergencyRelation.text = d.emergencyRelation;
  }

  @override
  void dispose() {
    _surgeriesCtrl.dispose(); _medsCtrl.dispose();
    _emergencyName.dispose(); _emergencyPhone.dispose(); _emergencyRelation.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(registrationProvider.notifier).update((d) => d.copyWith(
      bloodType: _bloodType, allergies: _allergies, conditions: _conditions,
      hasSurgeries: _hasSurgeries, surgeriesDetail: _surgeriesCtrl.text,
      currentMedications: _medsCtrl.text, familyHistory: _familyHistory,
      emergencyName: _emergencyName.text.trim(),
      emergencyPhone: _emergencyPhone.text.trim(),
      emergencyRelation: _emergencyRelation.text.trim(),
    ));
  }

  void _next() {
    _save();
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => RegStep4Screen(role: widget.role)));
  }

  Widget _label(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(t, style: const TextStyle(
          fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 14)));

  Widget _multiChips(List<String> opts, List<String> sel) {
    const none = 'Wala / None';
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: opts.map((o) => FilterChip(
        label: Text(o),
        selected: sel.contains(o),
        selectedColor: o == none ? const Color(0xFFE0E7FF) : AppTheme.primaryLight,
        checkmarkColor: o == none ? const Color(0xFF4338CA) : AppTheme.primaryDark,
        labelStyle: TextStyle(
          color: sel.contains(o)
              ? (o == none ? const Color(0xFF4338CA) : AppTheme.primaryDark)
              : AppTheme.textSecondary,
          fontWeight: sel.contains(o) ? FontWeight.w600 : FontWeight.normal,
        ),
        onSelected: (v) => setState(() {
          if (v) {
            if (o == none) { sel.clear(); } else { sel.remove(none); }
            sel.add(o);
          } else {
            sel.remove(o);
          }
        }),
      )).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S(ref.watch(langProvider));
    return Scaffold(
      appBar: buildAppBar(context, s.createAccountTitle),
      body: Column(children: [
        const RegProgressBar(step: 3, total: 4),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.step3Title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),

            _label(s.bloodType),
            Wrap(spacing: 8, runSpacing: 8,
                children: _bloodTypes.map((b) => ChoiceChip(
                  label: Text(b), selected: _bloodType == b,
                  selectedColor: AppTheme.primaryLight,
                  onSelected: (_) => setState(() => _bloodType = b),
                )).toList()),
            const SizedBox(height: 24),

            _label(s.allergies),
            _multiChips(_allergyOpts, _allergies),
            const SizedBox(height: 24),

            _label(s.existingConditions),
            _multiChips(_conditionOpts, _conditions),
            const SizedBox(height: 24),

            Row(children: [
              Text(s.previousSurgeries, style: const TextStyle(fontWeight: FontWeight.w500)),
              const Spacer(),
              Switch(value: _hasSurgeries,
                  onChanged: (v) => setState(() => _hasSurgeries = v),
                  activeThumbColor: AppTheme.primary),
            ]),
            if (_hasSurgeries) ...[
              const SizedBox(height: 8),
              TextFormField(controller: _surgeriesCtrl,
                  decoration: InputDecoration(labelText: s.describeSurgery), maxLines: 2),
            ],
            const SizedBox(height: 16),
            TextFormField(controller: _medsCtrl,
                decoration: InputDecoration(labelText: s.currentMeds), maxLines: 2),
            const SizedBox(height: 24),

            _label(s.familyHistory),
            _multiChips(_familyOpts, _familyHistory),
            const SizedBox(height: 24),

            _label(s.emergencyContact),
            TextFormField(controller: _emergencyName,
                decoration: InputDecoration(labelText: s.fullName),
                textCapitalization: TextCapitalization.words),
            const SizedBox(height: 12),
            TextFormField(controller: _emergencyPhone,
                decoration: InputDecoration(labelText: s.phoneNumber),
                keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            TextFormField(controller: _emergencyRelation,
                decoration: InputDecoration(labelText: s.relationship),
                textCapitalization: TextCapitalization.words),
            const SizedBox(height: 40),

            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () { _save(); Navigator.pop(context); },
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text(s.back),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                  onPressed: _next,
                  child: Text('${s.next} \u2192'))),
            ]),
            const SizedBox(height: 24),
          ]),
        )),
      ]),
    );
  }
}
