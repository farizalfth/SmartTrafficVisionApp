// lib/screens/live_cctv_screen.dart

import 'package:flutter/material.dart';
import 'package:smarttrafficapp/widgets/cctv_feed_thumbnail.dart';
import 'package:smarttrafficapp/services/api_service.dart';
import 'package:smarttrafficapp/models/cctv.dart';

// Import video player library if you install one, e.g.:
// import 'package:fijkplayer/fijkplayer.dart'; // or
// import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class LiveCCTVScreen extends StatefulWidget {
  final String? initialCCTVId; // Untuk menampilkan CCTV tertentu saat navigasi

  const LiveCCTVScreen({super.key, this.initialCCTVId});

  @override
  State<LiveCCTVScreen> createState() => _LiveCCTVScreenState();
}

class _LiveCCTVScreenState extends State<LiveCCTVScreen> {
  final ApiService _apiService = ApiService();
  List<CCTV> _cctvList = [];
  CCTV? _selectedCCTV;
  bool _isLoading = true;

  // FijkPlayerController? _fijkPlayerController; // Contoh untuk Fijkplayer
  // VlcPlayerController? _vlcPlayerController; // Contoh untuk VLC Player

  @override
  void initState() {
    super.initState();
    _fetchCCTVs();
  }

  Future<void> _fetchCCTVs() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final cctvs = await _apiService.getCCTVs();
      if (mounted) {
        setState(() {
          _cctvList = cctvs;
          if (widget.initialCCTVId != null) {
            // Perbaikan di sini: Pastikan _cctvList tidak kosong sebelum mencoba .firstWhere
            _selectedCCTV = cctvs.isNotEmpty
                ? cctvs.firstWhere(
                    (c) => c.id == widget.initialCCTVId,
                    orElse: () => cctvs.first, // Jika ID tidak ditemukan, ambil yang pertama
                  )
                : null; // Jika list kosong, maka null
          } else {
            _selectedCCTV = cctvs.isNotEmpty ? cctvs.first : null;
          }
          _isLoading = false;
          _initializeVideoPlayer();
        });
      }
    } catch (e) {
      print('Error fetching CCTV list: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _initializeVideoPlayer() {
  }

  void _changeSelectedCCTV(CCTV cctv) {
    if (mounted) {
      setState(() {
        _selectedCCTV = cctv;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedCCTV == null) {
      return const Center(child: Text('Tidak ada CCTV yang tersedia.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Live CCTV View', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildMainCCTVFeed(context),
          const SizedBox(height: 20),
          _buildCCTVGrid(context),
        ],
      ),
    );
  }

  Widget _buildMainCCTVFeed(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 4,
      child: Column(
        children: [
          Container(
            height: 250,
            width: double.infinity,
            color: Colors.grey[800], // Placeholder for main video stream
            child: _selectedCCTV == null
                ? const Center(child: Text('Pilih CCTV', style: TextStyle(color: Colors.white54)))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Streaming from: ${_selectedCCTV!.name}', style: const TextStyle(color: Colors.white70)),
                      Text('RTSP: ${_selectedCCTV!.rstpUrl}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 10),
                      const Text('Video Player Placeholder', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lokasi: ${_selectedCCTV!.location}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Status: ${_selectedCCTV!.status}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _selectedCCTV!.status == 'Online' ? Colors.green : Colors.red),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Kepadatan: Macet (85%)', style: Theme.of(context).textTheme.bodyMedium),
                    Text('Jumlah Kendaraan: 237', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCCTVGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CCTV Lainnya', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
          ),
          itemCount: _cctvList.length,
          itemBuilder: (context, index) {
            final cctv = _cctvList[index];
            return CCTVCFeedThumbnail(
              cctvId: cctv.id,
              location: cctv.location,
              onTap: () => _changeSelectedCCTV(cctv),
            );
          },
        ),
      ],
    );
  }
}