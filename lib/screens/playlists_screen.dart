import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';

import 'playlist_detail_screen.dart';

class PlaylistsScreen extends StatefulWidget {
  final AudioPlayer reproductor;

  const PlaylistsScreen({super.key, required this.reproductor});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  List<String> _nombresPlaylists = [];
  late SharedPreferences _prefs;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _inicializarBaseDeDatos();
  }

  Future<void> _inicializarBaseDeDatos() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombresPlaylists = _prefs.getStringList('mis_playlists') ?? [];
      _cargando = false;
    });
  }

  Future<void> _guardarCambios() async {
    await _prefs.setStringList('mis_playlists', _nombresPlaylists);
  }

  int _obtenerCantidadCanciones(String nombrePlaylist) {
    List<String> canciones =
        _prefs.getStringList('playlist_$nombrePlaylist') ?? [];
    return canciones.length;
  }

  void _mostrarDialogoPlaylist({int? indexParaRenombrar}) {
    TextEditingController controller = TextEditingController();
    bool esRenombrar = indexParaRenombrar != null;
    String nombreAntiguo = "";

    if (esRenombrar) {
      nombreAntiguo = _nombresPlaylists[indexParaRenombrar];
      controller.text = nombreAntiguo;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(esRenombrar ? 'Renombrar Playlist' : 'Nueva Playlist'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "Ej: Música para programar",
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                String nombreNuevo = controller.text.trim();

                if (nombreNuevo.isNotEmpty &&
                    !_nombresPlaylists.contains(nombreNuevo)) {
                  if (esRenombrar) {
                    List<String> cancionesGuardadas =
                        _prefs.getStringList('playlist_$nombreAntiguo') ?? [];
                    await _prefs.setStringList(
                      'playlist_$nombreNuevo',
                      cancionesGuardadas,
                    );
                    await _prefs.remove('playlist_$nombreAntiguo');

                    setState(() {
                      _nombresPlaylists[indexParaRenombrar] = nombreNuevo;
                    });
                  } else {
                    setState(() {
                      _nombresPlaylists.add(nombreNuevo);
                    });
                  }

                  await _guardarCambios();
                  if (mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text(
                'Guardar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _eliminarPlaylist(int index) async {
    String nombrePlaylist = _nombresPlaylists[index];
    setState(() {
      _nombresPlaylists.removeAt(index);
    });
    await _guardarCambios();
    await _prefs.remove('playlist_$nombrePlaylist');
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: _nombresPlaylists.isEmpty
          ? const Center(
              child: Text(
                'Aún no tienes listas de reproducción',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ClipRect(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.only(
                  top: 8,
                  left: 8,
                  right: 8,
                  bottom: 80,
                ),
                itemCount: _nombresPlaylists.length,

                proxyDecorator: (child, index, animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      return Material(
                        elevation: 6.0,
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).cardColor,
                        child: child,
                      );
                    },
                    child: child,
                  );
                },

                onReorder: (int oldIndex, int newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final playlistMovida = _nombresPlaylists.removeAt(oldIndex);
                    _nombresPlaylists.insert(newIndex, playlistMovida);
                  });
                  _guardarCambios();
                },

                itemBuilder: (context, index) {
                  String nombre = _nombresPlaylists[index];
                  int cantidad = _obtenerCantidadCanciones(nombre);

                  return Card(
                    key: ValueKey(nombre),
                    child: ListTile(
                      leading: const Icon(
                        Icons.queue_music,
                        color: Colors.redAccent,
                        size: 40,
                      ),
                      title: Text(
                        nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('$cantidad canciones'),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlaylistDetailScreen(
                              nombrePlaylist: nombre,
                              reproductor: widget.reproductor,
                            ),
                          ),
                        );
                        setState(() {});
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PopupMenuButton<String>(
                            onSelected: (valor) {
                              if (valor == 'renombrar') {
                                _mostrarDialogoPlaylist(
                                  indexParaRenombrar: index,
                                );
                              }
                              if (valor == 'eliminar') {
                                _eliminarPlaylist(index);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'renombrar',
                                child: Text('Renombrar'),
                              ),
                              const PopupMenuItem(
                                value: 'eliminar',
                                child: Text(
                                  'Eliminar',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                          ReorderableDragStartListener(
                            index: index,
                            child: const Icon(
                              Icons.drag_handle,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoPlaylist(),
        backgroundColor: Colors.redAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
