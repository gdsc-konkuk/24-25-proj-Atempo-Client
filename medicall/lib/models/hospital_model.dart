class Hospital {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String phoneNumber;
  final bool isAvailable;
  final int availableBeds;
  final String? specialties;

  Hospital({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phoneNumber,
    required this.isAvailable,
    required this.availableBeds,
    this.specialties,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      phoneNumber: json['phoneNumber'],
      isAvailable: json['isAvailable'],
      availableBeds: json['availableBeds'],
      specialties: json['specialties'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phoneNumber': phoneNumber,
      'isAvailable': isAvailable,
      'availableBeds': availableBeds,
      'specialties': specialties,
    };
  }

  // Calculate estimated arrival time based on distance (meters)
  String estimatedTime(double distanceInMeters) {
    // Calculate estimated time based on distance (in meters)
    // Using average ambulance speed (approx. 50 km/h = 13.89 m/s)
    final double speedInMetersPerSecond = 13.89;
    final int timeInSeconds = (distanceInMeters / speedInMetersPerSecond).round();
    
    if (timeInSeconds < 60) {
      return '$timeInSeconds sec';
    } else {
      final int minutes = (timeInSeconds / 60).round();
      return '$minutes min';
    }
  }
}
