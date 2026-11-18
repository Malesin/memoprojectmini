import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'memo_model.dart';

/// Komponen UI kartu memo bergaya pastel sesuai prototype
class MemoCard extends StatelessWidget {
  final Memo memo;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const MemoCard({
    super.key,
    required this.memo,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // Pilih warna pastel berdasarkan colorIndex
    final cardColor = pastelColors[memo.colorIndex % pastelColors.length];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Judul Memo (Bold, maksimal 1 baris)
                Text(
                  memo.title.isEmpty ? 'Tanpa Judul' : memo.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // 2. Cuplikan Isi Catatan (Maksimal 2 baris)
                Expanded(
                  child: Text(
                    memo.content.trim().isEmpty
                        ? '(Tidak ada isi teks)'
                        : memo.content,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4A4A4A),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // 3. Footer Kartu: Tanggal di kiri, Ikon Media (Kamera & Mic) di kanan
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Tanggal format ringkas (contoh: "15 Nov")
                    Text(
                      DateFormat('dd MMM').format(memo.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF757575),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    // Indikator ikon lampiran
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (memo.imagePath != null && memo.imagePath!.isNotEmpty) ...[
                          const Icon(
                            Icons.image_outlined,
                            size: 14,
                            color: Color(0xFF616161),
                          ),
                          if (memo.hasVoice) const SizedBox(width: 4),
                        ],
                        if (memo.hasVoice)
                          const Icon(
                            Icons.mic_none_outlined,
                            size: 14,
                            color: Color(0xFF616161),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
