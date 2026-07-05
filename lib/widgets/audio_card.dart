import 'package:flutter/material.dart';

class AudioCard extends StatelessWidget {
  final String ruta;
  final VoidCallback onPlay;
  final VoidCallback onDelete;
  final VoidCallback onAddPlaylist;

  const AudioCard({
    super.key,
    required this.ruta,
    required this.onPlay,
    required this.onDelete,
    required this.onAddPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    String nombreArchivo = ruta.split('/').last.replaceAll('.m4a', '');

    return Card(
      child: ListTile(
        leading: const Icon(Icons.music_note, color: Colors.redAccent),
        title: Text(
          nombreArchivo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: onPlay, // Al tocar la fila entera, se reproduce
        // 3. Cambiamos el trailing por un menú de opciones
        trailing: PopupMenuButton<String>(
          onSelected: (valor) {
            if (valor == 'playlist') onAddPlaylist();
            if (valor == 'eliminar') onDelete();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'playlist',
              child: Row(
                children: [
                  Icon(Icons.playlist_add, color: Colors.black54),
                  SizedBox(width: 8),
                  Text('Añadir a playlist'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'eliminar',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
