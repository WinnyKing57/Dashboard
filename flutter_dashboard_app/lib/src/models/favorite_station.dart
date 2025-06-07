import 'package:hive/hive.dart';

part 'favorite_station.g.dart';

@HiveType(typeId: 6) // Unique typeId
class FavoriteStation extends HiveObject {
  @HiveField(0)
  String stationuuid; // Primary key

  @HiveField(1)
  String name;

  @HiveField(2)
  String urlResolved;

  @HiveField(3)
  String? country;

  @HiveField(4)
  String? favicon;

  @HiveField(5)
  List<String>? tags;

  FavoriteStation({
    required this.stationuuid,
    required this.name,
    required this.urlResolved,
    this.country,
    this.favicon,
    this.tags,
  });
}
