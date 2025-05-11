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
  final double? distance;
  final int? travelTime;

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
    this.distance,
    this.travelTime,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    // Handle SSE data format
    if (json.containsKey('name') && json.containsKey('address') && json.containsKey('distance')) {
      // Generate unique ID using name and address hash code
      int generatedId = '${json['name']}_${json['address']}'.hashCode;
      
      // Format phone number
      String formattedPhone = json['phone_number'] ?? '';
      
      // Use departments as specialties
      String specialties = json['departments'] ?? '';
      
      // SSE response may not have isAvailable and availableBeds
      bool isAvailable = json['is_available'] ?? true;
      int availableBeds = json['available_beds'] ?? 5; // Default value 5
      
      // SSE response may not have coordinates - use default coordinates
      double lat = json['latitude'] ?? 37.5665;
      double lng = json['longitude'] ?? 126.9780;
      
      return Hospital(
        id: generatedId,
        name: json['name'] ?? '',
        address: json['address'] ?? '',
        latitude: lat,
        longitude: lng,
        phoneNumber: formattedPhone,
        isAvailable: isAvailable,
        availableBeds: availableBeds,
        specialties: specialties,
        distance: json['distance']?.toDouble(),
        travelTime: json['travel_time'],
      );
    }
    
    // Handle existing format
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
      'distance': distance,
      'travelTime': travelTime,
    };
  }

  // Calculate estimated arrival time based on distance (meters)
  String estimatedTime(double distanceInMeters) {
    // Use travelTime if available
    if (travelTime != null) {
      return '$travelTime min';
    }
    
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
