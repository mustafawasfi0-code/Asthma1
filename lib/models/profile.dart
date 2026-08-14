class Profile {
  const Profile({
    this.id,
    required this.name,
    required this.city,
    required this.age,
    required this.sex,
    required this.heightCm,
    this.personalBest,
    this.doctorName,
    this.doctorPhone,
  });
  final String? id;
  final String name, city, sex;
  final int age;
  final double heightCm;
  final int? personalBest;
  final String? doctorName, doctorPhone;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name.trim(),
    'city': city,
    'age': age,
    'sex': sex,
    'height_cm': heightCm,
    'personal_best_pef': personalBest,
    'doctor_name': doctorName,
    'doctor_phone': doctorPhone,
  };
  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
    id: j['id'],
    name: j['name'] ?? '',
    city: j['city'] ?? '',
    age: j['age'] ?? 0,
    sex: j['sex'] ?? '',
    heightCm: (j['height_cm'] as num?)?.toDouble() ?? 0,
    personalBest: j['personal_best_pef'],
    doctorName: j['doctor_name'],
    doctorPhone: j['doctor_phone'],
  );
}
