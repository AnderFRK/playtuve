import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class MiniPlayer extends StatelessWidget {
  final AudioPlayer reproductor;
  final VoidCallback onExpand;

  const MiniPlayer({
    super.key,
    required this.reproductor,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SequenceState?>(
      stream: reproductor.sequenceStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;

        if (state?.sequence.isEmpty ?? true) {
          return const SizedBox.shrink();
        }

        final mediaItem = state!.currentSource!.tag as MediaItem?;
        final nombreCancion = mediaItem?.title ?? 'Desconocido';

        final hasPrevious = reproductor.hasPrevious;
        final hasNext = reproductor.hasNext;

        return GestureDetector(
          onTap: onExpand,
          child: Container(
            height: 70,
            color: Colors.grey[900],
            child: Column(
              children: [
                // --- 1. BARRA DE PROGRESO LINEAL ---
                StreamBuilder<Duration>(
                  stream: reproductor.positionStream,
                  builder: (context, positionSnapshot) {
                    final position = positionSnapshot.data ?? Duration.zero;
                    final duration = reproductor.duration ?? Duration.zero;

                    double progress = 0.0;
                    if (duration.inMilliseconds > 0) {
                      progress =
                          position.inMilliseconds / duration.inMilliseconds;
                    }

                    return LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey[800],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.redAccent,
                      ),
                      minHeight: 2,
                    );
                  },
                ),

                // --- 2. CONTROLES DEL REPRODUCTOR ---
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.music_note, color: Colors.white),
                        const SizedBox(width: 12),
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

                        // Botón Retroceder
                        IconButton(
                          icon: const Icon(Icons.skip_previous),
                          color: Colors.white,
                          iconSize: 28,
                          // Si no hay canción previa, el botón se deshabilita (null)
                          onPressed: hasPrevious
                              ? () => reproductor.seekToPrevious()
                              : null,
                        ),

                        // Botón Play/Pausa en tiempo real
                        StreamBuilder<bool>(
                          stream: reproductor.playingStream,
                          builder: (context, snapshot) {
                            final isPlaying = snapshot.data ?? false;
                            return IconButton(
                              icon: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                              ),
                              color: Colors.white,
                              iconSize: 32,
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

                        // Botón Avanzar
                        IconButton(
                          icon: const Icon(Icons.skip_next),
                          color: Colors.white,
                          iconSize: 28,
                          // Si no hay siguiente canción, el botón se deshabilita (null)
                          onPressed: hasNext
                              ? () => reproductor.seekToNext()
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
