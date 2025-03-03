import 'dart:developer';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mercy_tv_app/controllers/home_controller.dart';

class NewScreenPlayer extends StatelessWidget {
  const NewScreenPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildVideoPlayer(controller),
          _buildTapDetector(controller),
          _buildLiveButton(controller),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer(HomeController controller) {
    return Obx(() {
      log('[VIDEO STATE] Initialized: ${controller.isVideoInitialized.value}, '
          'Chewie: ${controller.chewieController != null}, '
          'Live: ${controller.isLiveStream.value}');

      if (!controller.isVideoInitialized.value) {
        return _buildLoadingIndicator();
      }

      if (controller.chewieController == null) {
        return _buildErrorDisplay('Video controller not available');
      }

      return Chewie(
        controller: controller.chewieController!,
        key: Key(controller.currentVideoUrl.value), // Force widget recreation
      );
    });
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 10),
          Text(
            'Loading video...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorDisplay(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 40),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTapDetector(HomeController controller) {
    return Listener(
      onPointerDown: (_) => controller.onScreenTapped(),
      behavior: HitTestBehavior.translucent,
    );
  }

  Widget _buildLiveButton(HomeController controller) {
    return Obx(() {
      if (!controller.showButton.value) return const SizedBox.shrink();

      return Positioned(
        bottom: 40,
        right: 20,
        child: _liveButton(
          controller.isLiveStream.value ? 'Live' : 'Go Live',
          controller.isLiveStream.value ? Colors.red : const Color(0xFF8DBDCC),
          () => _handleLiveButtonPress(controller),
        ),
      );
    });
  }

  void _handleLiveButtonPress(HomeController controller) {
    log('Live button pressed');
    controller.resetPlayer();
    controller.initializePlayer(
      'https://mercyott.com/hls_output/master.m3u8',
      true,
    );
  }

  Widget _liveButton(String text, Color color, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 20,
          width: 50,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
