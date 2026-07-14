class ServiceReport {
  final String id;
  final String unitId;
  final String unitName;
  final String officerId;
  final String officerName;
  final DateTime campDate;
  final String villageName;
  final String district;
  final String state;

  // Population served
  final int totalMale;
  final int totalFemale;
  final int totalChildren;
  final int totalSeniorCitizens;

  // Services delivered
  final int generalConsultations;
  final int diabetesScreening;
  final int hypertensionScreening;
  final int maternalHealthServices;
  final int childHealthServices;
  final int vaccinationSupport;
  final int referralCases;

  final String remarks;
  final DateTime submittedAt;
  final bool isVerified;
  final String? verifiedBy;

  const ServiceReport({
    required this.id,
    required this.unitId,
    required this.unitName,
    required this.officerId,
    required this.officerName,
    required this.campDate,
    required this.villageName,
    required this.district,
    required this.state,
    required this.totalMale,
    required this.totalFemale,
    required this.totalChildren,
    required this.totalSeniorCitizens,
    required this.generalConsultations,
    required this.diabetesScreening,
    required this.hypertensionScreening,
    required this.maternalHealthServices,
    required this.childHealthServices,
    required this.vaccinationSupport,
    required this.referralCases,
    required this.remarks,
    required this.submittedAt,
    required this.isVerified,
    this.verifiedBy,
  });

  int get totalPopulationServed =>
      totalMale + totalFemale + totalChildren + totalSeniorCitizens;

  int get totalServicesDelivered =>
      generalConsultations +
      diabetesScreening +
      hypertensionScreening +
      maternalHealthServices +
      childHealthServices +
      vaccinationSupport +
      referralCases;
}
