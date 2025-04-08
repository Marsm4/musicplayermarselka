import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:marselkaplaer/music/player.dart';

class PlaylistTracksPage extends StatefulWidget {
  final List<dynamic> tracks;
  final String playlistName;
  final String playlistId;

  const PlaylistTracksPage({
    super.key,
    required this.tracks,
    required this.playlistName,
    required this.playlistId,
  });

  @override
  State<PlaylistTracksPage> createState() => _PlaylistTracksPageState();
}

class _PlaylistTracksPageState extends State<PlaylistTracksPage> {
  final AudioPlayer audioPlayer = AudioPlayer();
  int? currentPlayingIndex;

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> playTrack(String url, int index) async {
    if (currentPlayingIndex == index) {
      await audioPlayer.pause();
      setState(() => currentPlayingIndex = null);
    } else {
      await audioPlayer.play(UrlSource(url));
      setState(() => currentPlayingIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue, Colors.blueGrey],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            widget.playlistName,
            style: const TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView.builder(
          itemCount: widget.tracks.length,
          itemBuilder: (context, index) {
            final track = widget.tracks[index];
            final author = track['author'] as Map<String, dynamic>? ?? {};
            final isPlaying = currentPlayingIndex == index;
            final imageUrl = track['image']?.toString();
            final musicUrl = track['url_music']?.toString();

            return Card(
              color: Colors.white.withOpacity(0.2),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl != null && imageUrl.startsWith('http')
                      ? Image.network(
                          imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.music_note,
                            color: Colors.white,
                            size: 40,
                          ),
                        )
                      : const Icon(
                          Icons.music_note,
                          color: Colors.white,
                          size: 40,
                        ),
                ),
                title: Text(
                  track['name_track']?.toString() ?? 'Без названия',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  author['name_author']?.toString() ??
                      'Неизвестный исполнитель',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    if (musicUrl != null) {
                      playTrack(musicUrl, index);
                    }
                  },
                ),
                onTap: () {
                  if (musicUrl != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerPage(
                          urlMusic: musicUrl,
                          urlPhoto: imageUrl,
                          nameSound: track['name_track']?.toString(),
                          author: author['name_author']?.toString(),
                        ),
                      ),
                    );
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
