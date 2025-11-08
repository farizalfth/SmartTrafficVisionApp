// lib/widgets/cctv_feed_thumbnail.dart
import 'package:flutter/material.dart';

class CCTVCFeedThumbnail extends StatelessWidget {
  final String cctvId;
  final String location;
  final String? imageUrl; // Placeholder for actual video thumbnail
  final VoidCallback? onTap;

  const CCTVCFeedThumbnail({
    super.key,
    required this.cctvId,
    required this.location,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Theme.of(context).cardColor,
        elevation: 2,
        margin: const EdgeInsets.only(right: 10),
        child: SizedBox(
          width: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  color: Colors.grey[800], // Placeholder for video
                  child: Center(
                    child: Text(
                      'CCTV $cctvId',
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  location,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}