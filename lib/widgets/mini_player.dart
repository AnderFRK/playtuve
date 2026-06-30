import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class MiniPlayer extends StatelessWidget {
  final AudioPlayer reproductor;
  final VoidCallback
  onExpand; // Esta función se usará en la Fase 3 para agrandarlo

  const MiniPlayer({
    super.key,
    required this.reproductor,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    // Escuchamos el estado general del reproductor para saber qué canción suena
    return StreamBuilder<SequenceState?>(
      stream: reproductor.sequenceStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;

        // Si no hay ninguna canción cargada, ocultamos el reproductor
        if (state?.sequence.isEmpty ?? true) {
          return const SizedBox.shrink();
        }

        // Recuperamos el nombre de la canción que le pasaremos como "tag"
        final mediaItem = state!.currentSource!.tag as MediaItem?;
        final nombreCancion = mediaItem?.title ?? 'Desconocido';

        return GestureDetector(
          onTap: onExpand,
          child: Container(
            height: 70,
            color: Colors.grey[900], // Fondo oscuro estilo Spotify
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.music_note, color: Colors.white),
                const SizedBox(width: 12),

                // Nombre de la canción
                Expanded(
                  child: Text(
                    nombreCancion,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Botón Play/Pausa que reacciona en tiempo real
                StreamBuilder<bool>(
                  stream: reproductor.playingStream,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data ?? false;
                    return IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: () {
                        if (isPlaying) {
                          reproductor.pause();
                        } else {
                          reproductor.play();
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
