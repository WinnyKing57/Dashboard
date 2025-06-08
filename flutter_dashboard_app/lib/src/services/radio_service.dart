import 'dart:convert';
import 'package:flutter_dashboard_app/src/models/radio_station.dart';
import 'package:flutter_dashboard_app/src/models/favorite_station.dart'; // Import FavoriteStation
import 'package:hive/hive.dart'; // Import Hive for Box
import 'package:http/http.dart' as http;

class RadioService {
  static const String _baseUrl = 'https://de1.api.radio-browser.info/json';
  static const String _favoritesBoxName = 'favoriteStationsBox';

  Box<FavoriteStation> get _favoritesBox => Hive.box<FavoriteStation>(_favoritesBoxName);

  Future<List<RadioStation>> fetchStations({
    String searchTerm = '',
    String countryCode = '',
    String tag = '',
    int limit = 100, // Default limit
    bool hideBroken = true, // Recommended by RadioBrowser API docs
  }) async {
    // Construct query parameters
    Map<String, String> queryParams = {
      'limit': limit.toString(),
      'hidebroken': hideBroken.toString(),
      // Order by votes for generally better results, then by name
      'order': 'votes',
      'reverse': 'true',
    };

    if (searchTerm.isNotEmpty) {
      // Use 'search' endpoint if searchTerm is provided
      // The API documentation suggests using /stations/byname/{searchterm} or /stations/bytag/{searchterm} etc.
      // or the more general /stations/search with specific parameters.
      // For simplicity, we'll use the /stations/search endpoint and add 'name' or 'tag' param.
      // If a general search term can apply to name, tag, country, etc., the API might have a specific param or need multiple calls.
      // Let's assume searchTerm applies to station name for now.
      queryParams['name'] = searchTerm;
      queryParams['nameExact'] = 'false'; // Allow partial matches
    }
    if (countryCode.isNotEmpty) {
      queryParams['countrycode'] = countryCode;
    }
    if (tag.isNotEmpty) {
      queryParams['tag'] = tag;
      queryParams['tagExact'] = 'false';
    }

    final Uri uri = Uri.parse('$_baseUrl/stations/search').replace(queryParameters: queryParams);

    print('Fetching radio stations from: $uri');

    try {
      final response = await http.get(uri, headers: {
        // Recommended by RadioBrowser: identify your app
        'User-Agent': 'FlutterDashboardApp/1.0',
      });

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        if (jsonData.isEmpty) {
          return []; // Return empty list if API returns empty array
        }
        return jsonData.map((jsonStation) => RadioStation.fromJson(jsonStation)).toList();
      } else {
        print('Failed to load stations: ${response.statusCode} ${response.reasonPhrase}');
        // Consider throwing a specific exception or returning an error object
        return []; // Return empty list on error
      }
    } catch (e) {
      print('Error fetching stations: $e');
      // Consider throwing a specific exception or returning an error object
      return []; // Return empty list on error
    }
  }

  // Example of a more specific search if needed:
  // Future<List<RadioStation>> searchStationsByName(String name) async {
  //   final Uri uri = Uri.parse('$_baseUrl/stations/byname/$name');
  //   // ... similar http get and parsing logic ...
  // }

  // Favorite Management Methods
  Future<void> addFavorite(RadioStation station) async {
    final favorite = FavoriteStation(
      stationuuid: station.stationuuid,
      name: station.name,
      urlResolved: station.urlResolved,
      country: station.country,
      favicon: station.favicon,
      tags: station.tags,
    );
    await _favoritesBox.put(favorite.stationuuid, favorite);
  }

  Future<void> removeFavorite(String stationuuid) async {
    await _favoritesBox.delete(stationuuid);
  }

  bool isFavorite(String stationuuid) {
    return _favoritesBox.containsKey(stationuuid);
  }

  List<FavoriteStation> getFavoriteStations() {
    return _favoritesBox.values.toList();
  }

  // For Data Export/Import
  List<Map<String, dynamic>> exportFavorites() {
    return _favoritesBox.values.map((fav) => {
      'stationuuid': fav.stationuuid,
      'name': fav.name,
      'urlResolved': fav.urlResolved,
      'country': fav.country,
      'favicon': fav.favicon,
      'tags': fav.tags,
    }).toList();
  }

  Future<void> importFavorites(List<dynamic> favoritesJson) async {
    await _favoritesBox.clear(); // Clear existing favorites before importing
    for (var favData in favoritesJson) {
      if (favData is Map<String, dynamic>) {
        final favorite = FavoriteStation(
          stationuuid: favData['stationuuid'],
          name: favData['name'],
          urlResolved: favData['urlResolved'],
          country: favData['country'],
          favicon: favData['favicon'],
          tags: (favData['tags'] as List<dynamic>?)?.cast<String>().toList(),
        );
        await _favoritesBox.put(favorite.stationuuid, favorite);
      }
    }
  }
}
