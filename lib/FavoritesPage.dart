import 'package:flutter/material.dart';
import 'package:marselkaplaer/music/player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
} //a

class _FavoritesPageState extends State<FavoritesPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> favoriteTracks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) return;

      final response = await supabase.from('favorites').select('''
            track:track_id (
              id, name_track, url_music, image,
              Auhror_list:author (name_author),
              genre_id:genre (name_genre)
            )
          ''').eq('user_id', userId);

      setState(() {
        favoriteTracks = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching favorites: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.blueGrey],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Избранное'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : favoriteTracks.isEmpty
                ? const Center(
                    child: Text('Нет избранных треков',
                        style: TextStyle(color: Colors.white)))
                : ListView.builder(
                    itemCount: favoriteTracks.length,
                    itemBuilder: (context, index) {
                      final track = favoriteTracks[index]['track'];
                      return ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            image: track['image'] != null
                                ? DecorationImage(
                                    image: NetworkImage(track['image']))
                                : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: track['image'] == null
                              ? const Icon(Icons.music_note,
                                  color: Colors.white)
                              : null,
                        ),
                        title: Text(track['name_track'],
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Text(track['Auhror_list']['name_author'],
                            style: const TextStyle(color: Colors.white70)),
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
      ),
    );
  }
}
