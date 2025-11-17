import 'package:flutter/material.dart';
import 'package:smarttrafficapp/widgets/cctv_feed_thumbnail.dart';
import 'package:smarttrafficapp/services/api_service.dart';
import 'package:smarttrafficapp/models/cctv.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:flutter/services.dart'; // Untuk DeviceOrientation

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

  VlcPlayerController? _vlcPlayerController; // Deklarasikan VlcPlayerController
  bool _isPlaying = false;
  double _sliderValue = 0.0;
  double _volume = 100;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _fetchCCTVs();
  }

  Future<void> _fetchCCTVs() async {
    if (!mounted) return; // Pastikan widget masih ada sebelum setState
    setState(() {
      _isLoading = true;
    });
    try {
      final cctvs = await _apiService.getCCTVs();
      if (mounted) { // Pastikan widget masih ada setelah operasi async
        setState(() {
          _cctvList = cctvs;

          // Logika pemilihan CCTV awal yang diperbaiki
          if (widget.initialCCTVId != null && cctvs.isNotEmpty) {
            _selectedCCTV = cctvs.firstWhere(
              (c) => c.id == widget.initialCCTVId,
              // PERBAIKAN: Jika ID tidak ditemukan, kembalikan CCTV pertama di daftar.
              // Ini aman karena kita sudah memastikan cctvs.isNotEmpty.
              orElse: () => cctvs.first,
            );
          } else if (cctvs.isNotEmpty) {
            // Jika initialCCTVId null (tidak ada ID spesifik) dan daftar CCTV tidak kosong,
            // ambil CCTV pertama sebagai default.
            _selectedCCTV = cctvs.first;
          } else {
            // Jika daftar CCTV benar-benar kosong, tidak ada CCTV yang bisa dipilih.
            _selectedCCTV = null;
          }

          _isLoading = false;
          _initializeVideoPlayer(); // Panggil inisialisasi player setelah _selectedCCTV diset
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
    // Pastikan ada CCTV yang dipilih dan memiliki RTSP URL
    if (_selectedCCTV != null && _selectedCCTV!.rstpUrl.isNotEmpty) {
      // Buang controller lama sebelum membuat yang baru untuk mencegah kebocoran memori
      _vlcPlayerController?.dispose();

      _vlcPlayerController = VlcPlayerController.network(
        _selectedCCTV!.rstpUrl,
        hwAcc: HwAcc.full, // Gunakan akselerasi hardware untuk performa lebih baik
        autoPlay: true, // Otomatis putar saat inisialisasi
        options: VlcPlayerOptions(
          // Anda bisa menambahkan opsi VlcPlayerOptions lainnya di sini
          // Misalnya untuk pengaturan cache atau network (contoh di bawah)
          // HttpOptions([
          //   HttpOptions.httpReconnect(true),
          // ]),
          // VideoOptions([
          //   VideoOptions.dropLateFrames(true),
          //   VideoOptions.skipFrames(true),
          // ]),
        ),
      );

      _vlcPlayerController?.addListener(() {
        if (!mounted) return; // Pastikan widget masih ada sebelum setState
        // Perbarui UI hanya jika player sudah diinisialisasi untuk menghindari error
        if (_vlcPlayerController!.value.isInitialized) {
          setState(() {
            _isPlaying = _vlcPlayerController!.value.isPlaying;
            // Pastikan sliderValue tidak melebihi max durasi dan tidak negatif
            _sliderValue = _vlcPlayerController!.value.position.inSeconds.toDouble();
            if (_sliderValue > _vlcPlayerController!.value.duration.inSeconds.toDouble()) {
              _sliderValue = _vlcPlayerController!.value.duration.inSeconds.toDouble();
            }
            if (_sliderValue < 0) _sliderValue = 0.0;
          });
        }
      });
    } else {
      // Jika tidak ada CCTV yang dipilih atau RTSP URL kosong, buang controller
      _vlcPlayerController?.dispose();
      _vlcPlayerController = null;
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _sliderValue = 0.0;
        });
      }
    }
  }

  void _changeSelectedCCTV(CCTV cctv) {
    if (mounted) {
      setState(() {
        _selectedCCTV = cctv;
        _initializeVideoPlayer(); // Inisialisasi ulang player untuk CCTV baru
      });
    }
  }

  @override
  void dispose() {
    _vlcPlayerController?.dispose(); // Sangat penting untuk membuang controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Jika setelah loading tidak ada CCTV sama sekali dalam daftar
    if (_cctvList.isEmpty) {
      return const Center(child: Text('Tidak ada CCTV yang tersedia.'));
    }

    // _selectedCCTV seharusnya sudah diset di _fetchCCTVs,
    // tetapi ini sebagai guardrail tambahan jika ada edge case
    if (_selectedCCTV == null) {
      return const Center(child: Text('Gagal memilih CCTV awal.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live CCTV'),
        backgroundColor: Colors.transparent, // Background transparan untukAppBar
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
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
            color: Colors.black, // Background untuk video player
            child: _selectedCCTV == null || _vlcPlayerController == null || !_vlcPlayerController!.value.isInitialized
                ? Center(
                    child: _selectedCCTV == null
                        ? const Text('Pilih CCTV', style: TextStyle(color: Colors.white54))
                        : Text(
                            'Memuat ${_selectedCCTV!.name}...\n'
                            'RTSP: ${_selectedCCTV!.rstpUrl}\n'
                            'Pastikan URL RTSP valid dan dapat diakses.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                  )
                : VlcPlayer(
                    controller: _vlcPlayerController!,
                    // Periksa apakah aspectRatio valid sebelum menggunakannya
                    aspectRatio: (_vlcPlayerController!.value.aspectRatio.isFinite && _vlcPlayerController!.value.aspectRatio > 0)
                        ? _vlcPlayerController!.value.aspectRatio
                        : 16 / 9, // Fallback ke 16/9 jika tidak valid
                    placeholder: const Center(child: CircularProgressIndicator()),
                  ),
          ),
          _buildVideoControls(), // Tambahkan kontrol video
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nama CCTV: ${_selectedCCTV!.name}', // Ambil nama dari _selectedCCTV
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Lokasi: ${_selectedCCTV!.location}', // Ambil lokasi dari _selectedCCTV
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Status: ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      _selectedCctvStatusDisplay(_selectedCCTV!),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _selectedCCTV!.status == 'Online' ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Ini adalah data dummy, di aplikasi nyata didapat dari hasil ML backend
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

  Widget _buildVideoControls() {
    if (_vlcPlayerController == null || !_vlcPlayerController!.value.isInitialized) {
      return const SizedBox.shrink(); // Sembunyikan kontrol jika player belum siap
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Theme.of(context).canvasColor, // Warna background untuk kontrol
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () {
                  if (_isPlaying) {
                    _vlcPlayerController?.pause();
                  } else {
                    _vlcPlayerController?.play();
                  }
                  if (mounted) setState(() {});
                },
              ),
              Expanded(
                child: Slider(
                  value: _sliderValue,
                  min: 0.0,
                  // Pastikan durasi tidak negatif atau tidak valid
                  max: _vlcPlayerController!.value.duration.inSeconds.toDouble() > 0 ? _vlcPlayerController!.value.duration.inSeconds.toDouble() : 1.0,
                  onChanged: (newValue) {
                    if (mounted) setState(() => _sliderValue = newValue);
                  },
                  onChangeEnd: (newValue) {
                    _vlcPlayerController?.seekTo(Duration(seconds: newValue.toInt()));
                  },
                ),
              ),
              Text(
                '${_printDuration(_vlcPlayerController!.value.position)} / ${_printDuration(_vlcPlayerController!.value.duration)}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(_volume == 0 ? Icons.volume_off : Icons.volume_up),
                onPressed: () {
                  if (_volume == 0) {
                    _vlcPlayerController?.setVolume(100);
                    if (mounted) setState(() => _volume = 100);
                  } else {
                    _vlcPlayerController?.setVolume(0);
                    if (mounted) setState(() => _volume = 0);
                  }
                },
              ),
              DropdownButton<double>(
                value: _playbackSpeed,
                dropdownColor: Theme.of(context).canvasColor, // agar drop down terlihat
                items: const [
                  DropdownMenuItem(value: 0.5, child: Text('0.5x')),
                  DropdownMenuItem(value: 1.0, child: Text('1.0x')),
                  DropdownMenuItem(value: 1.5, child: Text('1.5x')),
                  DropdownMenuItem(value: 2.0, child: Text('2.0x')),
                ],
                onChanged: (speed) {
                  if (speed != null) {
                    _vlcPlayerController?.setPlaybackSpeed(speed);
                    if (mounted) setState(() => _playbackSpeed = speed);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.fullscreen),
                onPressed: () {
                  // Ini biasanya melibatkan SystemChrome.setEnabledSystemUIMode dan rotasi layar
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCCTVGrid(BuildContext context) {
    // Filter CCTV yang sedang dipilih agar tidak muncul di daftar "CCTV Lainnya"
    final otherCCTVs = _cctvList.where((c) => c.id != _selectedCCTV?.id).toList();

    if (otherCCTVs.isEmpty) {
      return const Text('Tidak ada CCTV lainnya.');
    }

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
          itemCount: otherCCTVs.length,
          itemBuilder: (context, index) {
            final cctv = otherCCTVs[index];
            return CCTVCFeedThumbnail(
              cctvId: cctv.id,
              location: cctv.location, // Ini akan menampilkan lokasi dari _dummyCCTVs (Jawa Tengah)
              // URL gambar placeholder yang lebih informatif
              imageUrl: cctv.status == 'Online'
                  ? 'https://via.placeholder.com/150/00FF00/FFFFFF?text=${Uri.encodeComponent(cctv.name)}' // Gunakan Uri.encodeComponent
                  : 'https://via.placeholder.com/150/FF0000/FFFFFF?text=${Uri.encodeComponent(cctv.name)}',
              congestionLevel: cctv.status == 'Online' ? 'Sedang (45%)' : 'Offline', // Placeholder data kepadatan
              onTap: () => _changeSelectedCCTV(cctv),
            );
          },
        ),
      ],
    );
  }

  String _selectedCctvStatusDisplay(CCTV cctv) {
    if (_vlcPlayerController != null && _vlcPlayerController!.value.isInitialized) {
      if (_vlcPlayerController!.value.hasError) {
        return 'Error Streaming';
      }
      if (_vlcPlayerController!.value.isBuffering) {
        return 'Buffering...';
      }
      if (!_vlcPlayerController!.value.isPlaying && _vlcPlayerController!.value.position == Duration.zero) {
        return 'Siap Diputar';
      }
    }
    return cctv.status;
  }

  String _printDuration(Duration duration) {
    if (duration.isNegative) return "00:00:00"; // Handle negatif duration
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}