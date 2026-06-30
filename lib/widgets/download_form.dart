import 'package:flutter/material.dart';

class DownloadForm extends StatelessWidget {
  final TextEditingController controller;
  final bool isDownloading;
  final double progress;
  final VoidCallback onDownload;

  const DownloadForm({
    super.key,
    required this.controller,
    required this.isDownloading,
    required this.progress,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Pega el enlace de YouTube aquí',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.link),
          ),
          enabled: !isDownloading,
        ),
        const SizedBox(height: 16),

        // La barra de progreso solo aparece cuando está descargando
        if (isDownloading) ...[
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            color: Colors.redAccent,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
        ],

        ElevatedButton.icon(
          onPressed: isDownloading ? null : onDownload,
          icon: isDownloading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download),
          // Mostramos el porcentaje real en el botón
          label: Text(
            isDownloading
                ? 'Descargando... ${(progress * 100).toInt()}%'
                : 'Descargar Audio',
          ),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
        ),
      ],
    );
  }
}
