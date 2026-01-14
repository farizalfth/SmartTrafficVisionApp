// lib/screens/live_cctv_screen.dart

// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:smarttrafficapp/models/cctv.dart';
import 'package:smarttrafficapp/data/cctv_data_source.dart';

class LiveCCTVScreen extends StatefulWidget {
  final String? initialCCTVId;

  const LiveCCTVScreen({super.key, this.initialCCTVId});

  @override
  State<LiveCCTVScreen> createState() => _LiveCCTVScreenState();
}

class _LiveCCTVScreenState extends State<LiveCCTVScreen> {
  YoutubePlayerController? _controller;
  CCTV? _selectedCCTV;
  String _searchQuery = '';
  bool _isInit = true;

  // --- DATABASE ---
  static const String _dbUrl =
      'https://smart-traffic-vision-app-default-rtdb.asia-southeast1.firebasedatabase.app/';
  late final DatabaseReference _trafficStatsRef;

  @override
  void initState() {
    super.initState();
    // Inisialisasi Database Spesifik Region
    final firebaseApp = Firebase.app();
    final rtdb =
        FirebaseDatabase.instanceFor(app: firebaseApp, databaseURL: _dbUrl);

    // Arahkan ke 'traffic_stats'
    _trafficStatsRef = rtdb.ref('traffic_stats');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final dataProvider = Provider.of<CCTVDataSource>(context, listen: false);
      if (dataProvider.cctvList.isNotEmpty) {
        if (widget.initialCCTVId != null) {
          try {
            _selectedCCTV = dataProvider.cctvList
                .firstWhere((c) => c.id == widget.initialCCTVId);
          } catch (e) {
            _selectedCCTV = dataProvider.cctvList.first;
          }
        } else {
          _selectedCCTV = dataProvider.cctvList.first;
        }
        _initializePlayer(_selectedCCTV!);
      }
      _isInit = false;
    }
  }

  void _initializePlayer(CCTV cctv) {
    final videoId = YoutubePlayer.convertUrlToId(cctv.rstpUrl);

    if (_controller != null) {
      _controller!.dispose(); // Dispose controller lama sebelum buat baru
      _controller = null;
    }

    if (videoId != null) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          isLive: true,
          forceHD: false,
          enableCaption: false,
        ),
      );
    }

    setState(() {
      _selectedCCTV = cctv;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live CCTV'),
        backgroundColor: Colors.transparent,
        elevation: 0,

        // --- TAMBAHKAN BAGIAN INI (TOMBOL MENU) ---
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            // Membuka Sidebar/Drawer
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      body: Consumer<CCTVDataSource>(
        builder: (context, dataSource, child) {
          final allCCTVs = dataSource.cctvList;

          if (allCCTVs.isEmpty)
            return const Center(child: Text("Belum ada data CCTV."));

          final filteredList = allCCTVs.where((cctv) {
            final matchesSearch =
                cctv.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    cctv.location
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase());
            final isNotPlaying = cctv.id != _selectedCCTV?.id;
            return matchesSearch && isNotPlaying;
          }).toList();

          // Safety check jika CCTV terpilih hilang dari list
          if (_selectedCCTV != null &&
              !allCCTVs.any((c) => c.id == _selectedCCTV!.id)) {
            if (allCCTVs.isNotEmpty) {
              _initializePlayer(allCCTVs.first);
            } else {
              _selectedCCTV = null;
              _controller = null;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedCCTV != null)
                  _buildMainPlayerArea(context, _selectedCCTV!),
                const SizedBox(height: 24),
                Text('CCTV Lainnya',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Cari lokasi atau nama CCTV...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 16),
                if (filteredList.isEmpty && _searchQuery.isNotEmpty)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text("Tidak ditemukan CCTV yang cocok.",
                              style: TextStyle(color: Colors.grey))))
                else
                  _buildCCTVGrid(filteredList),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainPlayerArea(BuildContext context, CCTV cctv) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // VIDEO PLAYER CONTAINER
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: _controller != null
              ? AspectRatio(
                  aspectRatio: 16 / 9,
                  child: YoutubePlayer(
                    controller: _controller!,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: Colors.redAccent,
                    bottomActions: [
                      CurrentPosition(),
                      ProgressBar(
                          isExpanded: true,
                          colors: const ProgressBarColors(
                              playedColor: Colors.red,
                              handleColor: Colors.redAccent)),
                      FullScreenButton(),
                    ],
                  ),
                )
              : Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.black,
                  child: const Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        Icon(Icons.videocam_off,
                            color: Colors.white54, size: 50),
                        SizedBox(height: 10),
                        Text("Stream Offline / URL RTSP",
                            style: TextStyle(color: Colors.white54)),
                      ])),
                ),
        ),
        const SizedBox(height: 16),

        // INFO CARD DENGAN DATA FIREBASE REALTIME
        Card(
          color: Theme.of(context).cardColor,
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cctv.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on,
                      color: Colors.blueAccent, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                      child: Text(cctv.location,
                          style: const TextStyle(color: Colors.white70),
                          overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 12),

                // --- STREAM BUILDER KHUSUS ID CCTV INI ---
                StreamBuilder(
                    stream: _trafficStatsRef
                        .child(cctv.id)
                        .onValue, // Mengambil data berdasarkan ID (misal: "3", "4")
                    builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                      String status = "Online";
                      String countText = "0";
                      String densityText = "Normal";

                      if (snapshot.hasData &&
                          snapshot.data!.snapshot.value != null) {
                        try {
                          final rawValue = snapshot.data!.snapshot.value;

                          // PARSING DATA PINTAR (Langsung atau Nested 'live')
                          if (rawValue is Map) {
                            if (rawValue.containsKey('live')) {
                              // Struktur ID 4: { live: { total: 6, status: "Lancar" } }
                              final liveData = rawValue['live'] as Map;
                              countText = liveData['total_akumulasi_hari_ini']
                                      ?.toString() ??
                                  "0";
                              densityText =
                                  liveData['status']?.toString() ?? "Normal";
                            } else {
                              // Struktur ID 3: { total: 2, status: "Lancar" }
                              countText = rawValue['total_akumulasi_hari_ini']
                                      ?.toString() ??
                                  "0";
                              densityText =
                                  rawValue['status']?.toString() ?? "Normal";
                            }
                          }

                          // Update status visual berdasarkan teks dari firebase
                          if (densityText.toLowerCase().contains("macet")) {
                            status = "Macet";
                          } else if (densityText
                              .toLowerCase()
                              .contains("padat")) status = "Padat";
                        } catch (e) {
                          debugPrint("Error parsing detail CCTV: $e");
                        }
                      }

                      Color statusColor = Colors.green;
                      if (status == "Macet") statusColor = Colors.red;
                      if (status == "Padat") statusColor = Colors.orange;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // BADGE STATUS
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: statusColor)),
                            child: Text("Status: $status",
                                style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          ),
                          // DETAIL KENDARAAN
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("Kepadatan: $densityText",
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: status == "Macet"
                                          ? Colors.redAccent
                                          : Colors.white70)),
                              Text("Jumlah Kendaraan: $countText",
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ],
                          )
                        ],
                      );
                    })
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCCTVGrid(List<CCTV> list) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return GestureDetector(
          onTap: () => _initializePlayer(item),
          child: Card(
            color: Theme.of(context).cardColor,
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(12)),
                      color: Colors.black26),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.red.withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 2)
                          ]),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 32),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(item.location,
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ]),
              ),
            ]),
          ),
        );
      },
    );
  }
}
