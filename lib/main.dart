import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const ZenMusicApp());
}

class ZenMusicApp extends StatelessWidget {
  const ZenMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zen Music Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      home: const ZenHomePage(),
    );
  }
}

class ZenHomePage extends StatefulWidget {
  const ZenHomePage({super.key});

  @override
  State<ZenHomePage> createState() => _ZenHomePageState();
}

class _ZenHomePageState extends State<ZenHomePage>
    with SingleTickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  bool isPlaying = false;
  double _volume = 0.5;
  late AnimationController _waveController;
  Timer? _stopTimer;
  int? _selectedDuration; // in minutes

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _waveController.dispose();
    _stopTimer?.cancel();
    super.dispose();
  }

  void _togglePlay() async {
    if (isPlaying) {
      await _audioPlayer.pause();
      _waveController.stop();
      _stopTimer?.cancel();
    } else {
      await _audioPlayer.setVolume(_volume);
      await _audioPlayer.play(AssetSource('audio/zen1.mp3'));
      _waveController.repeat();
      _startStopTimer();
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  void _startStopTimer() {
    if (_selectedDuration != null) {
      _stopTimer?.cancel(); // öncekiyi iptal et
      _stopTimer = Timer(Duration(minutes: _selectedDuration!), () async {
        await _audioPlayer.pause();
        _waveController.stop();
        setState(() {
          isPlaying = false;
        });
        _showStoppedDialog();
      });
    }
  }

  void _showStoppedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Time\'s up'),
        content: const Text('Your meditation timer has ended.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _setVolume(double value) async {
    setState(() {
      _volume = value;
    });
    await _audioPlayer.setVolume(_volume);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zen Music'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: WavePainter(_waveController.value),
                  size: const Size(200, 100),
                );
              },
            ),
            const SizedBox(height: 30),
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause_circle : Icons.play_circle,
                size: 80,
                color: Colors.teal,
              ),
              onPressed: _togglePlay,
            ),
            const SizedBox(height: 10),
            Text(
              isPlaying ? 'Relaxing...' : 'Tap to start',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            Text(
              'Volume: ${(_volume * 100).round()}%',
              style: const TextStyle(fontSize: 16),
            ),
            Slider(
              value: _volume,
              onChanged: _setVolume,
              min: 0,
              max: 1,
              divisions: 10,
            ),
            const SizedBox(height: 20),
            const Text(
              'Set Timer:',
              style: TextStyle(fontSize: 16),
            ),
            DropdownButton<int>(
              value: _selectedDuration,
              hint: const Text('Select duration'),
              items: const [
                DropdownMenuItem(value: 5, child: Text('5 minutes')),
                DropdownMenuItem(value: 10, child: Text('10 minutes')),
                DropdownMenuItem(value: 15, child: Text('15 minutes')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedDuration = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final double progress;

  WavePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.teal.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final path = Path();
    for (double i = 0; i < size.width; i++) {
      double y = 20 * sin((i / 20) + (progress * 2 * pi)) + size.height / 2;
      path.lineTo(i, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) => true;
}
