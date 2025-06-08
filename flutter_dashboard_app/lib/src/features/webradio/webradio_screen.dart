import 'package:flutter/material.dart';
import 'package:flutter_dashboard_app/src/models/radio_station.dart';
import 'package:flutter_dashboard_app/src/services/radio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async'; // For StreamSubscription

// Make AudioPlayer and current station accessible (simplification for now)
// In a real app, use a proper state management solution (Provider, Riverpod, BLoC)
// or a dedicated audio service.
class GlobalRadioState {
  static final AudioPlayer audioPlayer = AudioPlayer();
  static RadioStation? currentStation;
  static PlayerState? playerState;

  // Notification Channel details (Required for just_audio background notifications)
  static const String androidNotificationChannelId = 'com.example.flutter_dashboard_app.channel.audio';
  static const String androidNotificationChannelName = 'Flutter Dashboard App Audio';
  static const String androidNotificationIcon = 'mipmap/ic_launcher'; // Default Flutter icon
  static final StreamController<RadioStation?> _currentStationController = StreamController.broadcast();
  static final StreamController<PlayerState?> _playerStateController = StreamController.broadcast();

  static Stream<RadioStation?> get currentStationStream => _currentStationController.stream;
  static Stream<PlayerState?> get playerStateStream => _playerStateController.stream;


  static void setCurrentStation(RadioStation? station) {
    currentStation = station;
    _currentStationController.add(station);
  }

  static void setPlayerState(PlayerState? state) {
    playerState = state;
    _playerStateController.add(state);
  }

  // Ensure dispose is called if the app is fully closing, though this is tricky with static.
  // For now, WebRadioScreen will handle its own instance's player state stream.
}


class WebRadioScreen extends StatefulWidget {
  const WebRadioScreen({super.key});

  @override
  State<WebRadioScreen> createState() => _WebRadioScreenState();
}

class _WebRadioScreenState extends State<WebRadioScreen> {
  final RadioService _radioService = RadioService();
  // Use the static AudioPlayer instance
  final AudioPlayer _audioPlayer = GlobalRadioState.audioPlayer;
  final TextEditingController _searchController = TextEditingController();

  List<RadioStation> _apiStations = []; // Stations fetched from API
  List<FavoriteStation> _favoriteStations = []; // Loaded from Hive
  bool _isLoadingStations = false;
  bool _isSearching = false;
  bool _showFavorites = false; // Toggle state

  StreamSubscription<PlayerState>? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        GlobalRadioState.setPlayerState(state);
        setState(() {});
      }
    });
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _playerStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _loadFavorites(); // Load favorites first
    if (!_showFavorites) {
      await _fetchInitialApiStations(); // Then load API stations if not showing favs
    }
  }

  Future<void> _loadFavorites() async {
    if(mounted) setState(() { _isLoadingStations = true; });
    _favoriteStations = _radioService.getFavoriteStations();
    if(mounted) setState(() { _isLoadingStations = false; });
  }

  Future<void> _fetchInitialApiStations() async {
    // Fetch some popular stations by default if not in favorite view
    await _searchApiStations(term: "jazz");
  }

  Future<void> _searchApiStations({String term = '', String countryCode = '', String tag = ''}) async {
    if (mounted) {
      setState(() {
        _isLoadingStations = true;
        _isSearching = term.isNotEmpty || countryCode.isNotEmpty || tag.isNotEmpty;
      });
    }
    try {
      final stations = await _radioService.fetchStations(
        searchTerm: term,
        countryCode: countryCode,
        tag: tag
      );
      if (mounted) {
        setState(() {
          _apiStations = stations;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching stations: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStations = false;
        });
      }
    }
  }

  Future<void> _playStation(RadioStation station) async {
    if (station.urlResolved.isEmpty) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Station URL is not available.')),
      );
      return;
    }
    try {
      await _audioPlayer.stop(); // Stop previous before playing new

      // Create an AudioSource with metadata for the notification
      final audioSource = AudioSource.uri(
        Uri.parse(station.urlResolved),
        tag: MediaItem( // Used by just_audio for notification
          id: station.stationuuid,
          title: station.name,
          artist: station.country ?? station.tags.join(', '),
          artUri: station.favicon != null && station.favicon!.isNotEmpty ? Uri.parse(station.favicon!) : null,
          // For background playback notification configuration
          androidBrowsable: true,
        ),
      );
      // await _audioPlayer.setAudioSource(audioSource); // This is the new way
      // Configure just_audio for background playback notification
      // Note: The setAudioSource should handle this with the MediaItem.
      // However, explicit configuration might be needed if not using audio_service package directly.
      // For now, relying on MediaItem within AudioSource.uri
      await _audioPlayer.setAudioSource(
        audioSource,
        // These are important for just_audio's default notification handling
        // and for background audio behavior on Android.
        // This might be automatically picked up by newer just_audio versions from the manifest if AudioService is declared.
        // but explicitly setting them here if they were part of an older API or for clarity.
        // For modern just_audio, the MediaItem within AudioSource is the primary way.
        // Let's ensure the MediaItem is correctly populated.
        // The below might be redundant if MediaItem is fully utilized by just_audio's notification system.
        // androidNotificationChannelId: GlobalRadioState.androidNotificationChannelId,
        // androidNotificationChannelName: GlobalRadioState.androidNotificationChannelName,
        // androidNotificationIcon: GlobalRadioState.androidNotificationIcon, // e.g. 'mipmap/ic_launcher'
      );

      _audioPlayer.play();
      GlobalRadioState.setCurrentStation(station); // Update global state
      if (mounted) setState(() {}); // Update local UI if needed (e.g. selected item)
    } catch (e) {
      print("Error playing station: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing station: ${e.toString()}')),
      );
      GlobalRadioState.setCurrentStation(null); // Clear global current station
      if (mounted) setState(() {});
    }
  }

  Future<void> _pauseStation() async {
    await _audioPlayer.pause();
  }

  Future<void> _stopStation() async {
    await _audioPlayer.stop();
    GlobalRadioState.setCurrentStation(null); // Clear global current station
    if (mounted) setState(() {});
  }

  @override
  Future<void> _toggleFavorite(RadioStation station) async {
    if (_radioService.isFavorite(station.stationuuid)) {
      await _radioService.removeFavorite(station.stationuuid);
    } else {
      await _radioService.addFavorite(station);
    }
    // Refresh favorite list if currently shown, and update isFavorite state for icons
    await _loadFavorites();
    setState(() {}); // Rebuild to update icons and potentially list
  }

  List<RadioStation> get _displayedStations {
    if (_showFavorites) {
      // Convert FavoriteStation list to RadioStation list for display consistency
      return _favoriteStations.map((fav) => RadioStation(
        stationuuid: fav.stationuuid,
        name: fav.name,
        urlResolved: fav.urlResolved,
        country: fav.country,
        favicon: fav.favicon,
        tags: fav.tags ?? [],
        isFavorite: true, // Explicitly mark as favorite
      )).toList();
    }
    return _apiStations;
  }


  @override
  Widget build(BuildContext context) {
    bool isPlaying = GlobalRadioState.playerState?.playing ?? false;
    ProcessingState? processingState = GlobalRadioState.playerState?.processingState;
    bool isBuffering = processingState == ProcessingState.buffering ||
                       processingState == ProcessingState.loading;
    bool hasError = processingState == ProcessingState.error;
    RadioStation? currentStation = GlobalRadioState.currentStation;
    final stationsToDisplay = _displayedStations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Web Radio'),
        actions: [
          FilterChip(
            label: Text(_showFavorites ? 'Favorites' : 'All Stations', style: Theme.of(context).textTheme.labelLarge), // Themed label
            selected: _showFavorites,
            onSelected: (selected) {
              setState(() {
                _showFavorites = selected;
                if (!_showFavorites && _apiStations.isEmpty) {
                  _fetchInitialApiStations(); // Fetch API stations if switching to all and list is empty
                } else if (_showFavorites) {
                  _loadFavorites(); // Ensure favorites are up-to-date when switching
                }
              });
            },
            selectedColor: Theme.of(context).colorScheme.primaryContainer,
            checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
          )
        ],
      ),
      body: Column(
        children: [
          if (!_showFavorites) _buildSearchField(), // Only show search for All Stations
          _buildPlaybackControls(isPlaying, isBuffering),
          if (_isLoadingStations)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (stationsToDisplay.isEmpty)
             Expanded(child: Center(child: Padding(
               padding: const EdgeInsets.all(16.0),
               child: Text(
                 _showFavorites
                   ? 'No favorite stations yet. Tap the star to add one!'
                   : (_isSearching ? 'No stations found for "${_searchController.text}".' : 'Search for radio stations.'),
                 style: Theme.of(context).textTheme.bodyLarge,
                 textAlign: TextAlign.center,
               ),
             )))
          else
            _buildStationList(stationsToDisplay),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search all stations...',
          suffixIcon: IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              FocusScope.of(context).unfocus();
              _searchApiStations(term: _searchController.text);
            },
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
        onSubmitted: (value) => _searchApiStations(term: value),
      ),
    );
  }

  Widget _buildPlaybackControls(bool isPlaying, bool isBuffering, bool hasError, RadioStation? currentStation) {
    return Card(
      key: const ValueKey('webradio_player_controls'), // Added ValueKey here
      margin: const EdgeInsets.all(8.0),
      elevation: currentStation != null || hasError ? 2.0 : 0.5,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentStation?.name ?? (hasError ? 'Playback Error' : 'No station selected'),
              style: (currentStation != null || hasError
                  ? Theme.of(context).textTheme.titleMedium
                  : Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
              color: hasError ? Theme.of(context).colorScheme.error : null,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            if (currentStation != null && !hasError)
              Text(
                currentStation.countryDisplay,
                style: Theme.of(context).textTheme.bodySmall,
              )
            else if (!hasError)
              Text("Use search above to find stations.", style: Theme.of(context).textTheme.bodySmall),

            if(hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  "Could not play station. Try another.",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 8),
            if (isBuffering)
              const Center(child: CircularProgressIndicator())
            else if (!hasError) // Only show buttons if no error
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    iconSize: 36.0,
                    // Enable play only if a station is selected AND it's not already playing
                    onPressed: currentStation == null || isPlaying ? null : () => _playStation(currentStation),
                    tooltip: 'Play',
                  ),
                  IconButton(
                    icon: const Icon(Icons.pause),
                    iconSize: 36.0,
                    onPressed: isPlaying ? _pauseStation : null,
                    tooltip: 'Pause',
                  ),
                  IconButton(
                    icon: const Icon(Icons.stop),
                    iconSize: 36.0,
                    onPressed: (isPlaying || GlobalRadioState.playerState?.processingState != ProcessingState.idle) ? _stopStation : null,
                    tooltip: 'Stop',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationList(List<RadioStation> stations) {
    RadioStation? currentGlobalStation = GlobalRadioState.currentStation;
    return Expanded(
      child: ListView.builder(
        itemCount: stations.length,
        itemBuilder: (context, index) {
          final station = stations[index];
          bool isCurrentlyPlayingStation = currentGlobalStation?.stationuuid == station.stationuuid;
          bool isFav = _radioService.isFavorite(station.stationuuid);

          return ListTile(
            leading: station.favicon != null && station.favicon!.isNotEmpty
                ? Image.network(station.favicon!, width: 40, height: 40, errorBuilder: (c, o, s) => const Icon(Icons.radio))
                : const Icon(Icons.radio),
            title: Text(
              station.name,
              style: isCurrentlyPlayingStation
                  ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)
                  : Theme.of(context).textTheme.titleMedium
            ),
            subtitle: Text(
              '${station.countryDisplay} - ${station.tags.take(2).join(', ')}',
              style: Theme.of(context).textTheme.bodySmall
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(station.votes != null ? '${station.votes?.toInt()}' : '', style: Theme.of(context).textTheme.bodySmall), // Themed votes
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(isFav ? Icons.star : Icons.star_border, color: isFav ? Colors.amber : Theme.of(context).colorScheme.onSurfaceVariant),
                  onPressed: () => _toggleFavorite(station),
                  tooltip: isFav ? 'Remove from Favorites' : 'Add to Favorites',
                ),
              ],
            ),
            selected: isCurrentlyPlayingStation,
            onTap: () => _playStation(station),
          );
        },
      ),
    );
  }
}
