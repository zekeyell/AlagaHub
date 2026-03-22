import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Provider ─────────────────────────────────────────────────────────────────
final langProvider = StateNotifierProvider<LangNotifier, String>((ref) {
  return LangNotifier();
});

class LangNotifier extends StateNotifier<String> {
  LangNotifier() : super('en') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('app_lang') ?? 'en';
  }

  Future<void> setLang(String lang) async {
    state = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', lang);
  }
}

// ── Strings ───────────────────────────────────────────────────────────────────
class S {
  final String lang;
  const S(this.lang);

  bool get isEn => lang == 'en';

  // General
  String get appName => 'AlagaHub';
  String get cancel => isEn ? 'Cancel' : 'Kanselahin';
  String get confirm => isEn ? 'Confirm' : 'Kumpirmahin';
  String get save => isEn ? 'Save' : 'I-save';
  String get next => isEn ? 'Next' : 'Susunod';
  String get back => isEn ? 'Back' : 'Bumalik';
  String get done => isEn ? 'Done' : 'Tapos na';
  String get loading => isEn ? 'Loading...' : 'Naglo-load...';
  String get error => isEn ? 'Error' : 'Error';
  String get logout => isEn ? 'Logout' : 'Mag-logout';
  String get logoutConfirm => isEn ? 'Are you sure you want to logout?' : 'Sigurado ka bang gusto mong mag-logout?';
  String get no => isEn ? 'No' : 'Hindi';
  String get yes => isEn ? 'Yes' : 'Oo';
  String get search => isEn ? 'Search' : 'Maghanap';
  String get none => isEn ? 'None' : 'Wala';
  String get required => isEn ? 'Required' : 'Kailangan';
  String get optional => isEn ? 'Optional' : 'Opsyonal';
  String get viewAll => isEn ? 'View all' : 'Tingnan lahat';
  String get noData => isEn ? 'No data yet' : 'Walang data pa';
  String get language => isEn ? 'Language' : 'Wika';

  // Login screen
  String get welcomeBack => isEn ? 'Welcome back!' : 'Maligayang pagbabalik!';
  String get getStarted => isEn ? 'Get started' : 'Magsimula';
  String get loginSubtitle => isEn ? 'Login or create an account to continue.' : 'Mag-login o lumikha ng account para magpatuloy.';
  String get login => isEn ? 'Login' : 'Mag-login';
  String get createAccount => isEn ? 'Create Account' : 'Lumikha ng Account';
  String get loginAs => isEn ? 'Login as...' : 'Mag-login bilang...';
  String get registerAs => isEn ? 'Create Account as...' : 'Lumikha ng Account bilang...';
  String get chooseRole => isEn ? 'Choose your role.' : 'Piliin ang iyong tungkulin.';
  String get proceed => isEn ? 'Proceed' : 'Magpatuloy';
  String get demoAccess => isEn ? 'Demo Access' : 'Demo Access';
  String get forTestingOnly => isEn ? 'For testing only' : 'Para sa testing lamang';
  String get tagline => isEn ? 'Healthcare anywhere' : 'Healthcare kahit saan';

  // Roles
  String get patient => isEn ? 'Patient' : 'Pasyente';
  String get worker => isEn ? 'Healthcare Worker' : 'Healthcare Worker';
  String get admin => isEn ? 'Admin' : 'Admin';
  String get patientSubtitle => isEn ? 'Access your health records and services' : 'I-access ang iyong health records at serbisyo';
  String get workerSubtitle => isEn ? 'Manage patients and consultations' : 'Pamahalaan ang mga pasyente at konsultasyon';

  // Phone entry
  String get enterMobile => isEn ? 'Enter your mobile number' : 'Ilagay ang iyong numero';
  String get sendOtp => isEn ? 'Send OTP' : 'Magpadala ng OTP';
  String get sending => isEn ? 'Sending...' : 'Nagpapadala...';
  String get phoneHint => isEn ? 'We will send a verification code to your number.' : 'Magpapadala kami ng verification code sa iyong numero.';
  String get phoneExample => isEn ? 'Enter your number without the leading 0. Example: 9123456789' : 'Ilagay ang numero nang walang 0 sa simula. Halimbawa: 9123456789';

  // OTP
  String get verifyNumber => isEn ? 'Verify your number' : 'I-verify ang iyong numero';
  String get verifying => isEn ? 'Verifying...' : 'Sine-check...';
  String get verify => isEn ? 'Verify' : 'I-verify';
  String get resendOtp => isEn ? 'Resend OTP' : 'I-resend ang OTP';
  String resendIn(int s) => isEn ? 'Resend code in ${s}s' : 'I-resend ang code in ${s}s';
  String otpSentTo(String phone) => isEn
      ? 'We sent a 6-digit code to\n$phone'
      : 'Nagpadala kami ng 6-digit na code sa\n$phone';
  String get wrongCode => isEn ? 'Incorrect code. Please try again.' : 'Maling code. Subukan muli.';
  String get noAccountError => isEn
      ? 'No account found for this number. Please create an account first.'
      : 'Walang account ang numerong ito. Mangyaring lumikha ng account muna.';
  String get alreadyRegisteredError => isEn
      ? 'This number already has an account. Please login instead.'
      : 'Ang numerong ito ay mayroon nang account. Mangyaring mag-login na lang.';
  String get newOtpSent => isEn ? 'New OTP sent!' : 'Bagong OTP na ipinadala!';

  // Registration
  String get createAccountTitle => isEn ? 'Create Account' : 'Lumikha ng Account';
  String get step1Title => isEn ? 'Step 1: Personal Information' : 'Hakbang 1: Personal na Impormasyon';
  String get step2Title => isEn ? 'Step 2: Address' : 'Hakbang 2: Tirahan';
  String get step3Title => isEn ? 'Step 3: Health Profile' : 'Hakbang 3: Health Profile';
  String get step4Title => isEn ? 'Step 4: Insurance & ID' : 'Hakbang 4: Insurance at ID';
  String get allOptional => isEn ? 'All fields are optional' : 'Lahat ng field ay opsyonal';
  String get reviewTitle => isEn ? 'Review your account' : 'Suriin ang iyong account';
  String get firstName => isEn ? 'First Name' : 'Unang Pangalan';
  String get middleName => isEn ? 'Middle Name' : 'Gitnang Pangalan';
  String get lastName => isEn ? 'Last Name' : 'Apelyido';
  String get dateOfBirth => isEn ? 'Date of Birth' : 'Petsa ng Kapanganakan';
  String get pickDate => isEn ? 'Pick a date' : 'Pumili ng petsa';
  String get sexGender => isEn ? 'Sex / Gender' : 'Kasarian';
  String get civilStatus => isEn ? 'Civil Status' : 'Katayuang Sibil';
  String get houseStreet => isEn ? 'House / Street' : 'Bahay / Kalye';
  String get barangay => isEn ? 'Barangay' : 'Barangay';
  String get cityMunicipality => isEn ? 'City / Municipality' : 'Lungsod / Munisipyo';
  String get province => isEn ? 'Province' : 'Lalawigan';
  String get region => isEn ? 'Region' : 'Rehiyon';
  String get bloodType => isEn ? 'Blood Type' : 'Uri ng Dugo';
  String get allergies => isEn ? 'Allergies' : 'Mga Alerhiya';
  String get existingConditions => isEn ? 'Existing Conditions' : 'Mga Kasalukuyang Kondisyon';
  String get previousSurgeries => isEn ? 'Previous surgeries?' : 'Nakaraan na operasyon?';
  String get describeSurgery => isEn ? 'Describe the surgery' : 'Ilarawan ang operasyon';
  String get currentMeds => isEn ? 'Current Medications (optional)' : 'Kasalukuyang Gamot (opsyonal)';
  String get familyHistory => isEn ? 'Family Medical History' : 'Kasaysayang Medikal ng Pamilya';
  String get emergencyContact => isEn ? 'Emergency Contact' : 'Emergency Contact';
  String get fullName => isEn ? 'Full Name' : 'Buong Pangalan';
  String get phoneNumber => isEn ? 'Phone Number' : 'Numero ng Telepono';
  String get relationship => isEn ? 'Relationship (e.g. Mother, Spouse)' : 'Relasyon (hal. Nanay, Asawa)';
  String get philhealth => isEn ? 'PhilHealth Number' : 'PhilHealth Number';
  String get hmoInsurance => isEn ? 'HMO / Private Insurance (name)' : 'HMO / Pribadong Insurance (pangalan)';
  String get hmoId => isEn ? 'HMO ID Number' : 'HMO ID Number';
  String get selectSex => isEn ? 'Please select your sex/gender' : 'Piliin ang iyong kasarian';
  String get selectBirthdate => isEn ? 'Please enter your date of birth' : 'Ilagay ang petsa ng kapanganakan';
  String get selectRegion => isEn ? 'Please select a region' : 'Pumili ng rehiyon';

  // Home tab
  String get mgaAksyon => isEn ? 'Quick Actions' : 'Mga Aksyon';
  String get mgaAnunsyo => isEn ? 'Announcements' : 'Mga Anunsyo';
  String get healthTips => isEn ? 'Health Tips' : 'Mga Health Tips';
  String get noAnnouncements => isEn ? 'No announcements yet' : 'Walang anunsyo sa ngayon';
  String get noHealthTips => isEn ? 'No health tips yet' : 'Walang health tips sa ngayon';
  String get recordSymptoms => isEn ? 'Record\nSymptoms' : 'I-record ang\nSintomas';
  String get scheduleConsult => isEn ? 'Schedule\nConsultation' : 'Mag-iskedyul ng\nKonsultasyon';
  String get requestMeds => isEn ? 'Request\nMedicine' : 'Humiling ng\nGamot';
  String get myRecords => isEn ? 'My\nRecords' : 'Aking mga\nRekord';
  String get patientId => isEn ? 'Patient ID' : 'Patient ID';
  String get verified => isEn ? 'Verified' : 'Napatunayan';
  String get online => isEn ? 'Online' : 'Online';
  String get copied => isEn ? 'Patient ID copied!' : 'Patient ID na-kopya!';

  // Account tab
  String get mgaRekord => isEn ? 'Health Records' : 'Mga Rekord';
  String get mgaKonsultasyon => isEn ? 'Consultations' : 'Mga Konsultasyon';
  String get mgaGamot => isEn ? 'Medicine Requests' : 'Mga Hiling na Gamot';
  String get symptomHistory => isEn ? 'Symptom History' : 'Kasaysayan ng Sintomas';
  String get mgaSetting => isEn ? 'Settings' : 'Mga Setting';
  String get mgaNotipikasyon => isEn ? 'Notifications' : 'Mga Notipikasyon';
  String get helpSupport => isEn ? 'Help & Support' : 'Tulong / Help';
  String get aboutApp => isEn ? 'About the App' : 'Tungkol sa App';
  String get uriNgDugo => isEn ? 'Blood Type' : 'Uri ng Dugo';
  String get healthCenter => isEn ? 'Health Center' : 'Health Center';

  // Worker
  String get dashboard => isEn ? 'Dashboard' : 'Dashboard';
  String get mgaPasyente => isEn ? 'Patients' : 'Mga Pasyente';
  String get mgaKonsultasyonWorker => isEn ? 'Consultations' : 'Mga Konsultasyon';
  String get gamot => isEn ? 'Medicine' : 'Gamot';
  String get mensahe => isEn ? 'Messages' : 'Mensahe';
  String get greetWorker => isEn ? 'Good day,' : 'Kumusta,';
  String get noPatients => isEn ? 'No patients yet' : 'Walang mga pasyente pa';
  String get noConsultations => isEn ? 'No consultations' : 'Walang mga konsultasyon';
  String get noMedicineReqs => isEn ? 'No medicine requests yet' : 'Walang mga hiling pa';
  String get noMessages => isEn ? 'No messages yet' : 'Walang mga mensahe pa';
  String get smsNote => isEn
      ? 'Patients send messages via native SMS. Reply via SMS as well.'
      : 'Ang mga pasyente ay nagpapadala ng mensahe via native SMS. I-reply din via SMS.';
  String get searchPatient => isEn ? 'Search patient...' : 'Hanapin ang pasyente...';
  String get overview => isEn ? 'Overview' : 'Pangkalahatang-Tanaw';
  String get recentActivity => isEn ? 'Recent Activity' : 'Kamakailang Aktibidad';
  String get noActivity => isEn ? 'No recent activity' : 'Walang mga aktibidad';
  String get pendingConsults => isEn ? 'Pending\nConsultations' : 'Pending\nKonsultasyon';
  String get newPatients => isEn ? 'New\nPatients' : 'Bagong\nPasyente';
  String get pendingMeds => isEn ? 'Pending\nMedicine' : 'Pending\nGamot';

  // Admin
  String get systemOverview => isEn ? 'System Overview' : 'System Overview';
  String get totalPatients => isEn ? 'Total\nPatients' : 'Kabuuang\nMga Pasyente';
  String get healthcareWorkers => isEn ? 'Healthcare\nWorkers' : 'Healthcare\nWorkers';
  String get consultThisMonth => isEn ? 'Consultations\nThis Month' : 'Konsultasyon\nNgayong Buwan';
  String get medicineReqs => isEn ? 'Medicine\nRequests' : 'Medicine\nRequests';
  String get activeHealthCenters => isEn ? 'Active\nHealth Centers' : 'Aktibong\nHealth Centers';
  String get notSynced => isEn ? 'Not Yet\nSynced' : 'Hindi Pa\nNa-sync';
  String get userManagement => isEn ? 'User Management' : 'User Management';
  String get allRecords => isEn ? 'All Records' : 'Lahat ng Rekord';
  String get healthTipsAnnounce => isEn ? 'Health Tips & Announcements' : 'Health Tips & Anunsyo';
  String get exportData => isEn ? 'Export Data' : 'I-export ang Data';
  String get exportSubtitle => isEn ? 'Download records as CSV file.' : 'I-download ang mga rekord bilang CSV file.';
  String get mgaAdmin => isEn ? 'Admins' : 'Mga Admin';
  String get noWorkers => isEn ? 'No workers yet' : 'Walang mga worker';
  String get noAdmins => isEn ? 'No admins yet' : 'Walang mga admin';
  String get noRecords => isEn ? 'No records yet' : 'Walang mga rekord';
  String get noContent => isEn ? 'No health tips or announcements' : 'Walang mga health tips o anunsyo';
  String exportingMsg(String name) => isEn ? 'Exporting $name...' : 'Nag-eexport ng $name...';
  String get searchPatientAdmin => isEn ? 'Search patient...' : 'Hanapin ang pasyente...';
}

// ── Convenience extension on BuildContext ─────────────────────────────────────
extension LangContext on BuildContext {
  S get s {
    // Try to get from Riverpod if available, else fallback to 'en'
    try {
      final container = ProviderScope.containerOf(this, listen: false);
      final lang = container.read(langProvider);
      return S(lang);
    } catch (_) {
      return const S('en');
    }
  }
}

// ── Language toggle widget (can be dropped anywhere) ─────────────────────────
class LangToggle extends ConsumerWidget {
  final bool compact;
  const LangToggle({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final isEn = lang == 'en';

    if (compact) {
      return GestureDetector(
        onTap: () => ref.read(langProvider.notifier).setLang(isEn ? 'tl' : 'en'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(isEn ? '🇺🇸' : '🇵🇭', style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(isEn ? 'EN' : 'TL',
                style: const TextStyle(color: Colors.white, fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _LangBtn(flag: '🇺🇸', label: 'English', selected: isEn,
            onTap: () => ref.read(langProvider.notifier).setLang('en')),
        const SizedBox(width: 4),
        _LangBtn(flag: '🇵🇭', label: 'Filipino', selected: !isEn,
            onTap: () => ref.read(langProvider.notifier).setLang('tl')),
      ]),
    );
  }
}

class _LangBtn extends StatelessWidget {
  final String flag, label;
  final bool selected;
  final VoidCallback onTap;
  const _LangBtn({required this.flag, required this.label,
      required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        boxShadow: selected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4, offset: const Offset(0, 1))] : [],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(flag, style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: selected ? const Color(0xFF1E293B) : const Color(0xFF94A3B8))),
      ]),
    ),
  );
}
