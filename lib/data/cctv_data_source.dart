// lib/data/cctv_data_source.dart

import 'package:flutter/material.dart';
import 'package:smarttrafficapp/models/cctv.dart';
import 'package:uuid/uuid.dart';
import 'dart:math'; // Import untuk menggunakan Random

class CCTVDataSource extends ChangeNotifier {
  static final CCTVDataSource _instance = CCTVDataSource._internal();

  factory CCTVDataSource() {
    return _instance;
  }

  CCTVDataSource._internal() {
    _loadInitialCCTVs();
  }

  final Uuid _uuid = const Uuid();
  List<CCTV> _cctvList = [];
  final Random _random = Random(); // Untuk memilih gambar random

  // Daftar URL gambar statis yang relevan dengan Smart Traffic
  final List<String> _staticThumbnails = [
    'https://cdn.pixabay.com/photo/2018/01/29/18/34/road-3116523_960_720.jpg', // Jalan raya
    'https://cdn.pixabay.com/photo/2017/08/06/17/23/traffic-2593717_960_720.jpg', // Lalu lintas padat
    'https://cdn.pixabay.com/photo/2016/11/18/16/27/traffic-1835039_960_720.jpg', // Pemandangan kota dari atas
    'https://cdn.pixabay.com/photo/2016/11/23/15/48/city-1854486_960_720.jpg', // Lampu kota malam hari
    'https://cdn.pixabay.com/photo/2016/09/21/04/47/traffic-1685419_960_720.jpg', // Persimpangan jalan
    'https://cdn.pixabay.com/photo/2017/03/17/12/57/traffic-2152435_960_720.jpg', // Kendaraan bergerak
    'https://cdn.pixabay.com/photo/2017/04/24/13/46/car-2256403_960_720.jpg', // Detil lampu lalu lintas
    'https://cdn.pixabay.com/photo/2015/09/21/14/33/traffic-lights-949980_960_720.jpg', // Lampu lalu lintas
  ];

  String _getRandomThumbnailUrl() {
    return _staticThumbnails[_random.nextInt(_staticThumbnails.length)];
  }

  List<CCTV> get cctvList => List.unmodifiable(_cctvList);

  void _loadInitialCCTVs() {
    _cctvList = [
      CCTV(
        id: _uuid.v4(),
        name: 'CCTV Pontianak (Simpang Garuda)',
        location: 'Simpang Garuda, Pontianak',
        latitude: -0.0245,
        longitude: 109.3406,
        status: 'Aktif',
        lastUpdate: '2024-05-15 10:30:00',
        rstpUrl: 'https://www.youtube.com/watch?v=M7FIW2vD8G8',
        thumbnailUrl: _getRandomThumbnailUrl(), // Menambahkan thumbnail statis
      ),
      CCTV(
        id: _uuid.v4(),
        name: 'CCTV Pontianak (Tugu Khatulistiwa)',
        location: 'Tugu Khatulistiwa, Pontianak',
        latitude: 0.0000,
        longitude: 109.3300,
        status: 'Aktif',
        lastUpdate: '2024-05-15 10:30:00',
        rstpUrl: 'https://www.youtube.com/watch?v=Fj-E_P-P3L8',
        thumbnailUrl: _getRandomThumbnailUrl(),
      ),
      CCTV(
        id: _uuid.v4(),
        name: 'CCTV Demak (Alun-Alun)',
        location: 'Alun-Alun, Demak',
        latitude: -6.8906,
        longitude: 110.6385,
        status: 'Aktif',
        lastUpdate: '2024-05-15 10:32:15',
        rstpUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        thumbnailUrl: _getRandomThumbnailUrl(),
      ),
      CCTV(
        id: _uuid.v4(),
        name: 'CCTV Demak (Pasar Bintoro)',
        location: 'Pasar Bintoro, Demak',
        latitude: -6.8850,
        longitude: 110.6400,
        status: 'Aktif',
        lastUpdate: '2024-05-15 10:32:15',
        rstpUrl: 'https://www.youtube.com/watch?v=o04_sWJkXvY',
        thumbnailUrl: _getRandomThumbnailUrl(),
      ),
      CCTV(
        id: _uuid.v4(),
        name: 'CCTV Demak (Pertigaan Trengguli)',
        location: 'Pertigaan Trengguli, Demak',
        latitude: -6.8700,
        longitude: 110.6500,
        status: 'Aktif',
        lastUpdate: '2024-05-15 10:32:15',
        rstpUrl: 'https://www.youtube.com/watch?v=iik25wqIuFo',
        thumbnailUrl: _getRandomThumbnailUrl(),
      ),
      CCTV(
        id: _uuid.v4(),
        name: 'CCTV Magelang (Simpang Artos)',
        location: 'Simpang Artos, Magelang',
        latitude: -7.5000,
        longitude: 110.2000,
        status: 'Aktif',
        lastUpdate: '2024-05-15 10:35:00',
        rstpUrl: 'https://www.youtube.com/watch?v=gS8lVqfS44A',
        thumbnailUrl: _getRandomThumbnailUrl(),
      ),
      CCTV(
        id: _uuid.v4(),
        name: 'CCTV Semarang (Simpang Lima)',
        location: 'Simpang Lima, Semarang',
        latitude: -6.9832,
        longitude: 110.4093,
        status: 'Aktif',
        lastUpdate: '2024-05-15 10:30:00',
        rstpUrl: 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
        thumbnailUrl: _getRandomThumbnailUrl(),
      ),
      CCTV(
        id: _uuid.v4(),
        name: 'CCTV Solo (Gladag)',
        location: 'Gladag, Solo',
        latitude: -7.5604,
        longitude: 110.8291,
        status: 'Aktif',
        lastUpdate: '2024-05-15 10:32:15',
        rstpUrl: 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_2mb.mp4',
        thumbnailUrl: _getRandomThumbnailUrl(),
      ),
    ];
  }

  void addCCTV(CCTV newCCTV) {
    _cctvList.add(newCCTV.copyWith(
      id: _uuid.v4(),
      thumbnailUrl: _getRandomThumbnailUrl(), // Berikan thumbnail random saat menambah
    ));
    notifyListeners();
  }

  void updateCCTV(CCTV updatedCCTV) {
    final index = _cctvList.indexWhere((c) => c.id == updatedCCTV.id);
    if (index != -1) {
      _cctvList[index] = updatedCCTV;
      notifyListeners();
    }
  }

  void deleteCCTV(String cctvId) {
    _cctvList.removeWhere((c) => c.id == cctvId);
    notifyListeners();
  }
}