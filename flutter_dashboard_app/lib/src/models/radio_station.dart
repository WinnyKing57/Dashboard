// Note: This is not a HiveObject for now.
class RadioStation {
  final String stationuuid;
  final String name;
  final String urlResolved; // Stream URL
  final String? country;
  final String? countryCode;
  final String? state;
  final String? favicon;
  final String? homepage;
  final List<String> tags;
  final double? votes; // API sometimes returns votes as double
  final String? language;
  final String? codec;
  final int? bitrate;


  // Local field, not from API directly
  bool isFavorite;

  RadioStation({
    required this.stationuuid,
    required this.name,
    required this.urlResolved,
    this.country,
    this.countryCode,
    this.state,
    this.favicon,
    this.homepage,
    this.tags = const [],
    this.votes,
    this.language,
    this.codec,
    this.bitrate,
    this.isFavorite = false,
  });

  factory RadioStation.fromJson(Map<String, dynamic> json) {
    return RadioStation(
      stationuuid: json['stationuuid'] as String,
      name: json['name'] as String? ?? 'Unknown Station',
      urlResolved: json['url_resolved'] as String? ?? json['url'] as String? ?? '',
      country: json['country'] as String?,
      countryCode: json['countrycode'] as String?,
      state: json['state'] as String?,
      favicon: json['favicon'] as String?,
      homepage: json['homepage'] as String?,
      tags: (json['tags'] as String?)?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
      votes: (json['votes'] as num?)?.toDouble(), // API returns num (int or double)
      language: json['language'] as String?,
      codec: json['codec'] as String?,
      bitrate: (json['bitrate'] as num?)?.toInt(),
    );
  }

  // Helper to get a displayable country string
  String get countryDisplay {
    if (state != null && state!.isNotEmpty && country != null && country!.isNotEmpty) {
      return '$state, $country';
    }
    return country ?? countryCode ?? 'Unknown Location';
  }
}
