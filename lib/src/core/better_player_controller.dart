import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:better_player/better_player.dart';
import 'package:better_player/src/configuration/better_player_controller_event.dart';
import 'package:better_player/src/core/better_player_utils.dart';
import 'package:better_player/src/subtitles/better_player_subtitle.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_factory.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:better_player/src/video_player/video_player_platform_interface.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

///Class used to control overall Better Player behavior. Main class to change
///state of Better Player.
class BetterPlayerController {
  static const String _durationParameter = "duration";
  static const String _progressParameter = "progress";
  static const String _bufferedParameter = "buffered";
  static const String _volumeParameter = "volume";
  static const String _speedParameter = "speed";
  static const String _dataSourceParameter = "dataSource";
  static const String _authorizationHeader = "Authorization";

  ///General configuration used in controller instance.
  final BetterPlayerConfiguration betterPlayerConfiguration;

  ///Playlist configuration used in controller instance.
  final BetterPlayerPlaylistConfiguration? betterPlayerPlaylistConfiguration;

  ///List of event listeners, which listen to events.
  final List<Function(BetterPlayerEvent)?> _eventListeners = [];

  ///List of files to delete once player disposes.
  final List<File> _tempFiles = [];

  ///Stream controller which emits stream when control visibility changes.
  final StreamController<bool> _controlsVisibilityStreamController =
      StreamController.broadcast();

  ///Instance of video player controller which is adapter used to communicate
  ///between flutter high level code and lower level native code.
  VideoPlayerController? videoPlayerController;

  ///Controls configuration
  late BetterPlayerControlsConfiguration _betterPlayerControlsConfiguration;

  ///Controls configuration
  BetterPlayerControlsConfiguration get betterPlayerControlsConfiguration =>
      _betterPlayerControlsConfiguration;

  ///Expose all active eventListeners. Skips the first (configuration) listener
  ///without allocating a new list on every access.
  Iterable<Function(BetterPlayerEvent)?> get eventListeners =>
      _eventListeners.skip(1);

  /// Defines a event listener where video player events will be send.
  Function(BetterPlayerEvent)? get eventListener =>
      betterPlayerConfiguration.eventListener;

  ///Flag used to store full screen mode state.
  bool _isFullScreen = false;

  ///Flag used to store full screen mode state.
  bool get isFullScreen => _isFullScreen;

  ///Time when last progress event was sent
  int _lastPositionSelection = 0;

  ///Currently used data source in player.
  BetterPlayerDataSource? _betterPlayerDataSource;

  ///Currently used data source in player.
  BetterPlayerDataSource? get betterPlayerDataSource => _betterPlayerDataSource;

  ///List of BetterPlayerSubtitlesSources.
  final List<BetterPlayerSubtitlesSource> _betterPlayerSubtitlesSourceList = [];

  ///List of BetterPlayerSubtitlesSources.
  List<BetterPlayerSubtitlesSource> get betterPlayerSubtitlesSourceList =>
      UnmodifiableListView<BetterPlayerSubtitlesSource>(
          _betterPlayerSubtitlesSourceList);
  BetterPlayerSubtitlesSource? _betterPlayerSubtitlesSource;

  ///Currently used subtitles source.
  BetterPlayerSubtitlesSource? get betterPlayerSubtitlesSource =>
      _betterPlayerSubtitlesSource;

  ///Subtitles lines for current data source.
  List<BetterPlayerSubtitle> subtitlesLines = [];

  ///List of tracks available for current data source. Used only for HLS / DASH.
  List<BetterPlayerAsmsTrack> _betterPlayerAsmsTracks = [];

  ///List of tracks available for current data source. Used only for HLS / DASH.
  List<BetterPlayerAsmsTrack> get betterPlayerAsmsTracks =>
      UnmodifiableListView<BetterPlayerAsmsTrack>(_betterPlayerAsmsTracks);

  ///Currently selected player track. Used only for HLS / DASH.
  BetterPlayerAsmsTrack? _betterPlayerAsmsTrack;

  ///Currently selected player track. Used only for HLS / DASH.
  BetterPlayerAsmsTrack? get betterPlayerAsmsTrack => _betterPlayerAsmsTrack;

  ///Timer for next video. Used in playlist.
  Timer? _nextVideoTimer;

  ///Time for next video.
  int? _nextVideoTime;

  ///Stream controller which emits next video time.
  final StreamController<int?> _nextVideoTimeStreamController =
      StreamController.broadcast();

  Stream<int?> get nextVideoTimeStream => _nextVideoTimeStreamController.stream;

  ///Has player been disposed.
  bool _disposed = false;

  ///Was player playing before automatic pause.
  bool? _wasPlayingBeforePause;

  ///Currently used translations
  BetterPlayerTranslations translations = BetterPlayerTranslations();

  ///Has current data source started
  bool _hasCurrentDataSourceStarted = false;

  ///Has current data source initialized
  bool _hasCurrentDataSourceInitialized = false;

  ///Stream which sends flag whenever visibility of controls changes
  Stream<bool> get controlsVisibilityStream =>
      _controlsVisibilityStreamController.stream;

  ///Current app lifecycle state.
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  ///Flag which determines if controls (UI interface) is shown. When false,
  ///UI won't be shown (show only player surface).
  bool _controlsEnabled = true;

  ///Flag which determines if controls (UI interface) is shown. When false,
  ///UI won't be shown (show only player surface).
  bool get controlsEnabled => _controlsEnabled;

  ///Overridden aspect ratio which will be used instead of aspect ratio passed
  ///in configuration.
  double? _overriddenAspectRatio;

  ///Overridden fit which will be used instead of fit passed in configuration.
  BoxFit? _overriddenFit;

  ///Was Picture in Picture opened.
  bool _wasInPipMode = false;

  ///Was player in fullscreen before Picture in Picture opened.
  bool _wasInFullScreenBeforePiP = false;

  ///Was controls enabled before Picture in Picture opened.
  bool _wasControlsEnabledBeforePiP = false;

  ///GlobalKey of the BetterPlayer widget
  GlobalKey? _betterPlayerGlobalKey;

  ///Getter of the GlobalKey
  GlobalKey? get betterPlayerGlobalKey => _betterPlayerGlobalKey;

  ///StreamSubscription for VideoEvent listener
  StreamSubscription<VideoEvent>? _videoEventStreamSubscription;

  ///Are controls always visible
  bool _controlsAlwaysVisible = false;

  ///Are controls always visible
  bool get controlsAlwaysVisible => _controlsAlwaysVisible;

  ///List of all possible audio tracks returned from ASMS stream
  List<BetterPlayerAsmsAudioTrack>? _betterPlayerAsmsAudioTracks;

  ///List of all possible audio tracks returned from ASMS stream
  List<BetterPlayerAsmsAudioTrack>? get betterPlayerAsmsAudioTracks =>
      _betterPlayerAsmsAudioTracks;

  ///Selected ASMS audio track
  BetterPlayerAsmsAudioTrack? _betterPlayerAsmsAudioTrack;

  ///Selected ASMS audio track
  BetterPlayerAsmsAudioTrack? get betterPlayerAsmsAudioTrack =>
      _betterPlayerAsmsAudioTrack;

  ///Selected videoPlayerValue when error occurred.
  VideoPlayerValue? _videoPlayerValueOnError;

  ///Flag which holds information about player visibility
  bool _isPlayerVisible = true;

  final StreamController<BetterPlayerControllerEvent>
      _controllerEventStreamController = StreamController.broadcast();

  ///Stream of internal controller events. Shouldn't be used inside app. For
  ///normal events, use eventListener.
  Stream<BetterPlayerControllerEvent> get controllerEventStream =>
      _controllerEventStreamController.stream;

  ///Flag which determines whether are ASMS segments loading
  bool _asmsSegmentsLoading = false;

  ///List of loaded ASMS segments
  final Set<String> _asmsSegmentsLoaded = <String>{};

  ///Currently displayed [BetterPlayerSubtitle].
  BetterPlayerSubtitle? renderedSubtitle;

  BetterPlayerController(
    this.betterPlayerConfiguration, {
    this.betterPlayerPlaylistConfiguration,
    BetterPlayerDataSource? betterPlayerDataSource,
  }) {
    this._betterPlayerControlsConfiguration =
        betterPlayerConfiguration.controlsConfiguration;
    _eventListeners.add(eventListener);
    if (betterPlayerDataSource != null) {
      setupDataSource(betterPlayerDataSource);
    }
  }

  ///Get BetterPlayerController from context. Used in InheritedWidget.
  static BetterPlayerController of(BuildContext context) {
    final betterPLayerControllerProvider = context
        .dependOnInheritedWidgetOfExactType<BetterPlayerControllerProvider>()!;

    return betterPLayerControllerProvider.controller;
  }

  ///Setup new data source in Better Player.
  Future setupDataSource(BetterPlayerDataSource betterPlayerDataSource) async {
    postEvent(BetterPlayerEvent(BetterPlayerEventType.setupDataSource,
        parameters: <String, dynamic>{
          _dataSourceParameter: betterPlayerDataSource,
        }));
    _postControllerEvent(BetterPlayerControllerEvent.setupDataSource);
    _hasCurrentDataSourceStarted = false;
    _hasCurrentDataSourceInitialized = false;
    _betterPlayerDataSource = betterPlayerDataSource;
    _betterPlayerSubtitlesSourceList.clear();

    ///Build videoPlayerController if null
    if (videoPlayerController == null) {
      videoPlayerController = VideoPlayerController(
        bufferingConfiguration: betterPlayerDataSource.bufferingConfiguration,
      );
      // iOS only: Even though the player is being created at this moment,
      // we let OS know to mix with others before the player is created, so we don't
      // mute other sources at all. Audio session mix is not connected with the player.
      if (Platform.isIOS) {
        videoPlayerController
            ?.setMixWithOthers(betterPlayerConfiguration.mixWithOthers);
      }

      videoPlayerController?.addListener(_onVideoPlayerChanged);
    }

    ///Clear asms tracks
    _betterPlayerAsmsTracks.clear();

    ///Setup subtitles
    final List<BetterPlayerSubtitlesSource>? betterPlayerSubtitlesSourceList =
        betterPlayerDataSource.subtitles;
    if (betterPlayerSubtitlesSourceList != null) {
      _betterPlayerSubtitlesSourceList
          .addAll(betterPlayerDataSource.subtitles!);
    }

    if (_isDataSourceAsms(betterPlayerDataSource)) {
      _setupAsmsDataSource(betterPlayerDataSource).then((dynamic value) {
        _setupSubtitles();
      });
    } else {
      _setupSubtitles();
    }

    ///Process data source
    await _setupDataSource(betterPlayerDataSource);
    setTrack(BetterPlayerAsmsTrack.defaultTrack());
  }

  ///Configure subtitles based on subtitles source.
  void _setupSubtitles() {
    _betterPlayerSubtitlesSourceList.add(
      BetterPlayerSubtitlesSource(type: BetterPlayerSubtitlesSourceType.none),
    );
    final defaultSubtitle = _betterPlayerSubtitlesSourceList
        .firstWhereOrNull((element) => element.selectedByDefault == true);

    ///Setup subtitles (none is default)
    setupSubtitleSource(
        defaultSubtitle ?? _betterPlayerSubtitlesSourceList.last,
        sourceInitialize: true);
  }

  ///Check if given [betterPlayerDataSource] is HLS / DASH-type data source.
  bool _isDataSourceAsms(BetterPlayerDataSource betterPlayerDataSource) =>
      (BetterPlayerAsmsUtils.isDataSourceHls(betterPlayerDataSource.url) ||
          betterPlayerDataSource.videoFormat == BetterPlayerVideoFormat.hls) ||
      (BetterPlayerAsmsUtils.isDataSourceDash(betterPlayerDataSource.url) ||
          betterPlayerDataSource.videoFormat == BetterPlayerVideoFormat.dash);

  ///Configure HLS / DASH data source based on provided data source and configuration.
  ///This method configures tracks, subtitles and audio tracks from given
  ///master playlist.
  Future _setupAsmsDataSource(BetterPlayerDataSource source) async {
    final String? data = await BetterPlayerAsmsUtils.getDataFromUrl(
      betterPlayerDataSource!.url,
      _getHeaders(),
    );
    if (data != null) {
      final BetterPlayerAsmsDataHolder _response =
          await BetterPlayerAsmsUtils.parse(data, betterPlayerDataSource!.url);

      /// Load tracks
      if (_betterPlayerDataSource?.useAsmsTracks == true) {
        _betterPlayerAsmsTracks = _response.tracks ?? [];
      }

      /// Load subtitles
      if (betterPlayerDataSource?.useAsmsSubtitles == true) {
        final List<BetterPlayerAsmsSubtitle> asmsSubtitles =
            _response.subtitles ?? [];
        asmsSubtitles.forEach((BetterPlayerAsmsSubtitle asmsSubtitle) {
          _betterPlayerSubtitlesSourceList.add(
            BetterPlayerSubtitlesSource(
              type: BetterPlayerSubtitlesSourceType.network,
              name: asmsSubtitle.name,
              urls: asmsSubtitle.realUrls,
              asmsIsSegmented: asmsSubtitle.isSegmented,
              asmsSegmentsTime: asmsSubtitle.segmentsTime,
              asmsSegments: asmsSubtitle.segments,
              selectedByDefault: asmsSubtitle.isDefault,
            ),
          );
        });
      }

      ///Load audio tracks
      if (betterPlayerDataSource?.useAsmsAudioTracks == true &&
          _isDataSourceAsms(betterPlayerDataSource!)) {
        _betterPlayerAsmsAudioTracks = _response.audios ?? [];
        if (_betterPlayerAsmsAudioTracks?.isNotEmpty == true) {
          setAudioTrack(_betterPlayerAsmsAudioTracks!.first);
        }
      }
    }
  }

  ///Setup subtitles to be displayed from given subtitle source.
  ///If subtitles source is segmented then don't load videos at start. Videos
  ///will load with just in time policy.
  Future<void> setupSubtitleSource(BetterPlayerSubtitlesSource subtitlesSource,
      {bool sourceInitialize = false}) async {
    _betterPlayerSubtitlesSource = subtitlesSource;
    subtitlesLines.clear();
    _asmsSegmentsLoaded.clear();
    _asmsSegmentsLoading = false;

    if (subtitlesSource.type != BetterPlayerSubtitlesSourceType.none) {
      if (subtitlesSource.asmsIsSegmented == true) {
        return;
      }
      final subtitlesParsed =
          await BetterPlayerSubtitlesFactory.parseSubtitles(subtitlesSource);
      subtitlesLines.addAll(subtitlesParsed);
    }

    _postEvent(BetterPlayerEvent(BetterPlayerEventType.changedSubtitles));
    if (!_disposed && !sourceInitialize) {
      _postControllerEvent(BetterPlayerControllerEvent.changeSubtitles);
    }
  }

  ///Load ASMS subtitles segments for given [position].
  ///Segments are being loaded within range (current video position;endPosition)
  ///where endPosition is based on time segment detected in HLS playlist. If
  ///time segment is not present then 5000 ms will be used. Also time segment
  ///is multiplied by 5 to increase window of duration.
  ///Segments are also cached, so same segment won't load twice. Only one
  ///pack of segments can be load at given time.
  Future _loadAsmsSubtitlesSegments(Duration position) async {
    try {
      if (_asmsSegmentsLoading) {
        return;
      }
      _asmsSegmentsLoading = true;
      final BetterPlayerSubtitlesSource? source = _betterPlayerSubtitlesSource;
      final Duration loadDurationEnd = Duration(
          milliseconds: position.inMilliseconds +
              5 * (_betterPlayerSubtitlesSource?.asmsSegmentsTime ?? 5000));

      final segmentsToLoad = _betterPlayerSubtitlesSource?.asmsSegments
          ?.where((segment) {
            return segment.startTime > position &&
                segment.endTime < loadDurationEnd &&
                !_asmsSegmentsLoaded.contains(segment.realUrl);
          })
          .map((segment) => segment.realUrl)
          .toList();

      if (segmentsToLoad != null && segmentsToLoad.isNotEmpty) {
        final subtitlesParsed =
            await BetterPlayerSubtitlesFactory.parseSubtitles(
                BetterPlayerSubtitlesSource(
          type: _betterPlayerSubtitlesSource!.type,
          headers: _betterPlayerSubtitlesSource!.headers,
          urls: segmentsToLoad,
        ));

        ///Additional check if current source of subtitles is same as source
        ///used to start loading subtitles. It can be different when user
        ///changes subtitles and there was already pending load.
        if (source == _betterPlayerSubtitlesSource) {
          subtitlesLines.addAll(subtitlesParsed);
          _asmsSegmentsLoaded.addAll(segmentsToLoad);
        }
      }
      _asmsSegmentsLoading = false;
    } catch (exception) {
      BetterPlayerUtils.log("Load ASMS subtitle segments failed: $exception");
    }
  }

  ///Get VideoFormat from BetterPlayerVideoFormat (adapter method which translates
  ///to video_player supported format).
  VideoFormat? _getVideoFormat(
      BetterPlayerVideoFormat? betterPlayerVideoFormat) {
    if (betterPlayerVideoFormat == null) {
      return null;
    }
    switch (betterPlayerVideoFormat) {
      case BetterPlayerVideoFormat.dash:
        return VideoFormat.dash;
      case BetterPlayerVideoFormat.hls:
        return VideoFormat.hls;
      case BetterPlayerVideoFormat.ss:
        return VideoFormat.ss;
      case BetterPlayerVideoFormat.other:
        return VideoFormat.other;
    }
  }

  ///Internal method which invokes videoPlayerController source setup.
  Future _setupDataSource(BetterPlayerDataSource betterPlayerDataSource) async {
    switch (betterPlayerDataSource.type) {
      case BetterPlayerDataSourceType.network:
        try {
          await videoPlayerController?.setNetworkDataSource(
            betterPlayerDataSource.url,
            headers: _getHeaders(),
            useCache:
                _betterPlayerDataSource!.cacheConfiguration?.useCache ?? false,
            maxCacheSize:
                _betterPlayerDataSource!.cacheConfiguration?.maxCacheSize ?? 0,
            maxCacheFileSize:
                _betterPlayerDataSource!.cacheConfiguration?.maxCacheFileSize ??
                    0,
            cacheKey: _betterPlayerDataSource?.cacheConfiguration?.key,
            showNotification: _betterPlayerDataSource
                ?.notificationConfiguration?.showNotification,
            title: _betterPlayerDataSource?.notificationConfiguration?.title,
            author: _betterPlayerDataSource?.notificationConfiguration?.author,
            imageUrl:
                _betterPlayerDataSource?.notificationConfiguration?.imageUrl,
            notificationChannelName: _betterPlayerDataSource
                ?.notificationConfiguration?.notificationChannelName,
            overriddenDuration: _betterPlayerDataSource!.overriddenDuration,
            formatHint: _getVideoFormat(_betterPlayerDataSource!.videoFormat),
            licenseUrl: _betterPlayerDataSource?.drmConfiguration?.licenseUrl,
            certificateUrl:
                _betterPlayerDataSource?.drmConfiguration?.certificateUrl,
            drmHeaders: _betterPlayerDataSource?.drmConfiguration?.headers,
            activityName: _betterPlayerDataSource
                ?.notificationConfiguration?.activityName,
            clearKey: _betterPlayerDataSource?.drmConfiguration?.clearKey,
            videoExtension: _betterPlayerDataSource!.videoExtension,
          );
        } catch (e) {
          BetterPlayerUtils.log("Failed to setup network data source: $e");
        }
        break;
      case BetterPlayerDataSourceType.file:
        try {
          final file = File(betterPlayerDataSource.url);
          if (!file.existsSync()) {
            BetterPlayerUtils.log(
                "File ${file.path} doesn't exists. This may be because "
                "you're accessing file from native path and Flutter doesn't "
                "recognize this path.");
            return;
          }

          await videoPlayerController?.setFileDataSource(
              File(betterPlayerDataSource.url),
              showNotification: _betterPlayerDataSource
                  ?.notificationConfiguration?.showNotification,
              title: _betterPlayerDataSource?.notificationConfiguration?.title,
              author:
                  _betterPlayerDataSource?.notificationConfiguration?.author,
              imageUrl:
                  _betterPlayerDataSource?.notificationConfiguration?.imageUrl,
              notificationChannelName: _betterPlayerDataSource
                  ?.notificationConfiguration?.notificationChannelName,
              overriddenDuration: _betterPlayerDataSource!.overriddenDuration,
              activityName: _betterPlayerDataSource
                  ?.notificationConfiguration?.activityName,
              clearKey: _betterPlayerDataSource?.drmConfiguration?.clearKey);
        } catch (e) {
          BetterPlayerUtils.log("Failed to setup file data source: $e");
        }
        break;
      case BetterPlayerDataSourceType.memory:
        try {
          final file = await _createFile(_betterPlayerDataSource!.bytes!,
              extension: _betterPlayerDataSource!.videoExtension);

          if (file.existsSync()) {
            await videoPlayerController?.setFileDataSource(file,
                showNotification: _betterPlayerDataSource
                    ?.notificationConfiguration?.showNotification,
                title:
                    _betterPlayerDataSource?.notificationConfiguration?.title,
                author:
                    _betterPlayerDataSource?.notificationConfiguration?.author,
                imageUrl: _betterPlayerDataSource
                    ?.notificationConfiguration?.imageUrl,
                notificationChannelName: _betterPlayerDataSource
                    ?.notificationConfiguration?.notificationChannelName,
                overriddenDuration: _betterPlayerDataSource!.overriddenDuration,
                activityName: _betterPlayerDataSource
                    ?.notificationConfiguration?.activityName,
                clearKey: _betterPlayerDataSource?.drmConfiguration?.clearKey);
            _tempFiles.add(file);
          } else {
            BetterPlayerUtils.log("Couldn't create file from memory.");
          }
        } catch (e) {
          BetterPlayerUtils.log("Failed to setup memory data source: $e");
        }
        break;
    }
    await _initializeVideo();
  }

  ///Create file from provided list of bytes. File will be created in temporary
  ///directory.
  Future<File> _createFile(List<int> bytes,
      {String? extension = "temp"}) async {
    try {
      final String dir = (await getTemporaryDirectory()).path;
      final File temp = File(
          '$dir/better_player_${DateTime.now().millisecondsSinceEpoch}.$extension');
      await temp.writeAsBytes(bytes);
      return temp;
    } catch (e) {
      BetterPlayerUtils.log("Failed to create temporary file: $e");
      rethrow;
    }
  }

  ///Initializes video based on configuration. Invoke actions which need to be
  ///run on player start.
  Future _initializeVideo() async {
    setLooping(betterPlayerConfiguration.looping);
    _videoEventStreamSubscription?.cancel();
    _videoEventStreamSubscription = null;

    _videoEventStreamSubscription = videoPlayerController
        ?.videoEventStreamController.stream
        .listen(_handleVideoEvent);

    final fullScreenByDefault = betterPlayerConfiguration.fullScreenByDefault;
    if (betterPlayerConfiguration.autoPlay) {
      if (fullScreenByDefault && !isFullScreen) {
        enterFullScreen();
      }
      if (_isAutomaticPlayPauseHandled()) {
        if (_appLifecycleState == AppLifecycleState.resumed &&
            _isPlayerVisible) {
          await play();
        } else {
          _wasPlayingBeforePause = true;
        }
      } else {
        await play();
      }
    } else {
      if (fullScreenByDefault) {
        enterFullScreen();
      }
    }

    // Force orientation constraints for portrait videos
    _applyOrientationConstraintsForVideo();

    final startAt = betterPlayerConfiguration.startAt;
    if (startAt != null) {
      seekTo(startAt);
    }
  }

  ///Apply orientation constraints based on video type
  void _applyOrientationConstraintsForVideo() {
    final aspectRatio = videoPlayerController?.value.aspectRatio ?? 1.0;

    if (betterPlayerConfiguration.autoDetectFullscreenDeviceOrientation) {
      if (_isPortraitVideo(aspectRatio)) {
        _applyPortraitVideoOrientationConstraints();
      } else {
        _applyLandscapeVideoOrientationConstraints();
      }
    }
  }

  ///Check if video is portrait based on aspect ratio
  bool _isPortraitVideo(double aspectRatio) {
    return aspectRatio <= 4.0 / 3.0;
  }

  ///Apply orientation constraints for portrait videos
  void _applyPortraitVideoOrientationConstraints() {
    BetterPlayerUtils.log("Portrait video - Applying orientation constraints");
    // Force portrait orientation for portrait videos
    // Skip if currently in fullscreen to avoid overriding manual fullscreen orientation
    if (_isFullScreen) {
      return;
    }
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  ///Apply orientation constraints for landscape videos
  void _applyLandscapeVideoOrientationConstraints() {
    BetterPlayerUtils.log(
        "Landscape video - Applying orientation constraints (allowing all orientations)");
    // Allow all orientations for landscape videos to enable rotation
    // Skip if currently in fullscreen to avoid overriding manual fullscreen orientation
    if (_isFullScreen) {
      return;
    }
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  ///Method which is invoked when full screen changes.
  Future<void> _onFullScreenStateChanged() async {
    if (videoPlayerController?.value.isPlaying == true && !_isFullScreen) {
      enterFullScreen();
      videoPlayerController?.removeListener(_onFullScreenStateChanged);
    }
  }

  ///Enables full screen mode in player. This will trigger route change.
  void enterFullScreen() {
    _isFullScreen = true;
    _postControllerEvent(BetterPlayerControllerEvent.openFullscreen);
  }

  ///Disables full screen mode in player. This will trigger route change.
  void exitFullScreen() {
    _isFullScreen = false;
    _postControllerEvent(BetterPlayerControllerEvent.hideFullscreen);
  }

  ///Enables/disables full screen mode based on current fullscreen state.
  void toggleFullScreen() {
    _isFullScreen = !_isFullScreen;
    if (_isFullScreen) {
      _postControllerEvent(BetterPlayerControllerEvent.openFullscreen);
    } else {
      _postControllerEvent(BetterPlayerControllerEvent.hideFullscreen);
    }
  }

  ///Start video playback. Play will be triggered only if current lifecycle state
  ///is resumed.
  Future<void> play() async {
    if (videoPlayerController == null) {
      throw StateError("The data source has not been initialized");
    }

    if (_appLifecycleState == AppLifecycleState.resumed) {
      await videoPlayerController!.play();
      _hasCurrentDataSourceStarted = true;
      _wasPlayingBeforePause = null;
      _postEvent(BetterPlayerEvent(BetterPlayerEventType.play));
      _postControllerEvent(BetterPlayerControllerEvent.play);
    }
  }

  ///Enables/disables looping (infinity playback) mode.
  Future<void> setLooping(bool looping) async {
    if (videoPlayerController == null) {
      throw StateError("The data source has not been initialized");
    }

    await videoPlayerController!.setLooping(looping);
  }

  ///Stop video playback.
  Future<void> pause() async {
    if (videoPlayerController == null) {
      throw StateError("The data source has not been initialized");
    }

    await videoPlayerController!.pause();
    _postEvent(BetterPlayerEvent(BetterPlayerEventType.pause));
  }

  ///Move player to specific position/moment of the video.
  Future<void> seekTo(Duration moment) async {
    if (videoPlayerController == null) {
      throw StateError("The data source has not been initialized");
    }
    if (videoPlayerController?.value.duration == null) {
      throw StateError("The video has not been initialized yet.");
    }

    await videoPlayerController!.seekTo(moment);

    _postEvent(BetterPlayerEvent(BetterPlayerEventType.seekTo,
        parameters: <String, dynamic>{_durationParameter: moment}));

    final Duration? currentDuration = videoPlayerController!.value.duration;
    if (currentDuration == null) {
      return;
    }
    if (moment > currentDuration) {
      _postEvent(BetterPlayerEvent(BetterPlayerEventType.finished));
    } else {
      cancelNextVideoTimer();
    }
  }

  ///Set volume of player. Allows values from 0.0 to 1.0.
  Future<void> setVolume(double volume) async {
    if (volume < 0.0 || volume > 1.0) {
      BetterPlayerUtils.log("Volume must be between 0.0 and 1.0");
      throw ArgumentError("Volume must be between 0.0 and 1.0");
    }
    if (videoPlayerController == null) {
      BetterPlayerUtils.log("The data source has not been initialized");
      throw StateError("The data source has not been initialized");
    }
    await videoPlayerController!.setVolume(volume);
    _postEvent(BetterPlayerEvent(
      BetterPlayerEventType.setVolume,
      parameters: <String, dynamic>{_volumeParameter: volume},
    ));
  }

  ///Set playback speed of video. Allows to set speed value between 0 and 2.
  Future<void> setSpeed(double speed) async {
    if (speed <= 0 || speed > 2) {
      BetterPlayerUtils.log("Speed must be between 0 and 2");
      throw ArgumentError("Speed must be between 0 and 2");
    }
    if (videoPlayerController == null) {
      BetterPlayerUtils.log("The data source has not been initialized");
      throw StateError("The data source has not been initialized");
    }
    await videoPlayerController?.setSpeed(speed);
    _postEvent(
      BetterPlayerEvent(
        BetterPlayerEventType.setSpeed,
        parameters: <String, dynamic>{
          _speedParameter: speed,
        },
      ),
    );
  }

  ///Flag which determines whenever player is playing or not.
  bool? isPlaying() {
    if (videoPlayerController == null) {
      throw StateError("The data source has not been initialized");
    }
    return videoPlayerController!.value.isPlaying;
  }

  ///Flag which determines whenever player is loading video data or not.
  bool? isBuffering() {
    if (videoPlayerController == null) {
      throw StateError("The data source has not been initialized");
    }
    return videoPlayerController!.value.isBuffering;
  }

  ///Show or hide controls manually
  void setControlsVisibility(bool isVisible) {
    _controlsVisibilityStreamController.add(isVisible);
  }

  ///Enable/disable controls (when enabled = false, controls will be always hidden)
  void setControlsEnabled(bool enabled) {
    if (!enabled) {
      _controlsVisibilityStreamController.add(false);
    }
    _controlsEnabled = enabled;
  }

  ///Internal method, used to trigger CONTROLS_VISIBLE or CONTROLS_HIDDEN event
  ///once controls state changed.
  void toggleControlsVisibility(bool isVisible) {
    _postEvent(isVisible
        ? BetterPlayerEvent(BetterPlayerEventType.controlsVisible)
        : BetterPlayerEvent(BetterPlayerEventType.controlsHiddenEnd));
  }

  ///Send player event. Shouldn't be used manually.
  void postEvent(BetterPlayerEvent betterPlayerEvent) {
    _postEvent(betterPlayerEvent);
  }

  ///Send player event to all listeners.
  void _postEvent(BetterPlayerEvent betterPlayerEvent) {
    for (final Function(BetterPlayerEvent)? eventListener in _eventListeners) {
      if (eventListener != null) {
        eventListener(betterPlayerEvent);
      }
    }
  }

  ///Listener used to handle video player changes.
  void _onVideoPlayerChanged() async {
    final VideoPlayerValue currentVideoPlayerValue =
        videoPlayerController?.value ??
            VideoPlayerValue(duration: const Duration());

    if (currentVideoPlayerValue.hasError) {
      _videoPlayerValueOnError ??= currentVideoPlayerValue;
      _postEvent(
        BetterPlayerEvent(
          BetterPlayerEventType.exception,
          parameters: <String, dynamic>{
            "exception": currentVideoPlayerValue.errorDescription
          },
        ),
      );
    }
    if (currentVideoPlayerValue.initialized &&
        !_hasCurrentDataSourceInitialized) {
      _hasCurrentDataSourceInitialized = true;
      _postEvent(BetterPlayerEvent(BetterPlayerEventType.initialized));
    }
    if (currentVideoPlayerValue.isPip) {
      _wasInPipMode = true;
    } else if (_wasInPipMode) {
      _postEvent(BetterPlayerEvent(BetterPlayerEventType.pipStop));
      _wasInPipMode = false;
      if (!_wasInFullScreenBeforePiP) {
        exitFullScreen();
      }
      if (_wasControlsEnabledBeforePiP) {
        setControlsEnabled(true);
      }
      videoPlayerController?.refresh();
    }

    if (_betterPlayerSubtitlesSource?.asmsIsSegmented == true) {
      _loadAsmsSubtitlesSegments(currentVideoPlayerValue.position);
    }

    final int now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastPositionSelection > 500) {
      _lastPositionSelection = now;
      _postEvent(
        BetterPlayerEvent(
          BetterPlayerEventType.progress,
          parameters: <String, dynamic>{
            _progressParameter: currentVideoPlayerValue.position,
            _durationParameter: currentVideoPlayerValue.duration
          },
        ),
      );
    }
  }

  ///Add event listener which listens to player events.
  void addEventsListener(Function(BetterPlayerEvent) eventListener) {
    _eventListeners.add(eventListener);
  }

  ///Remove event listener. This method should be called once you're disposing
  ///Better Player.
  void removeEventsListener(Function(BetterPlayerEvent) eventListener) {
    _eventListeners.remove(eventListener);
  }

  ///Flag which determines whenever player is playing live data source.
  bool isLiveStream() {
    if (_betterPlayerDataSource == null) {
      BetterPlayerUtils.log("The data source has not been initialized");
      throw StateError("The data source has not been initialized");
    }
    return _betterPlayerDataSource!.liveStream == true;
  }

  ///Flag which determines whenever player data source has been initialized.
  bool? isVideoInitialized() {
    if (videoPlayerController == null) {
      BetterPlayerUtils.log("The data source has not been initialized");
      throw StateError("The data source has not been initialized");
    }
    return videoPlayerController?.value.initialized;
  }

  ///Start timer which will trigger next video. Used in playlist. Do not use
  ///manually.
  void startNextVideoTimer() {
    if (_nextVideoTimer == null) {
      if (betterPlayerPlaylistConfiguration == null) {
        BetterPlayerUtils.log(
            "BetterPlayerPlaylistConfiguration has not been set!");
        throw StateError("BetterPlayerPlaylistConfiguration has not been set!");
      }

      _nextVideoTime =
          betterPlayerPlaylistConfiguration!.nextVideoDelay.inSeconds;
      _nextVideoTimeStreamController.add(_nextVideoTime);
      if (_nextVideoTime == 0) {
        return;
      }

      _nextVideoTimer =
          Timer.periodic(const Duration(milliseconds: 1000), (_timer) async {
        if (_nextVideoTime == 1) {
          _timer.cancel();
          _nextVideoTimer = null;
        }
        if (_nextVideoTime != null) {
          _nextVideoTime = _nextVideoTime! - 1;
        }
        _nextVideoTimeStreamController.add(_nextVideoTime);
      });
    }
  }

  ///Cancel next video timer. Used in playlist. Do not use manually.
  void cancelNextVideoTimer() {
    _nextVideoTime = null;
    _nextVideoTimeStreamController.add(_nextVideoTime);
    _nextVideoTimer?.cancel();
    _nextVideoTimer = null;
  }

  ///Play next video form playlist. Do not use manually.
  void playNextVideo() {
    _nextVideoTime = 0;
    _nextVideoTimeStreamController.add(_nextVideoTime);
    _postEvent(BetterPlayerEvent(BetterPlayerEventType.changedPlaylistItem));
    cancelNextVideoTimer();
  }

  ///Setup track parameters for currently played video. Can be only used for HLS or DASH
  ///data source.
  void setTrack(BetterPlayerAsmsTrack track) {
    if (videoPlayerController == null) {
      throw StateError("The data source has not been initialized");
    }
    _postEvent(BetterPlayerEvent(BetterPlayerEventType.changedTrack,
        parameters: <String, dynamic>{
          "id": track.id,
          "width": track.width,
          "height": track.height,
          "bitrate": track.bitrate,
          "frameRate": track.frameRate,
          "codecs": track.codecs,
          "mimeType": track.mimeType,
        }));

    videoPlayerController!
        .setTrackParameters(track.width, track.height, track.bitrate);
    _betterPlayerAsmsTrack = track;
  }

  ///Check if player can be played/paused automatically
  bool _isAutomaticPlayPauseHandled() {
    return !(_betterPlayerDataSource
                ?.notificationConfiguration?.showNotification ==
            true) &&
        betterPlayerConfiguration.handleLifecycle;
  }

  ///Listener which handles state of player visibility. If player visibility is
  ///below 0.0 then video will be paused. When value is greater than 0, video
  ///will play again. If there's different handler of visibility then it will be
  ///used. If showNotification is set in data source or handleLifecycle is false
  /// then this logic will be ignored.
  void onPlayerVisibilityChanged(double visibilityFraction) async {
    _isPlayerVisible = visibilityFraction > 0;
    if (_disposed) {
      return;
    }
    _postEvent(
        BetterPlayerEvent(BetterPlayerEventType.changedPlayerVisibility));

    if (_isAutomaticPlayPauseHandled()) {
      if (betterPlayerConfiguration.playerVisibilityChangedBehavior != null) {
        betterPlayerConfiguration
            .playerVisibilityChangedBehavior!(visibilityFraction);
      } else {
        if (visibilityFraction == 0) {
          _wasPlayingBeforePause ??= isPlaying();
          pause();
        } else {
          if (_wasPlayingBeforePause == true && !isPlaying()!) {
            play();
          }
        }
      }
    }
  }

  ///Set different resolution (quality) for video
  void setResolution(String url) async {
    if (videoPlayerController == null) {
      throw StateError("The data source has not been initialized");
    }
    final position = await videoPlayerController!.position;
    final wasPlayingBeforeChange = isPlaying()!;
    pause();
    await setupDataSource(betterPlayerDataSource!.copyWith(url: url));
    seekTo(position!);
    if (wasPlayingBeforeChange) {
      play();
    }
    _postEvent(BetterPlayerEvent(
      BetterPlayerEventType.changedResolution,
      parameters: <String, dynamic>{"url": url},
    ));
  }

  ///Setup translations for given locale. In normal use cases it shouldn't be
  ///called manually.
  void setupTranslations(Locale locale) {
    // ignore: unnecessary_null_comparison
    if (locale != null) {
      final String languageCode = locale.languageCode;
      translations = betterPlayerConfiguration.translations?.firstWhereOrNull(
              (translations) => translations.languageCode == languageCode) ??
          _getDefaultTranslations(locale);
    } else {
      BetterPlayerUtils.log("Locale is null. Couldn't setup translations.");
    }
  }

  ///Setup default translations for selected user locale. These translations
  ///are pre-build in.
  BetterPlayerTranslations _getDefaultTranslations(Locale locale) {
    final String languageCode = locale.languageCode;
    switch (languageCode) {
      case "pl":
        return BetterPlayerTranslations.polish();
      case "zh":
        return BetterPlayerTranslations.chinese();
      case "hi":
        return BetterPlayerTranslations.hindi();
      case "tr":
        return BetterPlayerTranslations.turkish();
      case "vi":
        return BetterPlayerTranslations.vietnamese();
      case "es":
        return BetterPlayerTranslations.spanish();
      default:
        return BetterPlayerTranslations();
    }
  }

  ///Flag which determines whenever current data source has started.
  bool get hasCurrentDataSourceStarted => _hasCurrentDataSourceStarted;

  ///Set current lifecycle state. If state is [AppLifecycleState.resumed] then
  ///player starts playing again. if lifecycle is in [AppLifecycleState.paused]
  ///state, then video playback will stop. If showNotification is set in data
  ///source or handleLifecycle is false then this logic will be ignored.
  void setAppLifecycleState(AppLifecycleState appLifecycleState) {
    if (_isAutomaticPlayPauseHandled()) {
      _appLifecycleState = appLifecycleState;
      if (appLifecycleState == AppLifecycleState.resumed) {
        if (_wasPlayingBeforePause == true && _isPlayerVisible) {
          play();
        }
      }
      if (appLifecycleState == AppLifecycleState.paused) {
        _wasPlayingBeforePause ??= isPlaying();
        pause();
      }
    }
  }

  // ignore: use_setters_to_change_properties
  ///Setup overridden aspect ratio.
  void setOverriddenAspectRatio(double aspectRatio) {
    _overriddenAspectRatio = aspectRatio;
  }

  ///Get aspect ratio used in current video. If aspect ratio is null, then
  ///aspect ratio from BetterPlayerConfiguration will be used. Otherwise
  ///[_overriddenAspectRatio] will be used.
  double? getAspectRatio() {
    return _overriddenAspectRatio ?? betterPlayerConfiguration.aspectRatio;
  }

  // ignore: use_setters_to_change_properties
  ///Setup overridden fit.
  void setOverriddenFit(BoxFit fit) {
    _overriddenFit = fit;
  }

  ///Get fit used in current video. Always returns BoxFit.contain to prevent
  ///video stretching. If [_overriddenFit] is set, it will be used, otherwise
  ///BoxFit.contain is returned.
  BoxFit getFit() {
    return _overriddenFit ?? BoxFit.contain;
  }

  ///Enable Picture in Picture (PiP) mode. [betterPlayerGlobalKey] is required
  ///to open PiP mode in iOS. When device is not supported, PiP mode won't be
  ///open.
  Future<void>? enablePictureInPicture(GlobalKey betterPlayerGlobalKey) async {
    if (videoPlayerController == null) {
      throw StateError("The data source has not been initialized");
    }

    final bool isPipSupported =
        (await videoPlayerController!.isPictureInPictureSupported()) ?? false;

    if (isPipSupported) {
      _wasInFullScreenBeforePiP = _isFullScreen;
      _wasControlsEnabledBeforePiP = _controlsEnabled;
      setControlsEnabled(false);
      if (Platform.isAndroid) {
        _wasInFullScreenBeforePiP = _isFullScreen;
        await videoPlayerController?.enablePictureInPicture(
            left: 0, top: 0, width: 0, height: 0);
        enterFullScreen();
        _postEvent(BetterPlayerEvent(BetterPlayerEventType.pipStart));
        return;
      }
      if (Platform.isIOS) {
        final RenderBox? renderBox = betterPlayerGlobalKey.currentContext!
            .findRenderObject() as RenderBox?;
        if (renderBox == null) {
          BetterPlayerUtils.log(
              "Can't show PiP. RenderBox is null. Did you provide valid global"
              " key?");
          return;
        }
        final Offset position = renderBox.localToGlobal(Offset.zero);
        return videoPlayerController?.enablePictureInPicture(
          left: position.dx,
          top: position.dy,
          width: renderBox.size.width,
          height: renderBox.size.height,
        );
      } else {
        BetterPlayerUtils.log("Unsupported PiP in current platform.");
      }
    } else {
      BetterPlayerUtils.log(
          "Picture in picture is not supported in this device. If you're "
          "using Android, please check if you're using activity v2 "
          "embedding.");
    }
  }

  ///Disable Picture in Picture mode if it's enabled.
  Future<void>? disablePictureInPicture() {
    if (videoPlayerController == null) {
      throw StateError("The data source has not been initialized");
    }
    return videoPlayerController!.disablePictureInPicture();
  }

  // ignore: use_setters_to_change_properties
  ///Set GlobalKey of BetterPlayer. Used in PiP methods called from controls.
  void setBetterPlayerGlobalKey(GlobalKey betterPlayerGlobalKey) {
    _betterPlayerGlobalKey = betterPlayerGlobalKey;
  }

  ///Check if picture in picture mode is supported in this device.
  Future<bool> isPictureInPictureSupported() async {
    if (videoPlayerController == null) {
      throw StateError("The data source has not been initialized");
    }

    final bool isPipSupported =
        (await videoPlayerController!.isPictureInPictureSupported()) ?? false;

    return isPipSupported && !_isFullScreen;
  }

  ///Handle VideoEvent when remote controls notification / PiP is shown
  void _handleVideoEvent(VideoEvent event) async {
    switch (event.eventType) {
      case VideoEventType.play:
        _postEvent(BetterPlayerEvent(BetterPlayerEventType.play));
        break;
      case VideoEventType.pause:
        _postEvent(BetterPlayerEvent(BetterPlayerEventType.pause));
        break;
      case VideoEventType.seek:
        _postEvent(BetterPlayerEvent(BetterPlayerEventType.seekTo));
        break;
      case VideoEventType.completed:
        final VideoPlayerValue? videoValue = videoPlayerController?.value;
        _postEvent(
          BetterPlayerEvent(
            BetterPlayerEventType.finished,
            parameters: <String, dynamic>{
              _progressParameter: videoValue?.position,
              _durationParameter: videoValue?.duration
            },
          ),
        );
        break;
      case VideoEventType.bufferingStart:
        _postEvent(BetterPlayerEvent(BetterPlayerEventType.bufferingStart));
        break;
      case VideoEventType.bufferingUpdate:
        _postEvent(BetterPlayerEvent(BetterPlayerEventType.bufferingUpdate,
            parameters: <String, dynamic>{
              _bufferedParameter: event.buffered,
            }));
        break;
      case VideoEventType.bufferingEnd:
        _postEvent(BetterPlayerEvent(BetterPlayerEventType.bufferingEnd));
        break;
      case VideoEventType.pipWillStart:
        _postEvent(BetterPlayerEvent(BetterPlayerEventType.pipWillStart));
        break;
      case VideoEventType.pipWillStop:
        _postEvent(BetterPlayerEvent(BetterPlayerEventType.pipWillStop));
        break;
      case VideoEventType.pipRestoreUI:
        // Handle UI restoration from PiP
        _postEvent(BetterPlayerEvent(BetterPlayerEventType.pipRestoreUI));
        // Ensure controls are restored
        if (_wasControlsEnabledBeforePiP) {
          setControlsEnabled(true);
        }
        // Trigger UI refresh
        videoPlayerController?.refresh();
        break;
      case VideoEventType.pipError:
        // Handle PiP error
        _postEvent(BetterPlayerEvent(
          BetterPlayerEventType.pipError,
          parameters: <String, dynamic>{
            'error': event.error ?? 'Unknown PiP error',
          },
        ));
        if (betterPlayerConfiguration.showPipErrors) {
          BetterPlayerUtils.log("PiP error: ${event.error}");
        }
        break;
      case VideoEventType.pipStalled:
        // Handle PiP stalled playback
        _postEvent(BetterPlayerEvent(BetterPlayerEventType.pipStalled));
        BetterPlayerUtils.log("PiP playback stalled");
        break;
      case VideoEventType.pipAnalytics:
        // Handle PiP analytics
        final double duration = event.pipDuration ?? 0.0;
        _postEvent(BetterPlayerEvent(
          BetterPlayerEventType.pipAnalytics,
          parameters: <String, dynamic>{
            'duration': duration,
          },
        ));
        // Call user callback if provided
        if (betterPlayerConfiguration.onPipAnalytics != null) {
          betterPlayerConfiguration.onPipAnalytics!(duration);
        }
        BetterPlayerUtils.log("PiP session duration: ${duration}s");
        break;
      default:
        BetterPlayerUtils.log("Unhandled event type: ${event.eventType}");
        break;
    }
  }

  ///Setup controls always visible mode
  void setControlsAlwaysVisible(bool controlsAlwaysVisible) {
    _controlsAlwaysVisible = controlsAlwaysVisible;
    _controlsVisibilityStreamController.add(controlsAlwaysVisible);
  }

  ///Retry data source if playback failed.
  Future retryDataSource() async {
    // Remove listener which will be added again on _setupDataSource
    videoPlayerController?.removeListener(_onVideoPlayerChanged);
    await _setupDataSource(_betterPlayerDataSource!);
    if (_videoPlayerValueOnError != null) {
      final position = _videoPlayerValueOnError!.position;
      await seekTo(position);
      await play();
      _videoPlayerValueOnError = null;
    }
  }

  ///Set [audioTrack] in player. Works only for HLS or DASH streams.
  void setAudioTrack(BetterPlayerAsmsAudioTrack audioTrack) {
    if (videoPlayerController == null) {
      throw StateError("The data source has not been initialized");
    }

    if (audioTrack.language == null) {
      _betterPlayerAsmsAudioTrack = null;
      return;
    }

    _betterPlayerAsmsAudioTrack = audioTrack;
    videoPlayerController!.setAudioTrack(audioTrack.label, audioTrack.id);
  }

  ///Enable or disable audio mixing with other sound within device.
  void setMixWithOthers(bool mixWithOthers) {
    if (videoPlayerController == null) {
      throw StateError("The data source has not been initialized");
    }

    videoPlayerController!.setMixWithOthers(mixWithOthers);
  }

  ///Clear all cached data. Video player controller must be initialized to
  ///clear the cache.
  Future<void> clearCache() async {
    return VideoPlayerController.clearCache();
  }

  ///Build headers map that will be used to setup video player controller. Apply
  ///DRM headers if available.
  Map<String, String?> _getHeaders() {
    final headers = betterPlayerDataSource!.headers ?? {};
    if (betterPlayerDataSource?.drmConfiguration?.drmType ==
            BetterPlayerDrmType.token &&
        betterPlayerDataSource?.drmConfiguration?.token != null) {
      headers[_authorizationHeader] =
          betterPlayerDataSource!.drmConfiguration!.token!;
    }
    return headers;
  }

  ///PreCache a video. On Android, the future succeeds when
  ///the requested size, specified in
  ///[BetterPlayerCacheConfiguration.preCacheSize], is downloaded or when the
  ///complete file is downloaded if the file is smaller than the requested size.
  ///On iOS, the whole file will be downloaded, since [maxCacheFileSize] is
  ///currently not supported on iOS. On iOS, the video format must be in this
  ///list: https://github.com/sendyhalim/Swime/blob/master/Sources/MimeType.swift
  Future<void> preCache(BetterPlayerDataSource betterPlayerDataSource) async {
    final cacheConfig = betterPlayerDataSource.cacheConfiguration ??
        const BetterPlayerCacheConfiguration(useCache: true);

    final dataSource = DataSource(
      sourceType: DataSourceType.network,
      uri: betterPlayerDataSource.url,
      useCache: true,
      headers: betterPlayerDataSource.headers,
      maxCacheSize: cacheConfig.maxCacheSize,
      maxCacheFileSize: cacheConfig.maxCacheFileSize,
      cacheKey: cacheConfig.key,
      videoExtension: betterPlayerDataSource.videoExtension,
    );

    return VideoPlayerController.preCache(dataSource, cacheConfig.preCacheSize);
  }

  ///Stop pre cache for given [betterPlayerDataSource]. If there was no pre
  ///cache started for given [betterPlayerDataSource] then it will be ignored.
  Future<void> stopPreCache(
      BetterPlayerDataSource betterPlayerDataSource) async {
    return VideoPlayerController.stopPreCache(
      betterPlayerDataSource.url,
      betterPlayerDataSource.cacheConfiguration?.key,
    );
  }

  /// Sets the new [betterPlayerControlsConfiguration] instance in the
  /// controller.
  void setBetterPlayerControlsConfiguration(
      BetterPlayerControlsConfiguration betterPlayerControlsConfiguration) {
    this._betterPlayerControlsConfiguration = betterPlayerControlsConfiguration;
  }

  /// Add controller internal event.
  void _postControllerEvent(BetterPlayerControllerEvent event) {
    if (!_controllerEventStreamController.isClosed) {
      _controllerEventStreamController.add(event);
    }
  }

  ///Dispose BetterPlayerController. When [forceDispose] parameter is true, then
  ///autoDispose parameter will be overridden and controller will be disposed
  ///(if it wasn't disposed before).
  Future<void> dispose({bool forceDispose = false}) async {
    if (!betterPlayerConfiguration.autoDispose && !forceDispose) {
      return;
    }
    if (!_disposed) {
      if (videoPlayerController != null) {
        await pause();
        videoPlayerController!.removeListener(_onFullScreenStateChanged);
        videoPlayerController!.removeListener(_onVideoPlayerChanged);
        await videoPlayerController!.dispose();
      }
      _eventListeners.clear();
      renderedSubtitle = null;
      _nextVideoTimer?.cancel();
      await _nextVideoTimeStreamController.close();
      await _controlsVisibilityStreamController.close();
      await _videoEventStreamSubscription?.cancel();
      _disposed = true;
      await _controllerEventStreamController.close();

      // Delete temp files
      for (final file in _tempFiles) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
  }
}
