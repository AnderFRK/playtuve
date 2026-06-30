import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class FullPlayer extends StatefulWidget {
  final AudioPlayer reproductor;

  const FullPlayer({super.key, required this.reproductor});

  @override
  State<FullPlayer> createState() => _FullPlayerState();
}

class _FullPlayerState extends State<FullPlayer> {
  // Variable para rastrear el arrastre del usuario sin saturar el reproductor
  double? _dragValue;

  String _formatDuration(Duration? duration) {
    if (duration == null) return "00:00";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white,
            size: 32,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reproduciendo ahora',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 15,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.music_note,
                size: 120,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 40),

            StreamBuilder<SequenceState?>(
              stream: widget.reproductor.sequenceStateStream,
              builder: (context, snapshot) {
                final mediaItem =
                    snapshot.data?.currentSource?.tag as MediaItem?;
                final nombreCancion = mediaItem?.title ?? 'Desconocido';
                return Text(
                  nombreCancion,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
            const SizedBox(height: 20),

            // --- BARRA DE PROGRESO REPARADA ---
            StreamBuilder<Duration>(
              stream: widget.reproductor.positionStream,
              builder: (context, snapshotPosition) {
                final position = snapshotPosition.data ?? Duration.zero;
                final duration = widget.reproductor.duration ?? Duration.zero;

                double maxDuration = duration.inMilliseconds.toDouble();
                if (maxDuration <= 0)
                  maxDuration = 1.0; // Previene errores matemáticos

                // Si el usuario está arrastrando, mostramos su valor; si no, mostramos el real
                double currentValue =
                    _dragValue ?? position.inMilliseconds.toDouble();
                currentValue = currentValue.clamp(0.0, maxDuration);

                return Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        activeTrackColor: Colors.redAccent,
                        inactiveTrackColor: Colors.grey[700],
                        thumbColor: Colors.redAccent,
                      ),
                      child: Slider(
                        min: 0.0,
                        max: maxDuration,
                        value: currentValue,
                        onChanged: (value) {
                          // Solo actualizamos la vista, NO el audio aún
                          setState(() {
                            _dragValue = value;
                          });
                        },
                        onChangeEnd: (value) {
                          // Ahora sí enviamos la orden de adelantar/retroceder
                          widget.reproductor.seek(
                            Duration(milliseconds: value.toInt()),
                          );
                          setState(() {
                            _dragValue = null;
                          });
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(
                            Duration(milliseconds: currentValue.toInt()),
                          ),
                          style: const TextStyle(color: Colors.grey),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),

            // --- CONTROLES SIGUIENTE/ANTERIOR REPARADOS ---
            StreamBuilder<SequenceState?>(
              stream: widget.reproductor.sequenceStateStream,
              builder: (context, sequenceSnapshot) {
                final hasPrevious = widget.reproductor.hasPrevious;
                final hasNext = widget.reproductor.hasNext;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      // Cambia a gris si no hay canción anterior
                      icon: Icon(
                        Icons.skip_previous,
                        color: hasPrevious ? Colors.white : Colors.grey[600],
                      ),
                      iconSize: 45,
                      onPressed: () {
                        if (hasPrevious) {
                          widget.reproductor.seekToPrevious();
                        } else {
                          // Si es la primera canción, simplemente la reinicia
                          widget.reproductor.seek(Duration.zero);
                        }
                      },
                    ),
                    StreamBuilder<bool>(
                      stream: widget.reproductor.playingStream,
                      builder: (context, playingSnapshot) {
                        final isPlaying = playingSnapshot.data ?? false;
                        return Container(
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            iconSize: 60,
                            onPressed: () => isPlaying
                                ? widget.reproductor.pause()
                                : widget.reproductor.play(),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      // Cambia a gris si no hay canción siguiente
                      icon: Icon(
                        Icons.skip_next,
                        color: hasNext ? Colors.white : Colors.grey[600],
                      ),
                      iconSize: 45,
                      // Se deshabilita automáticamente si no hay nada que siga
                      onPressed: hasNext
                          ? () => widget.reproductor.seekToNext()
                          : null,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 30),

            Row(
              children: [
                const Icon(Icons.volume_down, color: Colors.grey),
                Expanded(
                  child: StreamBuilder<double>(
                    stream: widget.reproductor.volumeStream,
                    builder: (context, snapshot) {
                      final volumen = snapshot.data ?? 1.0;
                      return Slider(
                        value: volumen,
                        min: 0.0,
                        max: 1.0,
                        activeColor: Colors.white,
                        inactiveColor: Colors.grey[700],
                        onChanged: (valor) =>
                            widget.reproductor.setVolume(valor),
                      );
                    },
                  ),
                ),
                const Icon(Icons.volume_up, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
