import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alagahub/utils/app_theme.dart';
import 'package:alagahub/utils/lang.dart';
import 'package:alagahub/widgets/app_bar_widget.dart';
import 'package:alagahub/widgets/reg_progress_bar.dart';
import 'package:alagahub/services/registration_provider.dart';
import 'package:alagahub/screens/auth/registration/reg_review_screen.dart';

class RegStep4Screen extends ConsumerStatefulWidget {
  final String role;
  const RegStep4Screen({super.key, this.role = 'patient'});
  @override
  ConsumerState<RegStep4Screen> createState() => _RegStep4ScreenState();
}

class _RegStep4ScreenState extends ConsumerState<RegStep4Screen> {
  final _philhealth = TextEditingController();
  final _hmoName = TextEditingController();
  final _hmoId = TextEditingController();

  @override
  void initState() {
    super.initState();
    final d = ref.read(registrationProvider);
    _philhealth.text = d.philhealthNumber;
    _hmoName.text = d.hmoName;
    _hmoId.text = d.hmoId;
  }

  @override
  void dispose() { _philhealth.dispose(); _hmoName.dispose(); _hmoId.dispose(); super.dispose(); }

  void _save() {
    ref.read(registrationProvider.notifier).update((d) => d.copyWith(
      philhealthNumber: _philhealth.text.trim(),
      hmoName: _hmoName.text.trim(),
      hmoId: _hmoId.text.trim(),
    ));
  }

  void _next() {
    _save();
    Navigator.push(context, MaterialPageRoute(builder: (_) => RegReviewScreen(role: widget.role)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, 'Create Account'),
      body: Column(children: [
        const RegProgressBar(step: 4, total: 4),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Step 4: Insurance & ID',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('All fields are optional', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 32),
            TextFormField(controller: _philhealth, decoration: const InputDecoration(
                labelText: 'PhilHealth Number',
                prefixIcon: Icon(Icons.credit_card_rounded, color: AppTheme.primary))),
            const SizedBox(height: 16),
            TextFormField(controller: _hmoName,
                decoration: const InputDecoration(labelText: 'HMO / Private Insurance (name)')),
            const SizedBox(height: 16),
            TextFormField(controller: _hmoId,
                decoration: const InputDecoration(labelText: 'HMO ID Number')),
            const SizedBox(height: 32),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () { _save(); Navigator.pop(context); },
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text(S(ref.read(langProvider)).back),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: _next, child: const Text('Review my account →'))),
            ]),
            const SizedBox(height: 24),
          ]),
        )),
      ]),
    );
  }
}
