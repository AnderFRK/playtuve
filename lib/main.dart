import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'screens/library_screen.dart';
import 'widgets/mini_player.dart';
import 'widgets/full_player.dart';
import 'screens/playlists_screen.dart';
import 'screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.anderfrk.playtuve.channel.audio',
      androidNotificationChannelName: 'Reproducción de Audio',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
    );
  } catch (e) {
    print("====== ERROR EN EL AUDIO ======");
    print(e.toString());
  }

  runApp(const PlayTuveApp());
}

class PlayTuveApp extends StatelessWidget {
  const PlayTuveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlayTuve',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const MainScaffold(),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final AudioPlayer _reproductorGlobal = AudioPlayer();
  int _indiceSeleccionado = 0; // 0 = Descargas, 1 = Playlists

  @override
  void dispose() {
    _reproductorGlobal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PlayTuve',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configuración del servidor',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            // IndexedStack mantiene el estado de ambas pantallas vivo
            child: IndexedStack(
              index: _indiceSeleccionado,
              children: [
                LibraryScreen(reproductor: _reproductorGlobal),
                // Aquí está la corrección: pasamos el reproductor a la playlist
                PlaylistsScreen(reproductor: _reproductorGlobal),
              ],
            ),
          ),
          MiniPlayer(
            reproductor: _reproductorGlobal,
            onExpand: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) =>
                    FullPlayer(reproductor: _reproductorGlobal),
              );
            },
          ),
        ],
      ),
      // --- LA NUEVA BARRA DE NAVEGACIÓN ---
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceSeleccionado,
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.grey[900], // Para que combine con el MiniPlayer
        onTap: (index) {
          setState(() {
            _indiceSeleccionado = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: 'Descargas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.queue_music),
            label: 'Playlists',
          ),
        ],
      ),
    );
  }
}
