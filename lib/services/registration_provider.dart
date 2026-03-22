import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegistrationData {
  // Step 1 - Personal Info
  final String firstName;
  final String middleName;
  final String lastName;
  final String suffix;
  final DateTime? birthdate;
  final String sex;
  final String civilStatus;

  // Step 2 - Address
  final String houseStreet;
  final String barangay;
  final String city;
  final String province;
  final String region;

  // Step 3 - Health Profile
  final String bloodType;
  final List<String> allergies;
  final List<String> conditions;
  final bool hasSurgeries;
  final String surgeriesDetail;
  final String currentMedications;
  final List<String> familyHistory;
  final String emergencyName;
  final String emergencyPhone;
  final String emergencyRelation;

  // Step 4 - Insurance
  final String philhealthNumber;
  final String hmoName;
  final String hmoId;

  // Phone
  final String phoneNumber;

  const RegistrationData({
    this.firstName = '',
    this.middleName = '',
    this.lastName = '',
    this.suffix = '',
    this.birthdate,
    this.sex = '',
    this.civilStatus = '',
    this.houseStreet = '',
    this.barangay = '',
    this.city = '',
    this.province = '',
    this.region = '',
    this.bloodType = '',
    this.allergies = const [],
    this.conditions = const [],
    this.hasSurgeries = false,
    this.surgeriesDetail = '',
    this.currentMedications = '',
    this.familyHistory = const [],
    this.emergencyName = '',
    this.emergencyPhone = '',
    this.emergencyRelation = '',
    this.philhealthNumber = '',
    this.hmoName = '',
    this.hmoId = '',
    this.phoneNumber = '',
  });

  RegistrationData copyWith({
    String? firstName, String? middleName, String? lastName, String? suffix,
    DateTime? birthdate, String? sex, String? civilStatus,
    String? houseStreet, String? barangay, String? city, String? province, String? region,
    String? bloodType, List<String>? allergies, List<String>? conditions,
    bool? hasSurgeries, String? surgeriesDetail, String? currentMedications,
    List<String>? familyHistory, String? emergencyName, String? emergencyPhone,
    String? emergencyRelation, String? philhealthNumber, String? hmoName, String? hmoId,
    String? phoneNumber,
  }) {
    return RegistrationData(
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      suffix: suffix ?? this.suffix,
      birthdate: birthdate ?? this.birthdate,
      sex: sex ?? this.sex,
      civilStatus: civilStatus ?? this.civilStatus,
      houseStreet: houseStreet ?? this.houseStreet,
      barangay: barangay ?? this.barangay,
      city: city ?? this.city,
      province: province ?? this.province,
      region: region ?? this.region,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      conditions: conditions ?? this.conditions,
      hasSurgeries: hasSurgeries ?? this.hasSurgeries,
      surgeriesDetail: surgeriesDetail ?? this.surgeriesDetail,
      currentMedications: currentMedications ?? this.currentMedications,
      familyHistory: familyHistory ?? this.familyHistory,
      emergencyName: emergencyName ?? this.emergencyName,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      emergencyRelation: emergencyRelation ?? this.emergencyRelation,
      philhealthNumber: philhealthNumber ?? this.philhealthNumber,
      hmoName: hmoName ?? this.hmoName,
      hmoId: hmoId ?? this.hmoId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  String get fullName => [firstName, middleName, lastName, suffix]
      .where((s) => s.isNotEmpty).join(' ');

  int? get age {
    if (birthdate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthdate!.year;
    if (now.month < birthdate!.month ||
        (now.month == birthdate!.month && now.day < birthdate!.day)) {
      age--;
    }
    return age;
  }
}

class RegistrationNotifier extends StateNotifier<RegistrationData> {
  RegistrationNotifier() : super(const RegistrationData());

  void update(RegistrationData Function(RegistrationData) updater) {
    state = updater(state);
  }

  void reset() => state = const RegistrationData();
}

final registrationProvider =
    StateNotifierProvider<RegistrationNotifier, RegistrationData>(
  (ref) => RegistrationNotifier(),
);
