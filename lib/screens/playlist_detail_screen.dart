import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../widgets/audio_card.dart';
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

  // --- NUEVA LÓGICA PARA EL BOTÓN + ---
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
          height:
              MediaQuery.of(context).size.height *
              0.7, // Ocupa el 70% de la pantalla
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
                                ? null // Si ya está, no hace nada
                                : () async {
                                    // Añadimos a la base de datos y a la vista actual
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    setState(() {
                                      _canciones.add(rutaAudio);
                                    });
                                    await prefs.setStringList(
                                      'playlist_${widget.nombrePlaylist}',
                                      _canciones,
                                    );

                                    if (mounted) {
                                      Navigator.pop(
                                        context,
                                      ); // Cierra el modal automáticamente al tocar una
                                    }
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nombrePlaylist),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. Todo el contenido de tu lista lo envolvemos en un Expanded
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
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _canciones.length,
                    itemBuilder: (context, index) {
                      String ruta = _canciones[index];

                      return AudioCard(
                        ruta: ruta,
                        onPlay: () async {
                          try {
                            final playlist = ConcatenatingAudioSource(
                              children: _canciones.map((rutaAudio) {
                                String nombre = rutaAudio
                                    .split('/')
                                    .last
                                    .replaceAll('.m4a', '');
                                return AudioSource.uri(
                                  Uri.file(rutaAudio),
                                  tag: MediaItem(
                                    id: rutaAudio,
                                    title: nombre,
                                    album: widget.nombrePlaylist,
                                  ),
                                );
                              }).toList(),
                            );

                            await widget.reproductor.setAudioSource(
                              playlist,
                              initialIndex: index,
                            );
                            widget.reproductor.play();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al reproducir: $e'),
                                ),
                              );
                            }
                          }
                        },
                        onDelete: () => _quitarDePlaylist(index),
                        onAddPlaylist: () {},
                      );
                    },
                  ),
          ),

          // 2. Aquí añadimos el MiniPlayer al fondo de la pantalla
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

      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarBuscadorDeCanciones,
        backgroundColor: Colors.redAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      // Elevamos el botón flotante un poco para que el MiniPlayer no lo tape
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
