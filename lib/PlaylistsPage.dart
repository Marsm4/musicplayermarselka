import 'package:flutter/material.dart';
import 'package:marselkaplaer/PlaylistTracksPage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlaylistsPage extends StatefulWidget {
  const PlaylistsPage({super.key});

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> playlists = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPlaylists();
  }

  // Метод _fetchPlaylists() остается без изменений
  Future<void> _fetchPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        setState(() {
          errorMessage = 'Пользователь не авторизован';
          isLoading = false;
        });
        return;
      }

      final listsResponse =
          await supabase.from('list').select().eq('user_id', userId);

      if (listsResponse.isEmpty) {
        setState(() {
          playlists = [];
          isLoading = false;
        });
        return;
      }

      final List<Map<String, dynamic>> fullPlaylists = [];

      for (final list in listsResponse) {
        final playlistItems = await supabase
            .from('playlist')
            .select('track_id')
            .eq('list_id', list['id']);

        final trackIds =
            playlistItems.map<int>((item) => item['track_id'] as int).toList();

        final List<Map<String, dynamic>> tracks = [];

        if (trackIds.isNotEmpty) {
          final tracksResponse = await supabase.from('Track').select('''
                *,
                author:Auhror_list (*),
                genre:genre_id (*)
              ''').inFilter('id', trackIds);

          tracks.addAll(tracksResponse);
        }

        fullPlaylists.add({
          ...list,
          'tracks': tracks,
        });
      }

      setState(() {
        playlists = fullPlaylists;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Ошибка загрузки плейлистов: ${e.toString()}';
      });
      debugPrint('Ошибка при загрузке плейлистов: $e');
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
          title: const Text('Мои плейлисты'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: isLoading ? null : _fetchPlaylists,
            ),
          ],
        ),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showCreatePlaylistDialog(context),
          child: const Icon(Icons.add),
          backgroundColor: Colors.blueAccent,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchPlaylists,
              child: const Text('Повторить попытку'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
            ),
          ],
        ),
      );
    }

    if (playlists.isEmpty) {
      return const Center(
        child: Text(
          'У вас пока нет плейлистов',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return ListView.builder(
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        final tracks = playlist['tracks'] as List? ?? [];
        final tracksCount = tracks.length;

        return Card(
          color: Colors.white.withOpacity(0.2),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            leading:
                const Icon(Icons.playlist_play, size: 40, color: Colors.white),
            title: Text(
              playlist['list_name'] ?? 'Без названия',
              style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Треков: $tracksCount',
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () => _showPlaylistOptions(context, playlist['id']),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlaylistTracksPage(
                    tracks: tracks,
                    playlistName: playlist['list_name'] ?? 'Без названия',
                    playlistId: playlist['id'].toString(),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Остальные методы (_showCreatePlaylistDialog, _createPlaylist и т.д.)
  // остаются без изменений
  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Создать плейлист'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Название плейлиста',
              border: OutlineInputBorder(),
            ),
            maxLength: 30,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  await _createPlaylist(controller.text.trim());
                }
              },
              child: const Text('Создать'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createPlaylist(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка авторизации')),
        );
        return;
      }

      setState(() => isLoading = true);

      await supabase.from('list').insert({
        'list_name': name,
        'user_id': userId,
      });

      await _fetchPlaylists();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Плейлист "$name" создан')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showPlaylistOptions(BuildContext context, String playlistId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Переименовать'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, playlistId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Удалить', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, playlistId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRenameDialog(
      BuildContext context, String playlistId) async {
    final playlist = playlists.firstWhere((p) => p['id'] == playlistId);
    final controller = TextEditingController(text: playlist['list_name']);

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Переименовать плейлист'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Новое название',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  await _renamePlaylist(playlistId, controller.text.trim());
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _renamePlaylist(String playlistId, String newName) async {
    try {
      setState(() => isLoading = true);

      await supabase
          .from('list')
          .update({'list_name': newName}).eq('id', playlistId);

      await _fetchPlaylists();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Название плейлиста изменено')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, String playlistId) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить плейлист?'),
          content: const Text(
              'Все треки в этом плейлисте будут удалены. Это действие нельзя отменить.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(context);
                await _deletePlaylist(playlistId);
              },
              child:
                  const Text('Удалить', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePlaylist(String playlistId) async {
    try {
      setState(() => isLoading = true);

      // Сначала удаляем все треки из плейлиста
      await supabase.from('playlist').delete().eq('list_id', playlistId);

      // Затем удаляем сам плейлист
      await supabase.from('list').delete().eq('id', playlistId);

      await _fetchPlaylists();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Плейлист удален')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}
