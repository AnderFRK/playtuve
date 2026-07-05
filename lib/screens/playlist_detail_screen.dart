import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../widgets/mini_player.dart';
import '../widgets/full_player.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String nombrePlaylist;
  final AudioPlayer reproductor;

  const PlaylistDetailScreen({
    super.key,
    required this.nombrePlaylist,
    required this.reproductor,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  List<String> _canciones = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCanciones();
  }

  Future<void> _cargarCanciones() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _canciones =
          prefs.getStringList('playlist_${widget.nombrePlaylist}') ?? [];
      _cargando = false;
    });
  }

  Future<void> _quitarDePlaylist(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _canciones.removeAt(index);
    });
    await prefs.setStringList('playlist_${widget.nombrePlaylist}', _canciones);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Canción removida de la lista')),
      );
    }
  }

  Future<void> _reproducirDesde(int index) async {
    try {
      final fuentes = _canciones.map((ruta) {
        String nombre = ruta.split('/').last.replaceAll('.m4a', '');
        return AudioSource.uri(
          Uri.file(ruta),
          tag: MediaItem(id: ruta, title: nombre, album: widget.nombrePlaylist),
        );
      }).toList();

      final playlist = ConcatenatingAudioSource(children: fuentes);
      await widget.reproductor.setAudioSource(playlist, initialIndex: index);
      widget.reproductor.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al reproducir: $e')));
      }
    }
  }

  Future<void> _mostrarBuscadorDeCanciones() async {
    final directorioMusica = await getApplicationDocumentsDirectory();
    List<String> todasLasRutas = [];

    if (await directorioMusica.exists()) {
      List<FileSystemEntity> archivos = directorioMusica.listSync();
      for (var archivo in archivos) {
        if (archivo.path.endsWith('.m4a')) {
          todasLasRutas.add(archivo.path);
        }
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            children: [
              const Text(
                'Selecciona canciones para añadir',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Expanded(
                child: todasLasRutas.isEmpty
                    ? const Center(child: Text('No hay canciones descargadas.'))
                    : ListView.builder(
                        itemCount: todasLasRutas.length,
                        itemBuilder: (context, index) {
                          String rutaAudio = todasLasRutas[index];
                          String nombre = rutaAudio
                              .split('/')
                              .last
                              .replaceAll('.m4a', '');
                          bool yaEstaEnLista = _canciones.contains(rutaAudio);

                          return ListTile(
                            leading: const Icon(
                              Icons.music_note,
                              color: Colors.grey,
                            ),
                            title: Text(
                              nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: yaEstaEnLista
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : const Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.redAccent,
                                  ),
                            onTap: yaEstaEnLista
                                ? null
                                : () async {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    setState(() {
                                      _canciones.add(rutaAudio);
                                    });
                                    await prefs.setStringList(
                                      'playlist_${widget.nombrePlaylist}',
                                      _canciones,
                                    );
                                    if (mounted) Navigator.pop(context);
                                  },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const double alturaMiniPlayer = 64.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nombrePlaylist),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _canciones.isEmpty
                ? const Center(
                    child: Text(
                      'Esta lista está vacía.\n¡Usa el botón + para añadir música!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.only(
                      top: 8,
                      left: 8,
                      right: 8,
                      bottom: 140,
                    ),
                    itemCount: _canciones.length,

                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          return Material(
                            elevation: 6.0,
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[850],
                            child: child,
                          );
                        },
                        child: child,
                      );
                    },

                    onReorder: (int oldIndex, int newIndex) async {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final cancionMovida = _canciones.removeAt(oldIndex);
                        _canciones.insert(newIndex, cancionMovida);
                      });

                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setStringList(
                        'playlist_${widget.nombrePlaylist}',
                        _canciones,
                      );
                    },

                    itemBuilder: (context, index) {
                      final rutaCancion = _canciones[index];
                      final nombreLimpio = rutaCancion
                          .split('/')
                          .last
                          .replaceAll('.m4a', '');

                      return Card(
                        key: ValueKey(rutaCancion),
                        child: ListTile(
                          leading: const Icon(
                            Icons.music_note,
                            color: Colors.redAccent,
                          ),
                          title: Text(
                            nombreLimpio,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.grey,
                                ),
                                onPressed: () => _quitarDePlaylist(index),
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
                          onTap: () => _reproducirDesde(index),
                        ),
                      );
                    },
                  ),
          ),

          MiniPlayer(
            reproductor: widget.reproductor,
            onExpand: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) =>
                    FullPlayer(reproductor: widget.reproductor),
              );
            },
          ),
        ],
      ),

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: alturaMiniPlayer),
        child: FloatingActionButton(
          onPressed: _mostrarBuscadorDeCanciones,
          backgroundColor: Colors.redAccent,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
