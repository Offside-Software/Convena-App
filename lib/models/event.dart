class TicketTier {
  final String id;
  final String name;
  final double price;
  final int quota;
  final int sold;
  final List<String> benefits;
  final bool isAvailable;

  const TicketTier({
    required this.id,
    required this.name,
    required this.price,
    required this.quota,
    this.sold = 0,
    this.benefits = const [],
    this.isAvailable = true,
  });

  bool get isFree => price <= 0;

  int get quotaLeft => (quota - sold).clamp(0, quota);

  String get formattedPrice {
    if (isFree) return 'GRATIS';
    final intPrice = price.toInt();
    final buffer = StringBuffer();
    final str = intPrice.toString();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return 'Rp $buffer';
  }

  factory TicketTier.fromJson(Map<String, dynamic> json) {
    return TicketTier(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Tiket Masuk',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quota: (json['quota'] as num?)?.toInt() ?? 100,
      sold: (json['sold'] as num?)?.toInt() ?? 0,
      benefits: (json['benefits'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quota': quota,
      'sold': sold,
      'benefits': benefits,
      'isAvailable': isAvailable,
    };
  }
}

class Event {
  final String id;
  final String createdBy;
  final String? organizationId;
  final String title;
  final String slug;
  final String? description;
  final String? shortDescription;
  final String? bannerUrl;
  final String category;
  final String status;
  final String visibility;
  final DateTime startDate;
  final DateTime endDate;
  final String locationType;
  final String? venueName;
  final String? address;
  final String? city;
  final String? onlineUrl;
  final double? latitude;
  final double? longitude;
  final String? attendanceQrToken;
  final String? organizationName;
  final String? company;
  final List<TicketTier> ticketTiers;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Event({
    required this.id,
    required this.createdBy,
    this.organizationId,
    required this.title,
    required this.slug,
    this.description,
    this.shortDescription,
    this.bannerUrl,
    required this.category,
    this.status = 'published',
    this.visibility = 'public',
    required this.startDate,
    required this.endDate,
    this.locationType = 'offline',
    this.venueName,
    this.address,
    this.city,
    this.onlineUrl,
    this.latitude,
    this.longitude,
    this.attendanceQrToken,
    this.organizationName,
    this.company,
    this.ticketTiers = const [],
    required this.createdAt,
    this.updatedAt,
  });

  double get lowestPrice {
    if (ticketTiers.isEmpty) return 0.0;
    double minPrice = ticketTiers.first.price;
    for (final tier in ticketTiers) {
      if (tier.price < minPrice) {
        minPrice = tier.price;
      }
    }
    return minPrice;
  }

  bool get isFree => lowestPrice <= 0;

  String get formattedLowestPrice {
    if (isFree) return 'GRATIS';
    final intPrice = lowestPrice.toInt();
    final buffer = StringBuffer();
    final str = intPrice.toString();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return 'Rp $buffer';
  }

  int get totalCapacity {
    if (ticketTiers.isEmpty) return 500;
    return ticketTiers.fold(0, (sum, t) => sum + t.quota);
  }

  int get attendeeCount {
    if (ticketTiers.isEmpty) return 0;
    return ticketTiers.fold(0, (sum, t) => sum + t.sold);
  }

  String get displayLocation {
    if (locationType.toLowerCase() == 'online') {
      return 'Online Event';
    }
    final venue = venueName?.trim();
    final cityName = city?.trim();
    if (venue != null && venue.isNotEmpty && cityName != null && cityName.isNotEmpty) {
      return '$venue, $cityName';
    }
    return venue ?? cityName ?? 'Venue Acara';
  }

  String get formattedDate {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final dayName = days[startDate.weekday - 1];
    final monthName = months[startDate.month - 1];
    return '$dayName, ${startDate.day} $monthName ${startDate.year}';
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    List<TicketTier> tiers = [];
    if (json['ticketTiers'] is List) {
      tiers = (json['ticketTiers'] as List)
          .map((t) => TicketTier.fromJson(t as Map<String, dynamic>))
          .toList();
    }

    return Event(
      id: json['id']?.toString() ?? '',
      createdBy: json['createdBy']?.toString() ?? '',
      organizationId: json['organizationId']?.toString(),
      title: json['title'] as String? ?? 'Untitled Event',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      shortDescription: json['shortDescription'] as String? ??
          (json['description'] != null && (json['description'] as String).length > 120
              ? (json['description'] as String).substring(0, 120)
              : json['description'] as String?),
      bannerUrl: json['bannerUrl'] as String?,
      category: json['category'] as String? ?? 'seminar',
      status: json['status'] as String? ?? 'published',
      visibility: json['visibility'] as String? ?? 'public',
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? '') ??
          DateTime.now(),
      endDate: DateTime.tryParse(json['endDate']?.toString() ?? '') ??
          DateTime.now(),
      locationType: json['locationType'] as String? ?? 'offline',
      venueName: json['venueName'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      onlineUrl: json['onlineUrl'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      attendanceQrToken: json['attendanceQrToken'] as String?,
      organizationName: json['organizationName'] as String? ?? 'BEM & DPM Kema Tel-U',
      company: json['company'] as String? ?? 'Telkom University',
      ticketTiers: tiers,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdBy': createdBy,
      'organizationId': organizationId,
      'title': title,
      'slug': slug,
      'description': description,
      'shortDescription': shortDescription,
      'bannerUrl': bannerUrl,
      'category': category,
      'status': status,
      'visibility': visibility,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'locationType': locationType,
      'venueName': venueName,
      'address': address,
      'city': city,
      'onlineUrl': onlineUrl,
      'latitude': latitude,
      'longitude': longitude,
      'attendanceQrToken': attendanceQrToken,
      'organizationName': organizationName,
      'company': company,
      'ticketTiers': ticketTiers.map((t) => t.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class EventRegistration {
  final String id;
  final String eventId;
  final String userId;
  final String tierId;
  final String tierName;
  final double price;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final String attendeeName;
  final String attendeeEmail;
  final String? attendeePhone;
  final String? attendeeInstitution;
  final String ticketCode;
  final DateTime? checkedInAt;
  final DateTime createdAt;

  const EventRegistration({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.tierId,
    required this.tierName,
    required this.price,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.attendeeName,
    required this.attendeeEmail,
    this.attendeePhone,
    this.attendeeInstitution,
    required this.ticketCode,
    this.checkedInAt,
    required this.createdAt,
  });

  bool get isCheckedIn => status == 'checked_in';
  bool get isPaid => paymentStatus == 'paid';

  String get formattedPrice {
    if (price <= 0) return 'GRATIS';
    final intPrice = price.toInt();
    final buffer = StringBuffer();
    final str = intPrice.toString();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return 'Rp $buffer';
  }

  factory EventRegistration.fromJson(Map<String, dynamic> json) {
    return EventRegistration(
      id: json['id']?.toString() ?? '',
      eventId: json['eventId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      tierId: json['tierId']?.toString() ?? '',
      tierName: json['tierName']?.toString() ?? 'General Admission',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod']?.toString() ?? 'free',
      paymentStatus: json['paymentStatus']?.toString() ?? 'paid',
      status: json['status']?.toString() ?? 'confirmed',
      attendeeName: json['attendeeName']?.toString() ?? 'Peserta Convena',
      attendeeEmail: json['attendeeEmail']?.toString() ?? '',
      attendeePhone: json['attendeePhone']?.toString(),
      attendeeInstitution: json['attendeeInstitution']?.toString(),
      ticketCode: json['ticketCode']?.toString() ?? 'TKT-CONVENA',
      checkedInAt: json['checkedInAt'] != null
          ? DateTime.tryParse(json['checkedInAt'].toString())
          : null,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class AttendanceRealtimeEvent {
  final String eventType;
  final String eventId;
  final String eventTitle;
  final bool alreadyCheckedIn;
  final String message;
  final EventRegistration registration;
  final DateTime timestamp;

  const AttendanceRealtimeEvent({
    required this.eventType,
    required this.eventId,
    required this.eventTitle,
    required this.alreadyCheckedIn,
    required this.message,
    required this.registration,
    required this.timestamp,
  });

  factory AttendanceRealtimeEvent.fromJson(Map<String, dynamic> json) {
    final regMap = json['registration'] is Map<String, dynamic>
        ? json['registration'] as Map<String, dynamic>
        : <String, dynamic>{};
    return AttendanceRealtimeEvent(
      eventType: json['eventType']?.toString() ?? 'attendance.checked_in',
      eventId: json['eventId']?.toString() ?? regMap['eventId']?.toString() ?? '',
      eventTitle: json['eventTitle']?.toString() ?? 'Event Convena',
      alreadyCheckedIn: json['alreadyCheckedIn'] == true,
      message: json['message']?.toString() ?? 'Status kehadiran diperbarui',
      registration: EventRegistration.fromJson(regMap),
      timestamp:
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}


