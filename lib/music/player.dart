import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class PlayerPage extends StatefulWidget {
  final String? urlMusic;
  final String? urlPhoto;
  final String? nameSound;
  final String? author;

  PlayerPage({
    super.key,
    this.urlMusic,
    this.urlPhoto,
    this.nameSound,
    this.author,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  bool isPlaying = false;
  late final AudioPlayer audioPlayer;
  late final UrlSource urlSource;
  Duration _duration = Duration();
  Duration _position = Duration();

  @override
  void initState() {
    super.initState();
    initPlayer();
  }

  Future<void> initPlayer() async {
    audioPlayer = AudioPlayer();

    if (widget.urlMusic != null) {
      urlSource = UrlSource(widget.urlMusic!);
    } else {
      print("URL музыки не указан");
      return;
    }

    // Следим за изменением длительности трека
    audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _duration = duration;
      });
    });

    // Следим за изменением позиции воспроизведения
    audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _position = position;
      });
    });

    // Следим за завершением воспроизведения
    audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        isPlaying = false;
        _position = _duration;
      });
    });
  }

  // Метод для воспроизведения/паузы
  void playPause() async {
    if (isPlaying) {
      await audioPlayer.pause();
    } else {
      await audioPlayer.play(urlSource);
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  // Метод для перемотки
  void seek(Duration position) async {
    await audioPlayer.seek(position);
    setState(() {});
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 33, 150, 243),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.blueGrey],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Обложка трека
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: widget.urlPhoto != null
                  ? Image.network(
                      widget.urlPhoto!,
                      height: MediaQuery.of(context).size.height * 0.3,
                      width: MediaQuery.of(context).size.width * 0.6,
                      fit: BoxFit.cover,
                    )
                  : Icon(Icons.music_note, size: 100, color: Colors.white),
            ),
            SizedBox(height: 20),
            // Название трека и исполнитель
            ListTile(
              textColor: Colors.white,
              title: Text(
                widget.nameSound ?? 'Название трека не указано',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              subtitle: Text(
                widget.author ?? 'Исполнитель не указан',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 20),
            // Прогресс воспроизведения
            Slider(
              min: 0,
              max: _duration.inSeconds.toDouble(),
              value: _position.inSeconds.toDouble(),
              onChanged: (value) {
                seek(Duration(seconds: value.toInt()));
              },
              activeColor: Colors.white,
              inactiveColor: Colors.white54,
            ),
            // Время воспроизведения
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _position.format(),
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    _duration.format(),
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Управление воспроизведением
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    seek(Duration(seconds: _position.inSeconds - 10));
                  },
                  icon: Icon(Icons.fast_rewind, size: 40, color: Colors.white),
                ),
                IconButton(
                  onPressed: playPause,
                  icon: Icon(
                    isPlaying ? Icons.pause_circle : Icons.play_circle,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    seek(Duration(seconds: _position.inSeconds + 10));
                  },
                  icon: Icon(Icons.fast_forward, size: 40, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Форматирование времени
extension DurationExtension on Duration {
  String format() {
    String minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
