
class Clinic {
  final String id;
  final String name;
  final Map<String, String> servicesWithTime;
  final double rating;
  final String password;

  Clinic({
    this.id = '',
    required this.name,
    required this.servicesWithTime,
    this.rating = 0.0,
    this.password = '',
  });
}
