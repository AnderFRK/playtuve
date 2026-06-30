import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';

// Asegúrate de que esta ruta coincida con el nombre de tu archivo de detalles
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

  // 1. Cargar datos guardados
  Future<void> _inicializarBaseDeDatos() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombresPlaylists = _prefs.getStringList('mis_playlists') ?? [];
      _cargando = false;
    });
  }

  // 2. Guardar cambios
  Future<void> _guardarCambios() async {
    await _prefs.setStringList('mis_playlists', _nombresPlaylists);
  }

  // 3. Obtener la cantidad de canciones de una playlist
  int _obtenerCantidadCanciones(String nombrePlaylist) {
    List<String> canciones =
        _prefs.getStringList('playlist_$nombrePlaylist') ?? [];
    return canciones.length;
  }

  // 4. Cuadro de diálogo para Crear o Renombrar
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
                    // Mover las canciones de la llave vieja a la llave nueva
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
                    // Crear nueva playlist vacía
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

  // 5. Confirmación para Eliminar
  Future<void> _eliminarPlaylist(int index) async {
    String nombrePlaylist = _nombresPlaylists[index];

    setState(() {
      _nombresPlaylists.removeAt(index);
    });

    await _guardarCambios();
    // Borramos también la música asociada a esa playlist
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
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _nombresPlaylists.length,
              itemBuilder: (context, index) {
                String nombre = _nombresPlaylists[index];
                int cantidad = _obtenerCantidadCanciones(nombre);

                return Card(
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
                      // Navegamos a la pantalla de detalles
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlaylistDetailScreen(
                            nombrePlaylist: nombre,
                            reproductor: widget.reproductor,
                          ),
                        ),
                      );
                      // Refresca la vista al volver (por si se borraron canciones)
                      setState(() {});
                    },
                    trailing: PopupMenuButton<String>(
                      onSelected: (valor) {
                        if (valor == 'renombrar') {
                          _mostrarDialogoPlaylist(indexParaRenombrar: index);
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
                  ),
                );
              },
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
