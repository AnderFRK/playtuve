import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/backend_config.dart';
import '../widgets/download_form.dart';
import '../widgets/audio_card.dart';

class LibraryScreen extends StatefulWidget {
  final AudioPlayer reproductor;

  const LibraryScreen({super.key, required this.reproductor});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _estaDescargando = false;
  double _progresoDescarga = 0.0;
  List<String> _todosLosAudios = [];
  List<String> _audiosFiltrados = [];

  @override
  void initState() {
    super.initState();
    _cargarAudiosGuardados();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarAudiosGuardados() async {
    try {
      final directorioMusica = await getApplicationDocumentsDirectory();

      if (await directorioMusica.exists()) {
        List<FileSystemEntity> archivos = directorioMusica.listSync();
        List<String> rutas = [];

        for (var archivo in archivos) {
          if (archivo.path.endsWith('.m4a')) {
            rutas.add(archivo.path);
          }
        }

        setState(() {
          _todosLosAudios = rutas;
          _audiosFiltrados = rutas;
        });
      }
    } catch (e) {
      debugPrint("Error al cargar: $e");
    }
  }

  Future<void> _eliminarAudio(String ruta) async {
    try {
      File archivo = File(ruta);

      if (await archivo.exists()) {
        await archivo.delete();
      }

      setState(() {
        _todosLosAudios.remove(ruta);
        _filtrarAudios(_searchController.text);
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Canción eliminada.')));
      }
    } catch (e) {
      debugPrint(">>> ERROR al eliminar: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  Future<void> _mostrarDialogoAgregarPlaylist(String rutaAudio) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> playlists = prefs.getStringList('mis_playlists') ?? [];

    if (playlists.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes playlists creadas aún.')),
      );
      return;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Se adapta al tamaño del contenido
            children: [
              const Text(
                'Añadir a Playlist',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    String nombrePlaylist = playlists[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.queue_music,
                        color: Colors.redAccent,
                      ),
                      title: Text(nombrePlaylist),
                      onTap: () async {
                        // 1. Leemos las canciones de esa playlist
                        List<String> canciones =
                            prefs.getStringList('playlist_$nombrePlaylist') ??
                            [];

                        // 2. Si no está repetida, la agregamos
                        if (!canciones.contains(rutaAudio)) {
                          canciones.add(rutaAudio);
                          await prefs.setStringList(
                            'playlist_$nombrePlaylist',
                            canciones,
                          );

                          if (mounted) {
                            Navigator.pop(context); // Cierra el modal
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Añadida a "$nombrePlaylist" ✅'),
                              ),
                            );
                          }
                        } else {
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'La canción ya está en esta lista ⚠️',
                                ),
                              ),
                            );
                          }
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

  Future<void> _descargarAudio() async {
    String urlOriginal = _urlController.text.trim();

    String backendActual = await BackendConfig.obtenerUrl();

    if (backendActual.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ Primero configura la URL del servidor en Configuración.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (urlOriginal.isEmpty) return;

    if (!urlOriginal.contains('youtube.com') &&
        !urlOriginal.contains('youtu.be')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enlace inválido.')));
      return;
    }

    setState(() {
      _estaDescargando = true;
      _progresoDescarga = 0.0;
    });

    try {
      debugPrint(">>> Pidiendo info al backend en: $backendActual");

      var infoResponse = await http
          .post(
            Uri.parse(
              '$backendActual/info',
            ), // <-- Usamos la URL actualizada aquí
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'url': urlOriginal}),
          )
          .timeout(const Duration(seconds: 60));

      if (infoResponse.statusCode != 200) {
        throw Exception('Error al obtener info: ${infoResponse.body}');
      }

      var info = jsonDecode(infoResponse.body);
      String titulo = info['titulo'] ?? 'audio';
      String tituloLimpio = titulo.replaceAll(RegExp(r'[\\/:*?"<>|]'), '');

      debugPrint(">>> Título obtenido: $tituloLimpio");
      debugPrint(">>> Descargando audio desde el backend...");

      var response = await http
          .post(
            Uri.parse('$backendActual/descargar'), // <-- Y aquí también
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'url': urlOriginal}),
          )
          .timeout(const Duration(minutes: 3));

      if (response.statusCode != 200) {
        throw Exception('Error del servidor: ${response.body}');
      }

      final directorio = await getApplicationDocumentsDirectory();
      String rutaArchivo = '${directorio.path}/$tituloLimpio.m4a';

      File archivo = File(rutaArchivo);
      await archivo.writeAsBytes(response.bodyBytes);

      debugPrint(
        ">>> Descarga completa: $rutaArchivo (${response.bodyBytes.length} bytes)",
      );

      setState(() {
        _todosLosAudios.add(rutaArchivo);
        _filtrarAudios(_searchController.text);
        _urlController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('¡Descarga completada!')));
      }
    } catch (e) {
      debugPrint(">>> ERROR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } finally {
      setState(() {
        _estaDescargando = false;
        _progresoDescarga = 0.0;
      });
    }
  }

  // --- LÓGICA DE BÚSQUEDA ---

  void _filtrarAudios(String query) {
    if (query.isEmpty) {
      setState(() {
        _audiosFiltrados = _todosLosAudios;
      });
    } else {
      setState(() {
        _audiosFiltrados = _todosLosAudios.where((ruta) {
          String nombreArchivo = ruta.split('/').last.toLowerCase();
          return nombreArchivo.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  // --- INTERFAZ ---

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          DownloadForm(
            controller: _urlController,
            isDownloading: _estaDescargando,
            progress: _progresoDescarga,
            onDownload: _descargarAudio,
          ),
          const SizedBox(height: 16),
          const Divider(),

          TextField(
            controller: _searchController,
            onChanged: _filtrarAudios,
            decoration: InputDecoration(
              labelText: 'Buscar en mis descargas...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: _audiosFiltrados.isEmpty
                ? const Center(
                    child: Text(
                      'No se encontraron audios',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _audiosFiltrados.length,
                    itemBuilder: (context, index) {
                      String ruta = _audiosFiltrados[index];
                      return AudioCard(
                        ruta: ruta,
                        onPlay: () async {
                          try {
                            final playlist = ConcatenatingAudioSource(
                              children: _audiosFiltrados.map((rutaAudio) {
                                String nombre = rutaAudio
                                    .split('/')
                                    .last
                                    .replaceAll('.m4a', '');

                                return AudioSource.uri(
                                  Uri.file(rutaAudio),
                                  tag: MediaItem(
                                    id: rutaAudio,
                                    title: nombre,
                                    album: "PlayTuve",
                                  ),
                                );
                              }).toList(),
                            );

                            await widget.reproductor.setAudioSource(
                              playlist,
                              initialIndex:
                                  index, // El índice actual del ListView
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
                        onAddPlaylist: () =>
                            _mostrarDialogoAgregarPlaylist(ruta),
                        onDelete: () => _eliminarAudio(ruta),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
