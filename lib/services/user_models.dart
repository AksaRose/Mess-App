class AppUser {
  final String admissionNo;
  final String fullName;
  final int passOutYear;

  const AppUser({
    required this.admissionNo,
    required this.fullName,
    required this.passOutYear,
  });

  Map<String, dynamic> toJson() => {
    'admissionNo': admissionNo,
    'fullName': fullName,
    'passOutYear': passOutYear,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    admissionNo: json['admissionNo'] as String,
    fullName: json['fullName'] as String,
    passOutYear: (json['passOutYear'] as num).toInt(),
  );
}
