import 'package:latlong2/latlong.dart';

class EventLocation {
  /// Nama event
  final String eventTitle;
  /// Nama venue / tempat acara (misal: "Creative Meetup", "Dago, Bandung")
  final String venueName;
  /// Alamat venue
  final String address;
  /// Garis lintang (latitude)
  final double latitude;
  /// Garis bujur (longitude)
  final double longitude;
  /// Jarak estimasi dari posisi pengguna (misal: "1.2 km")
  final String distance;
  /// URL gambar thumbnail event
  final String? imageUrl;
  /// Kategori event (misal: "Meetup", "Music", "Tech")
  final String? category;

  const EventLocation({
    required this.eventTitle,
    required this.venueName,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.distance = '1.0 km',
    this.imageUrl,
    this.category,
  });

  /// Konversi latitude & longitude ke objek [LatLng] untuk kebutuhan flutter_map
  LatLng get coordinates => LatLng(latitude, longitude);

  /// Koordinat tidak null / inputan valid
  bool get isValid =>
      latitude != 0.0 &&
      longitude != 0.0 &&
      latitude >= -90.0 &&
      latitude <= 90.0 &&
      longitude >= -180.0 &&
      longitude <= 180.0;
}
