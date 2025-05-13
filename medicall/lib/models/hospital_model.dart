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
      
      // Coordinate conversion and validation
      double lat;
      double lng;
      
      try {
        var rawLat = json['latitude'];
        var rawLng = json['longitude'];
        
        if (rawLat == null || rawLng == null) {
          throw Exception("Hospital coordinates are null.");
        }
        
        if (rawLat is double) {
          lat = rawLat;
        } else if (rawLat is int) {
          lat = rawLat.toDouble();
        } else if (rawLat is String) {
          lat = double.parse(rawLat);
        } else {
          throw Exception("Invalid latitude format: $rawLat (${rawLat.runtimeType})");
        }
        
        if (rawLng is double) {
          lng = rawLng;
        } else if (rawLng is int) {
          lng = rawLng.toDouble();
        } else if (rawLng is String) {
          lng = double.parse(rawLng);
        } else {
          throw Exception("Invalid longitude format: $rawLng (${rawLng.runtimeType})");
        }
        
        // Coordinate validation
        if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
          throw Exception("Coordinates are out of valid range: lat=$lat, lng=$lng");
        }
      } catch (e) {
        print("⚠️ Hospital coordinates processing error: $e - Using Seoul City Hall coordinates as fallback.");
        // Error occurred, use Seoul City Hall coordinates as fallback
        lat = 37.5662;
        lng = 126.9785;
      }
      
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
    try {
      
      double lat;
      double lng;
      
      var rawLat = json['latitude'];
      var rawLng = json['longitude'];
      
      if (rawLat == null || rawLng == null) {
        throw Exception("Hospital coordinates are null.");
      }
      
      if (rawLat is double) {
        lat = rawLat;
      } else if (rawLat is int) {
        lat = rawLat.toDouble();
      } else if (rawLat is String) {
        lat = double.parse(rawLat);
      } else {
        throw Exception("Invalid latitude format: $rawLat (${rawLat.runtimeType})");
      }
      
      if (rawLng is double) {
        lng = rawLng;
      } else if (rawLng is int) {
        lng = rawLng.toDouble();
      } else if (rawLng is String) {
        lng = double.parse(rawLng);
      } else {
        throw Exception("Invalid longitude format: $rawLng (${rawLng.runtimeType})");
      }
      
      // 좌표 범위 검증
      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
        throw Exception("Coordinates are out of valid range: lat=$lat, lng=$lng");
      }
      
      return Hospital(
        id: json['id'],
        name: json['name'],
        address: json['address'],
        latitude: lat,
        longitude: lng,
        phoneNumber: json['phoneNumber'],
        isAvailable: json['isAvailable'],
        availableBeds: json['availableBeds'],
        specialties: json['specialties'],
      );
    } catch (e) {
      print("⚠️ Hospital coordinates processing error: $e - Using Seoul City Hall coordinates as fallback.");
      // Error occurred, use Seoul City Hall coordinates as fallback
      return Hospital(
        id: json['id'] ?? (json['name'] ?? '').hashCode,
        name: json['name'] ?? '',
        address: json['address'] ?? '',
        latitude: 37.5662, 
        longitude: 126.9785,  
        phoneNumber: json['phoneNumber'] ?? '',
        isAvailable: json['isAvailable'] ?? true,
        availableBeds: json['availableBeds'] ?? 5,
        specialties: json['specialties'],
      );
    }
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
