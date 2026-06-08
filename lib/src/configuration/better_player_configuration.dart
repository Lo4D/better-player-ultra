import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

///Configuration of Better Player. Allows to setup general behavior of player.
///Master configuration which contains children that configure specific part
///of player.
class BetterPlayerConfiguration {
  /// Play the video as soon as it's displayed
  final bool autoPlay;

  /// Start video at a certain position
  final Duration? startAt;

  /// Whether or not the video should loop
  final bool looping;

  /// When the video playback runs  into an error, you can build a custom
  /// error message.
  final Widget Function(BuildContext context, String? errorMessage)?
      errorBuilder;

  /// The Aspect Ratio of the Video. Important to get the correct size of the
  /// video!
  ///
  /// Will fallback to fitting within the space allowed.
  final double? aspectRatio;

  /// The placeholder is displayed underneath the Video before it is initialized
  /// or played.
  final Widget? placeholder;

  /// Should the placeholder be shown until play is pressed
  final bool showPlaceholderUntilPlay;

  /// Placeholder position of player stack. If false, then placeholder will be
  /// displayed on the bottom, so user need to hide it manually. Default is
  /// true.
  final bool placeholderOnTop;

  /// A widget which is placed between the video and the controls
  final Widget? overlay;

  /// Defines if the player will start in fullscreen when play is pressed
  final bool fullScreenByDefault;

  /// Defines if the player will sleep in fullscreen or not
  final bool allowedScreenSleep;

  /// Defines aspect ratio which will be used in fullscreen
  final double? fullScreenAspectRatio;

  /// Defines the set of allowed device orientations on entering fullscreen
  final List<DeviceOrientation> deviceOrientationsOnFullScreen;

  /// Defines the system overlays visible after exiting fullscreen
  final List<SystemUiOverlay> systemOverlaysAfterFullScreen;

  /// Defines the set of allowed device orientations after exiting fullscreen
  final List<DeviceOrientation> deviceOrientationsAfterFullScreen;

  /// Defines a custom RoutePageBuilder for the fullscreen
  final BetterPlayerRoutePageBuilder? routePageBuilder;

  /// Defines a event listener where video player events will be send
  final Function(BetterPlayerEvent)? eventListener;

  ///Defines subtitles configuration
  final BetterPlayerSubtitlesConfiguration subtitlesConfiguration;

  ///Defines controls configuration
  final BetterPlayerControlsConfiguration controlsConfiguration;

  ///Defines fit of the video, allows to fix video stretching, see possible
  ///values here: https://api.flutter.dev/flutter/painting/BoxFit-class.html
  final BoxFit fit;

  ///Defines rotation of the video in degrees. Default value is 0. Can be 0, 90, 180, 270.
  ///Angle will rotate only video box, controls will be in the same place.
  final double rotation;

  ///Defines function which will react on player visibility changed
  final Function(double visibilityFraction)? playerVisibilityChangedBehavior;

  ///Defines translations used in player. If null, then default english translations
  ///will be used.
  final List<BetterPlayerTranslations>? translations;

  ///Defines if player should auto detect full screen device orientation based
  ///on aspect ratio of the video. If aspect ratio of the video is < 1 then
  ///video will played in full screen in portrait mode. If aspect ratio is >= 1
  ///then video will be played horizontally. If this parameter is true, then
  ///[deviceOrientationsOnFullScreen] and [fullScreenAspectRatio] value will be
  /// ignored.
  final bool autoDetectFullscreenDeviceOrientation;

  ///Defines if player should auto detect full screen aspect ration of the video.
  ///If [deviceOrientationsOnFullScreen] is true this is done automaticaly also.
  final bool autoDetectFullscreenAspectRatio;

  ///Defines if player should auto detect video orientation and set appropriate BoxFit.
  ///If true, both portrait and landscape videos will use BoxFit.contain to prevent
  ///video stretching when rotating.
  final bool autoDetectVideoFit;

  ///Defines flag which enables/disables lifecycle handling (pause on app closed,
  ///play on app resumed). Default value is true.
  final bool handleLifecycle;

  ///Defines flag which enabled/disabled auto dispose of
  ///[BetterPlayerController] on [BetterPlayer] dispose. When it's true and
  ///[BetterPlayerController] instance has been attached to [BetterPlayer] widget
  ///and dispose has been called on [BetterPlayer] instance, then
  ///[BetterPlayerController] will be disposed.
  ///Default value is true.
  final bool autoDispose;

  ///Flag which causes to player expand to fill all remaining space. Set to false
  ///to use minimum constraints
  final bool expandToFill;

  ///Flag which causes to player use the root navigator to open new pages.
  ///Default value is false.
  final bool useRootNavigator;

  /// Set this to true to mix video players audio with other audio sources.
  /// The default value is false
  final bool mixWithOthers;

  ///Widget to display below the seekbar
  final Widget? widgetBelowSeekBar;

  ///Widget to display on the left side of the top bar
  final Widget? widgetInTopBarLeft;

  ///Enable replicated blurred background behind the video similar to YouTube Ambient Mode.
  final bool enableAmbientMode;

  ///Show ambient only when the player is fullscreen.
  final bool ambientModeFullScreenOnly;

  ///Restrict ambient effect to landscape orientation (recommended for horizontal fullscreen).
  final bool ambientModeLandscapeOnly;

  ///Blur sigma applied to the replicated video surface.
  final double ambientBlurSigma;

  ///Scale factor for the replicated video surface relative to original.
  final double ambientScale;

  ///Darken overlay (0-1) placed above the blurred video to reduce glare.
  final double ambientDarken;

  /// Auto-enter PiP mode when app goes to background (iOS only).
  /// Default value is false. User must explicitly enable this.
  final bool autoEnterPipOnBackground;

  /// Show error messages for PiP failures as notifications.
  /// Default value is true.
  final bool showPipErrors;

  /// Callback for PiP analytics events. Receives duration in seconds.
  final Function(double duration)? onPipAnalytics;

  const BetterPlayerConfiguration({
    this.aspectRatio,
    this.autoPlay = false,
    this.startAt,
    this.looping = false,
    this.fullScreenByDefault = false,
    this.placeholder,
    this.showPlaceholderUntilPlay = false,
    this.placeholderOnTop = true,
    this.overlay,
    this.errorBuilder,
    this.allowedScreenSleep = true,
    this.fullScreenAspectRatio,
    this.deviceOrientationsOnFullScreen = const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ],
    this.systemOverlaysAfterFullScreen = SystemUiOverlay.values,
    this.deviceOrientationsAfterFullScreen = const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ],
    this.routePageBuilder,
    this.eventListener,
    this.subtitlesConfiguration = const BetterPlayerSubtitlesConfiguration(),
    this.controlsConfiguration = const BetterPlayerControlsConfiguration(),
    this.fit = BoxFit.contain,
    this.rotation = 0,
    this.playerVisibilityChangedBehavior,
    this.translations,
    this.autoDetectFullscreenDeviceOrientation = false,
    this.autoDetectFullscreenAspectRatio = false,
    this.autoDetectVideoFit = true,
    this.handleLifecycle = true,
    this.autoDispose = true,
    this.expandToFill = true,
    this.useRootNavigator = false,
    this.mixWithOthers = false,
    this.widgetBelowSeekBar,
    this.widgetInTopBarLeft,
    this.enableAmbientMode = true,
    this.ambientModeFullScreenOnly = false,
    this.ambientModeLandscapeOnly = false,
    this.ambientBlurSigma = 60,
    this.ambientScale = 1.25,
    this.ambientDarken = 0.55,
    this.autoEnterPipOnBackground = false,
    this.showPipErrors = true,
    this.onPipAnalytics,
  });

  BetterPlayerConfiguration copyWith({
    double? aspectRatio,
    bool? autoPlay,
    Duration? startAt,
    bool? looping,
    bool? fullScreenByDefault,
    Widget? placeholder,
    bool? showPlaceholderUntilPlay,
    bool? placeholderOnTop,
    Widget? overlay,
    bool? showControlsOnInitialize,
    Widget Function(BuildContext context, String? errorMessage)? errorBuilder,
    bool? allowedScreenSleep,
    double? fullScreenAspectRatio,
    List<DeviceOrientation>? deviceOrientationsOnFullScreen,
    List<SystemUiOverlay>? systemOverlaysAfterFullScreen,
    List<DeviceOrientation>? deviceOrientationsAfterFullScreen,
    BetterPlayerRoutePageBuilder? routePageBuilder,
    Function(BetterPlayerEvent)? eventListener,
    BetterPlayerSubtitlesConfiguration? subtitlesConfiguration,
    BetterPlayerControlsConfiguration? controlsConfiguration,
    BoxFit? fit,
    double? rotation,
    Function(double visibilityFraction)? playerVisibilityChangedBehavior,
    List<BetterPlayerTranslations>? translations,
    bool? autoDetectFullscreenDeviceOrientation,
    bool? autoDetectFullscreenAspectRatio,
    bool? autoDetectVideoFit,
    bool? handleLifecycle,
    bool? autoDispose,
    bool? expandToFill,
    bool? useRootNavigator,
    bool? mixWithOthers,
    Widget? widgetBelowSeekBar,
    Widget? widgetInTopBarLeft,
    bool? enableAmbientMode,
    bool? ambientModeFullScreenOnly,
    bool? ambientModeLandscapeOnly,
    double? ambientBlurSigma,
    double? ambientScale,
    double? ambientDarken,
    bool? autoEnterPipOnBackground,
    bool? showPipErrors,
    Function(double duration)? onPipAnalytics,
  }) {
    return BetterPlayerConfiguration(
      aspectRatio: aspectRatio ?? this.aspectRatio,
      autoPlay: autoPlay ?? this.autoPlay,
      startAt: startAt ?? this.startAt,
      looping: looping ?? this.looping,
      fullScreenByDefault: fullScreenByDefault ?? this.fullScreenByDefault,
      placeholder: placeholder ?? this.placeholder,
      showPlaceholderUntilPlay:
          showPlaceholderUntilPlay ?? this.showPlaceholderUntilPlay,
      placeholderOnTop: placeholderOnTop ?? this.placeholderOnTop,
      overlay: overlay ?? this.overlay,
      errorBuilder: errorBuilder ?? this.errorBuilder,
      allowedScreenSleep: allowedScreenSleep ?? this.allowedScreenSleep,
      fullScreenAspectRatio:
          fullScreenAspectRatio ?? this.fullScreenAspectRatio,
      deviceOrientationsOnFullScreen:
          deviceOrientationsOnFullScreen ?? this.deviceOrientationsOnFullScreen,
      systemOverlaysAfterFullScreen:
          systemOverlaysAfterFullScreen ?? this.systemOverlaysAfterFullScreen,
      deviceOrientationsAfterFullScreen: deviceOrientationsAfterFullScreen ??
          this.deviceOrientationsAfterFullScreen,
      routePageBuilder: routePageBuilder ?? this.routePageBuilder,
      eventListener: eventListener ?? this.eventListener,
      subtitlesConfiguration:
          subtitlesConfiguration ?? this.subtitlesConfiguration,
      controlsConfiguration:
          controlsConfiguration ?? this.controlsConfiguration,
      fit: fit ?? this.fit,
      rotation: rotation ?? this.rotation,
      playerVisibilityChangedBehavior: playerVisibilityChangedBehavior ??
          this.playerVisibilityChangedBehavior,
      translations: translations ?? this.translations,
      autoDetectFullscreenDeviceOrientation:
          autoDetectFullscreenDeviceOrientation ??
              this.autoDetectFullscreenDeviceOrientation,
      autoDetectFullscreenAspectRatio: autoDetectFullscreenAspectRatio ??
          this.autoDetectFullscreenAspectRatio,
      autoDetectVideoFit: autoDetectVideoFit ?? this.autoDetectVideoFit,
      handleLifecycle: handleLifecycle ?? this.handleLifecycle,
      autoDispose: autoDispose ?? this.autoDispose,
      expandToFill: expandToFill ?? this.expandToFill,
      useRootNavigator: useRootNavigator ?? this.useRootNavigator,
      mixWithOthers: mixWithOthers ?? this.mixWithOthers,
      widgetBelowSeekBar: widgetBelowSeekBar ?? this.widgetBelowSeekBar,
      widgetInTopBarLeft: widgetInTopBarLeft ?? this.widgetInTopBarLeft,
      enableAmbientMode: enableAmbientMode ?? this.enableAmbientMode,
      ambientModeFullScreenOnly:
          ambientModeFullScreenOnly ?? this.ambientModeFullScreenOnly,
      ambientModeLandscapeOnly:
          ambientModeLandscapeOnly ?? this.ambientModeLandscapeOnly,
      ambientBlurSigma: ambientBlurSigma ?? this.ambientBlurSigma,
      ambientScale: ambientScale ?? this.ambientScale,
      ambientDarken: ambientDarken ?? this.ambientDarken,
      autoEnterPipOnBackground:
          autoEnterPipOnBackground ?? this.autoEnterPipOnBackground,
      showPipErrors: showPipErrors ?? this.showPipErrors,
      onPipAnalytics: onPipAnalytics ?? this.onPipAnalytics,
    );
  }
}
