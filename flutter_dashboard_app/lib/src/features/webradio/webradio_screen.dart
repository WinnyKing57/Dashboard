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

  List<RadioStation> _stations = [];
  bool _isLoadingStations = false;
  // RadioStation? _currentStation is now GlobalRadioState.currentStation;
  // PlayerState? _playerState is now GlobalRadioState.playerState;
  bool _isSearching = false;

  StreamSubscription<PlayerState>? _playerStateSubscription;
  // No need for StreamSubscription for currentStation here, will listen in widget if needed

  @override
  void initState() {
    super.initState();
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        GlobalRadioState.setPlayerState(state); // Update global state
        setState(() {}); // Rebuild to reflect player state changes like play/pause button state
      }
    });
     // Listen to global current station changes if needed by this screen directly for UI updates
    // For example, if another part of the app could change the station.
    // GlobalRadioState.currentStationStream.listen((station) {
    //   if (mounted) setState(() {});
    // });
    _fetchInitialStations(); // Fetch some stations on init
  }

  @override
  void dispose() {
    _searchController.dispose();
    _playerStateSubscription?.cancel();
    // Do not dispose the global player here, it might be used by other widgets.
    // _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialStations() async {
    // Fetch some popular stations by default, e.g., by a common tag or just top voted
    _searchStations(term: "jazz"); // Example: initial search for "jazz"
  }

  Future<void> _searchStations({String term = '', String countryCode = '', String tag = ''}) async {
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
          _stations = stations;
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
  Widget build(BuildContext context) {
    // Use global state for isPlaying and isBuffering
    bool isPlaying = GlobalRadioState.playerState?.playing ?? false;
    bool isBuffering = GlobalRadioState.playerState?.processingState == ProcessingState.buffering ||
                       GlobalRadioState.playerState?.processingState == ProcessingState.loading;
    RadioStation? currentStation = GlobalRadioState.currentStation;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Web Radio'),
      ),
      body: Column(
        children: [
          _buildSearchField(),
          _buildPlaybackControls(isPlaying, isBuffering),
          if (_isLoadingStations)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_stations.isEmpty && _isSearching)
             Expanded(child: Center(child: Text('No stations found for "${_searchController.text}".')))
          else if (_stations.isEmpty && !_isSearching)
             const Expanded(child: Center(child: Text('Search for radio stations above.')))
          else
            _buildStationList(),
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
          hintText: 'Search stations by name, tag, country...',
          suffixIcon: IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              FocusScope.of(context).unfocus(); // Hide keyboard
              _searchStations(term: _searchController.text);
            },
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
        onSubmitted: (value) => _searchStations(term: value),
      ),
    );
  }

  Widget _buildPlaybackControls(bool isPlaying, bool isBuffering, RadioStation? currentStation) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      // Make controls less prominent if no station is selected/playing
      elevation: currentStation != null ? 2.0 : 0.5,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentStation?.name ?? 'No station selected',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: currentStation != null ? null : Colors.grey
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            if (currentStation != null)
              Text(
                currentStation.countryDisplay,
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              Text("Use search above to find stations.", style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            if (isBuffering)
              const Center(child: CircularProgressIndicator())
            else
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

  Widget _buildStationList() {
    RadioStation? currentStation = GlobalRadioState.currentStation; // Get current global station
    return Expanded(
      child: ListView.builder(
        itemCount: _stations.length,
        itemBuilder: (context, index) {
          final station = _stations[index];
          bool isCurrentlyPlayingStation = currentStation?.stationuuid == station.stationuuid;
          return ListTile(
            leading: station.favicon != null && station.favicon!.isNotEmpty
                ? Image.network(station.favicon!, width: 40, height: 40, errorBuilder: (c, o, s) => const Icon(Icons.radio))
                : const Icon(Icons.radio),
            title: Text(station.name, style: TextStyle(fontWeight: isCurrentlyPlayingStation ? FontWeight.bold : FontWeight.normal)),
            subtitle: Text('${station.countryDisplay} - ${station.tags.take(2).join(', ')}'),
            trailing: Text('${station.votes ?? 0} votes'),
            selected: isCurrentlyPlayingStation,
            onTap: () => _playStation(station),
          );
        },
      ),
    );
  }
}
