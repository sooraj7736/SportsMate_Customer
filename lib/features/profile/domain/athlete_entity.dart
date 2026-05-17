class Address {
  final String name;
  final double lat;
  final double lng;
  final String addressText;

  Address({
    required this.name,
    required this.lat,
    required this.lng,
    required this.addressText,
  });

  Map<String, dynamic> toMap() {
    return {'name': name, 'lat': lat, 'lng': lng, 'addressText': addressText};
  }

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      name: map['name'] ?? '',
      lat: map['lat']?.toDouble() ?? 0.0,
      lng: map['lng']?.toDouble() ?? 0.0,
      addressText: map['addressText'] ?? '',
    );
  }
}

class Athlete {
  final String uid;
  final String username;
  final String name;
  final String email;
  final List<String> favoriteSports;
  final String skillLevel;
  final String? profilePic;

  Athlete({
    required this.uid,
    required this.username,
    required this.name,
    required this.email,
    required this.favoriteSports,
    required this.skillLevel,
    this.profilePic,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'name': name,
      'email': email,
      'favoriteSports': favoriteSports,
      'skillLevel': skillLevel,
      'profilePic': profilePic,
    };
  }

  factory Athlete.fromMap(Map<String, dynamic> map, String id) {
    return Athlete(
      uid: map['uid'] ?? id,
      username: map['username'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      favoriteSports: List<String>.from(map['favoriteSports'] ?? []),
      skillLevel: map['skillLevel'] ?? '',
      profilePic: map['profilePic'],
    );
  }
}
