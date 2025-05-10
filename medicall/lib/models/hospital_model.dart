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
    // SSE 데이터 형식 처리
    if (json.containsKey('name') && json.containsKey('address') && json.containsKey('distance')) {
      // ID를 고유하게 생성하기 위해 이름과 주소의 해시코드를 사용
      int generatedId = '${json['name']}_${json['address']}'.hashCode;
      
      // 전화번호 포맷팅 처리
      String formattedPhone = json['phone_number'] ?? '';
      
      // 부서 정보를 specialties로 사용
      String specialties = json['departments'] ?? '';
      
      // SSE 응답에는 isAvailable과 availableBeds가 없을 수 있음
      bool isAvailable = json['is_available'] ?? true;
      int availableBeds = json['available_beds'] ?? 5; // 기본값 5
      
      // SSE 응답에는 좌표가 없을 수 있음 - 기본 좌표 사용
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
    
    // 기존 형식 처리
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
