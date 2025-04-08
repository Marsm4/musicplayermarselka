import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:marselkaplaer/ProfilePage.dart';
import 'package:marselkaplaer/auth.dart';
import 'package:marselkaplaer/database/auth.dart';
import 'package:marselkaplaer/drawer.dart';
import 'package:marselkaplaer/music/player.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrackListPage extends StatefulWidget {
  const TrackListPage({super.key});

  @override
  _TrackListPageState createState() => _TrackListPageState();
}

class _TrackListPageState extends State<TrackListPage> {
  AuthService authService = AuthService();
  final SupabaseClient supabase = Supabase.instance.client;
  int currentTrackIndex = 0;
  List<Map<String, dynamic>> authors = [];
  bool isLoading = true;
  List<String> favoriteTrackIds = []; // Для хранения ID избранных треков

  List<Map<String, dynamic>> tracks = [];
  String? selectedAuthorId;
  String? selectedAuthorName;

  String searchQuery = '';
  bool isPlaying = true;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    fetchAuthors();
    fetchTracks();
    _loadFavorites(); // Загружаем избранные треки
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Загрузка избранных треков
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) return;

    final response = await supabase
        .from('favorites')
        .select('track_id')
        .eq('user_id', userId);

    setState(() {
      favoriteTrackIds =
          response.map<String>((item) => item['track_id'].toString()).toList();
    });
  }

  // Проверка, есть ли трек в избранном
  bool isFavorite(String trackId) {
    return favoriteTrackIds.contains(trackId);
  }

  // Добавление/удаление из избранного
  Future<void> _toggleFavorite(String trackId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) return;

    try {
      if (isFavorite(trackId)) {
        await supabase
            .from('favorites')
            .delete()
            .eq('user_id', userId)
            .eq('track_id', trackId);
        setState(() {
          favoriteTrackIds.remove(trackId);
        });
      } else {
        await supabase
            .from('favorites')
            .insert({'user_id': userId, 'track_id': trackId});
        setState(() {
          favoriteTrackIds.add(trackId);
        });
      }
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  // Диалог добавления в плейлист
  Future<void> _showAddToPlaylistDialog(
      BuildContext context, String trackId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) return;

    final playlists =
        await supabase.from('list').select().eq('user_id', userId);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent, // прозрачный фон
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Добавить в плейлист',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 300,
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return ListTile(
                      title: Text(
                        playlist['list_name'],
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        await _addToPlaylist(
                          playlist['id'].toString(), // Явное преобразование
                          trackId.toString(),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Добавление трека в плейлист
  Future<void> _addToPlaylist(String playlistId, String trackId) async {
    try {
      // Проверяем, не добавлен ли уже трек
      final exists = await supabase
          .from('playlist')
          .select()
          .eq('list_id', playlistId)
          .eq('track_id', trackId);

      if (exists.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Трек уже в этом плейлисте')),
        );
        return;
      }

      // Добавляем трек
      final res = await supabase
          .from('playlist')
          .insert({'list_id': playlistId, 'track_id': trackId}).select();

      if (res != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Трек добавлен')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.toString()}')),
      );
      rethrow;
    }
  }

  List<Map<String, dynamic>> get filteredTracks {
    return tracks.where((track) {
      final authorId = track['Auhror_list']['id'];
      final authorName = track['Auhror_list']['name_author'];

      final authorMatch =
          selectedAuthorId == null || authorId == selectedAuthorId;

      final searchMatch = searchQuery.isEmpty ||
          track['name_track']
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
          authorName.toLowerCase().contains(searchQuery.toLowerCase());

      return authorMatch && searchMatch;
    }).toList();
  }

  void resetFilters() {
    setState(() {
      selectedAuthorId = null;
      selectedAuthorName = null;
      searchQuery = '';
      _searchController.clear();
    });
  }

  Future<void> fetchAuthors() async {
    try {
      final response = await supabase
          .from('author')
          .select('id, created_at, name_author, image_author')
          .order('created_at', ascending: false);

      setState(() {
        authors = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      print('Ошибка при загрузке авторов: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchTracks() async {
    try {
      final response = await supabase.from('Track').select('''
      id, 
      created_at, 
      name_track, 
      image, 
      url_music,
      Auhror_list:author (id, name_author, image_author),
      genre_id:genre (id, name_genre)
    ''').order('created_at', ascending: false);

      print('Данные из Supabase: $response');
      if (response == null) {
        print('Ошибка: Пустой ответ от Supabase');
        return;
      }

      setState(() {
        tracks = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      print('Ошибка при загрузке треков: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void nextTrack() {
    setState(() {
      if (currentTrackIndex < tracks.length - 1) {
        currentTrackIndex++;
      } else {
        currentTrackIndex = 0;
      }
    });
  }

  void previousTrack() {
    setState(() {
      if (currentTrackIndex > 0) {
        currentTrackIndex--;
      } else {
        currentTrackIndex = tracks.length - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentTrack = tracks.isNotEmpty ? tracks[currentTrackIndex] : null;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue, Colors.blueGrey],
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Список треков'),
          actions: [
            IconButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(),
                  ),
                );
              },
              icon: const Icon(Icons.person, color: Colors.white),
            ),
            IconButton(
              onPressed: () async {
                await authService.LogOut();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('IsLoggedIn', false);
                Navigator.popAndPushNamed(context, '/auth');
              },
              icon: const Icon(Icons.logout, color: Colors.white),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: _searchController,
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            hintText: 'Поиск',
                            hintStyle: const TextStyle(color: Colors.white70),
                            prefixIcon:
                                const Icon(Icons.search, color: Colors.white),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide:
                                    const BorderSide(color: Colors.white)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide:
                                    const BorderSide(color: Colors.white54)),
                          ),
                          style: const TextStyle(color: Colors.white),
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          'Исполнители',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : SizedBox(
                              height: 130,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                itemCount: authors.length,
                                itemBuilder: (context, index) {
                                  final author = authors[index];
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (selectedAuthorId ==
                                            author['id'].toString()) {
                                          selectedAuthorId = null;
                                          selectedAuthorName = null;
                                          searchQuery = '';
                                          _searchController.clear();
                                        } else {
                                          selectedAuthorId =
                                              author['id'].toString();
                                          selectedAuthorName =
                                              author['name_author'];
                                          searchQuery = author['name_author'];
                                          _searchController.text =
                                              author['name_author'];
                                        }
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6),
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 70,
                                            height: 70,
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                              image:
                                                  author['image_author'] != null
                                                      ? DecorationImage(
                                                          image: NetworkImage(
                                                              author[
                                                                  'image_author']),
                                                          fit: BoxFit.cover,
                                                        )
                                                      : null,
                                              border: selectedAuthorId ==
                                                      author['id'].toString()
                                                  ? Border.all(
                                                      color: Colors.white,
                                                      width: 2)
                                                  : null,
                                            ),
                                            child:
                                                author['image_author'] == null
                                                    ? const Icon(Icons.person,
                                                        color: Colors.white,
                                                        size: 40)
                                                    : null,
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            author['name_author'] ??
                                                'Неизвестный',
                                            style: const TextStyle(
                                                color: Colors.white),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Row(
                          children: [
                            Text(
                              'Треки',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (selectedAuthorId != null ||
                                searchQuery.isNotEmpty)
                              TextButton(
                                onPressed: resetFilters,
                                child: Text(
                                  'Сбросить фильтры',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredTracks.length,
                        itemBuilder: (context, index) {
                          final track = filteredTracks[index];
                          return ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                                image: track['image'] != null
                                    ? DecorationImage(
                                        image: NetworkImage(track['image']),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: track['image'] == null
                                  ? const Icon(Icons.music_note,
                                      color: Colors.white)
                                  : null,
                            ),
                            title: Text(
                              track['name_track'] ?? 'Нет трека',
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              '${track['Auhror_list']['name_author'] ?? 'Нет исполнителя'} - ${track['genre_id']['name_genre'] ?? 'Нет жанра'}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isFavorite(track['id'].toString())
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isFavorite(track['id'].toString())
                                        ? Colors.red
                                        : Colors.white,
                                  ),
                                  onPressed: () =>
                                      _toggleFavorite(track['id'].toString()),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.playlist_add,
                                      color: Colors.white),
                                  onPressed: () => _showAddToPlaylistDialog(
                                      context, track['id'].toString()),
                                ),
                              ],
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlayerPage(
                                  nameSound: track['name_track'],
                                  author: track['Auhror_list']['name_author'],
                                  urlMusic: track['url_music'],
                                  urlPhoto: track['image'],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(10.0),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                image: currentTrack?['image'] != null
                    ? DecorationImage(
                        image: NetworkImage(currentTrack?['image']),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: currentTrack?['image'] == null
                  ? const Icon(Icons.music_note, color: Colors.white)
                  : null,
            ),
            title: Text(
              currentTrack?['name_track'] ?? 'Нет трека',
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              '${currentTrack?['Auhror_list']['name_author'] ?? 'Нет исполнителя'} - ${currentTrack?['genre_id']['name_genre'] ?? 'Нет жанра'}',
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: previousTrack,
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => PlayerPage(
                          nameSound: currentTrack?['name_track'] ?? 'Нет трека',
                          author: currentTrack?['Auhror_list']['name_author'] ??
                              'Нет исполнителя',
                          urlMusic: currentTrack?['url_music'] ?? '',
                          urlPhoto: currentTrack?['image'] ?? '',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                ),
                IconButton(
                  onPressed: nextTrack,
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        drawer: DrawerPage(),
      ),
    );
  }
}
