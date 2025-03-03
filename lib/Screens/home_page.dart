import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mercy_tv_app/Colors/custom_color.dart';
import 'package:mercy_tv_app/controllers/home_controller.dart';
import 'package:mercy_tv_app/widget/Live_View_widget.dart';
import 'package:mercy_tv_app/widget/button_section.dart';
import 'package:mercy_tv_app/widget/new_screen_player.dart';
import 'package:mercy_tv_app/widget/sugested_video_list.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../API/dataModel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  Timer? _timer;
  DateTime _currentDateTime = DateTime.now();
  String _selectedProgramTitle = 'Mercy TV Live';
  String _selectedProgramDate = '';
  String _selectedProgramTime = '';
  Orientation? _currentOrientation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _currentDateTime = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final mediaQuery = MediaQuery.of(context);
    final newOrientation = mediaQuery.orientation;
    if (newOrientation != _currentOrientation) {
      _currentOrientation = newOrientation;
      _handleOrientationChange(newOrientation);
    }
  }

  void _handleOrientationChange(Orientation orientation) {
    final homeController = Get.find<HomeController>();
    if (orientation == Orientation.landscape) {
      homeController.enterFullScreen();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      homeController.exitFullScreen();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://mercytv.tv');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  void _playVideo(ProgramDetails programDetails) {
    final homeController = Get.find<HomeController>();

    homeController.resetPlayer();
    homeController.playSelectedVideo(programDetails.videoUrl);

    if (mounted) {
      setState(() {
        _selectedProgramTitle = programDetails.title;
        _selectedProgramDate = programDetails.date != null
            ? _formatDate(programDetails.date!)
            : '';
        _selectedProgramTime = programDetails.time != null
            ? _formatTime(programDetails.time!)
            : '';
      });
    }
  }

  String _formatDate(String date) =>
      DateFormat('EEE dd MMM').format(DateFormat('yyyy-MM-dd').parse(date));

  String _formatTime(String time) =>
      DateFormat('hh:mm a').format(DateFormat('HH:mm:ss').parse(time));

  @override
  Widget build(BuildContext context) {
    final HomeController homeController =
        Get.find<HomeController>(); // Changed from Get.put

    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) {
          return Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [Color.fromARGB(255, 0, 90, 87), Color(0xFF000000)],
                stops: [0.0, 0.9],
              ),
            ),
            child: orientation == Orientation.portrait
                ? _buildPortraitLayout()
                : _buildLandscapeLayout(),
          );
        },
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        _buildVideoContainer(0.4),
        _buildContentSection(),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return _buildVideoContainer(1.0);
  }

  Widget _buildVideoContainer(double heightFactor) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * heightFactor,
      child: const NewScreenPlayer(),
    );
  }

  Widget _buildContentSection() {
    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleSection(),
              _buildDateTimeSection(),
              const ButtonSection(),
              _buildWebsiteButton(),
              _buildPastProgramsSection(),
              SuggestedVideoCard(onVideoTap: _playVideo),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Row(
      children: [
        Expanded(
          child: Text(
            _selectedProgramTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (_selectedProgramTitle == 'Mercy TV Live') const LiveViewWidget(),
      ],
    );
  }

  Widget _buildDateTimeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            _selectedProgramDate.isNotEmpty
                ? _selectedProgramDate
                : DateFormat('EEE dd MMM').format(_currentDateTime),
            style: const TextStyle(color: Colors.white),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('|', style: TextStyle(color: Colors.white)),
          ),
          Text(
            _selectedProgramTime.isNotEmpty
                ? _selectedProgramTime
                : DateFormat('hh:mm a').format(_currentDateTime),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildWebsiteButton() {
    return GestureDetector(
      onTap: _launchURL,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Center(
          child: Text(
            'Visit Website',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPastProgramsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Past Programs',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w300,
          ),
        ),
        Container(
          width: 120,
          height: 2,
          color: CustomColors.buttonColor,
          margin: const EdgeInsets.only(top: 4),
        ),
      ],
    );
  }
}
