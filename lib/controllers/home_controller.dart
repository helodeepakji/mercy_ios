import 'dart:async';
import 'dart:developer';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class HomeController extends GetxController {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  final RxBool isVideoInitialized = false.obs;
  final RxString currentVideoUrl =
      'https://mercyott.com/hls_output/master.m3u8'.obs;
  final RxBool isLiveStream =
      true.obs; // Used as isLiveStreamVar in NewScreenPlayer
  final RxInt currentlyPlayingIndex =
      RxInt(-1); // Fixed to non-nullable with default -1
  final RxBool showButton = false.obs; // Added for button visibility
  bool _isDisposed = false;
  int _playerInitToken = 0;
  Timer? _hideButtonTimer; // Timer to auto-hide the button

  @override
  void onInit() {
    super.onInit();
    initializePlayer(currentVideoUrl.value, isLiveStream.value);
  }

  void resetPlayer() {
    _disposeControllers();
    update();
  }

  void playSelectedVideo(String url) {
    if (_chewieController?.isFullScreen ?? false) {
      exitFullScreen();
    }
    initializePlayer(url, false);
  }

  void updateCurrentVideo(String url, bool isLive, String title) {
    currentVideoUrl.value = url;
    isLiveStream.value = isLive;
    initializePlayer(url, isLive);
  }

  Future<void> initializePlayer(String videoUrl, bool isLive) async {
    final currentToken = ++_playerInitToken;
    log('Initializing player with URL: $videoUrl, isLive: $isLive'); // Log URL

    try {
      await _disposeControllers();

      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: true,
        ),
      );

      await _videoController!.initialize();
      log('::: Video initialized successfully: ${videoUrl}');

      if (_isDisposed || currentToken != _playerInitToken) {
        log('::: Initialization aborted due to disposal or token mismatch');
        return;
      }

      _setupChewieController(isLive);
      currentVideoUrl.value = videoUrl;
      isLiveStream.value = isLive;
      isVideoInitialized.value = true;

      if (isLive) {
        _videoController!.play();
        log('::: Playing live stream');
      } else {
        _videoController!.play(); // Play VOD too
        log('Playing VOD');
      }
    } catch (e) {
      log("::: Error initializing video: $e",
          error: e); // Detailed error logging
      isVideoInitialized.value = false;
    }
  }

  void _setupChewieController(bool isLive) {
    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      aspectRatio: _videoController!.value.aspectRatio,
      autoPlay: true,
      looping: isLive,
      showControls: true,
      allowFullScreen: true,
      allowPlaybackSpeedChanging: !isLive,
      deviceOrientationsAfterFullScreen: [
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
      additionalOptions: (context) => isLive ? _qualityOptions(context) : [],
    );
  }

  List<OptionItem> _qualityOptions(BuildContext context) {
    return [
      OptionItem(
        iconData: Icons.video_settings,
        title: 'Quality',
        onTap: (context) => _showQualityOptions(context),
      ),
    ];
  }

  void _showQualityOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      builder: (context) => Wrap(
        children: [
          _qualityOption('Auto', 'https://mercyott.com/hls_output/master.m3u8'),
          _qualityOption('360p', 'https://mercyott.com/hls_output/360p.m3u8'),
          _qualityOption('720p', 'https://mercyott.com/hls_output/720p.m3u8'),
          _qualityOption('1080p', 'https://mercyott.com/hls_output/1080p.m3u8'),
        ],
      ),
    );
  }

  Widget _qualityOption(String quality, String url) {
    return ListTile(
      leading: const Icon(Icons.hd, color: Colors.white),
      title: Text(quality, style: const TextStyle(color: Colors.white)),
      onTap: () => _changeVideoQuality(url),
    );
  }

  Future<void> _changeVideoQuality(String url) async {
    Navigator.pop(Get.context!);
    await initializePlayer(url, true);
  }

  Future<void> _disposeControllers() async {
    if (_chewieController != null) {
      _chewieController!.dispose();
    }
    if (_videoController != null) {
      await _videoController!.dispose();
    }
    _chewieController = null;
    _videoController = null;
  }

  void enterFullScreen() {
    if (_chewieController?.isFullScreen ?? false) return;
    log('Entering full screen');
    _chewieController?.enterFullScreen();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    // Ensure video plays after entering full screen
    if (isVideoInitialized.value && _videoController != null) {
      _videoController!.play();
    }
  }

  void exitFullScreen() {
    if (!(_chewieController?.isFullScreen ?? true)) return;
    log('Exiting full screen');
    _chewieController?.exitFullScreen();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // Ensure video continues playing in portrait
    if (isVideoInitialized.value && _videoController != null) {
      _videoController!.play();
    }
  }

  // Added method for screen tap
  void onScreenTapped() {
    if (isVideoInitialized.value) {
      showButton.value = true;
      _hideButtonTimer?.cancel(); // Cancel any existing timer
      _hideButtonTimer = Timer(const Duration(seconds: 3), () {
        showButton.value = false; // Hide button after 3 seconds
      });
    }
  }

  ChewieController? get chewieController => _chewieController;
  VideoPlayerController? get videoController => _videoController;

  @override
  Future<void> onClose() async {
    _isDisposed = true;
    _hideButtonTimer?.cancel(); // Clean up timer
    await _disposeControllers();
    super.onClose();
  }
}
