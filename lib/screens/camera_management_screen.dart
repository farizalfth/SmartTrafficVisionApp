// lib/screens/camera_management_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smarttrafficapp/models/cctv.dart';
import 'package:smarttrafficapp/data/cctv_data_source.dart';

class CameraManagementScreen extends StatefulWidget {
  const CameraManagementScreen({super.key});

  @override
  State<CameraManagementScreen> createState() => _CameraManagementScreenState();
}

class _CameraManagementScreenState extends State<CameraManagementScreen> {
  String _searchQuery = ''; 

  // Filter List
  List<CCTV> _getFilteredCCTVList(List<CCTV> cctvList) {
    if (_searchQuery.isEmpty) {
      return cctvList;
    }
    return cctvList.where((cctv) {
      return cctv.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          cctv.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          cctv.id.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // Dialog Tambah/Edit
  Future<void> _addOrEditCCTV({CCTV? cctvToEdit}) async {
    final result = await showDialog<CCTV>(
      context: context,
      builder: (context) => CCTVFormDialog(cctv: cctvToEdit),
    );

    if (result != null && mounted) {
      final cctvDataSource = Provider.of<CCTVDataSource>(context, listen: false);
      
      if (cctvToEdit == null) {
        cctvDataSource.addCCTV(result);
        _showSnackBar('Kamera "${result.name}" berhasil ditambahkan!', Colors.green);
      } else {
        final updatedCCTV = result.copyWith(id: cctvToEdit.id); 
        cctvDataSource.updateCCTV(updatedCCTV);
        _showSnackBar('Kamera "${result.name}" berhasil diperbarui!', Colors.blue);
      }
    }
  }

  // Dialog Hapus
  Future<void> _deleteCCTV(String cctvId, String cctvName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Kamera?', style: TextStyle(color: Colors.white)),
        content: Text('Anda yakin ingin menghapus "$cctvName"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final cctvDataSource = Provider.of<CCTVDataSource>(context, listen: false);
      cctvDataSource.deleteCCTV(cctvId);
      _showSnackBar('Kamera "$cctvName" telah dihapus.', Colors.redAccent);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Kamera'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<CCTVDataSource>(
        builder: (context, cctvDataSource, child) {
          final List<CCTV> cctvList = cctvDataSource.cctvList;
          final List<CCTV> filteredList = _getFilteredCCTVList(cctvList);

          return Column(
            children: [
              // SEARCH BAR (Desain Dipercantik)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Cari nama, lokasi, atau ID...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),

              // LIST KAMERA
              Expanded(
                child: filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam_off, size: 64, color: Colors.grey[800]),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada data kamera.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        // PENTING: Padding bawah ditambah agar item terakhir tidak ketutup tombol
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 100),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          return _buildCCTVCard(context, filteredList[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      // TOMBOL TAMBAH (Floating)
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 10), // Sedikit naik dari bawah layar
        child: FloatingActionButton.extended(
          onPressed: () => _addOrEditCCTV(),
          label: const Text(
            'Tambah Kamera',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          icon: const Icon(Icons.add_rounded, size: 28),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, // Posisi Tengah Bawah
    );
  }

  Widget _buildCCTVCard(BuildContext context, CCTV cctv) {
    // Tentukan warna status
    final bool isOnline = cctv.status == 'Online' || cctv.status == 'Aktif';
    final Color statusColor = isOnline ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      color: Theme.of(context).cardColor, 
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _addOrEditCCTV(cctvToEdit: cctv), // Edit saat tap card (opsional)
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // THUMBNAIL (Kotak Gelap + Play Merah)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 90,
                  height: 70,
                  color: Colors.black26, 
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // INFO TEXT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cctv.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            cctv.location,
                            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // STATUS BADGE
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
                      ),
                      child: Text(
                        isOnline ? "ONLINE" : "OFFLINE",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ACTIONS (Edit & Delete)
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                    onPressed: () => _addOrEditCCTV(cctvToEdit: cctv),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _deleteCCTV(cctv.id, cctv.name),
                    tooltip: 'Hapus',
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- FORM DIALOG (RAPID & BERSIH) ---
class CCTVFormDialog extends StatefulWidget {
  final CCTV? cctv;
  const CCTVFormDialog({super.key, this.cctv});

  @override
  State<CCTVFormDialog> createState() => _CCTVFormDialogState();
}

class _CCTVFormDialogState extends State<CCTVFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _rstpUrlController;
  late TextEditingController _latController;
  late TextEditingController _lonController;
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.cctv?.name ?? '');
    _locationController = TextEditingController(text: widget.cctv?.location ?? '');
    _rstpUrlController = TextEditingController(text: widget.cctv?.rstpUrl ?? '');
    _latController = TextEditingController(text: widget.cctv?.latitude.toString() ?? '');
    _lonController = TextEditingController(text: widget.cctv?.longitude.toString() ?? '');
    
    // Normalisasi status (jika data lama 'Aktif', ubah jadi 'Online' untuk dropdown)
    String statusRaw = widget.cctv?.status ?? 'Online';
    if (statusRaw == 'Aktif') statusRaw = 'Online';
    if (statusRaw == 'Tidak Aktif') statusRaw = 'Offline';
    _selectedStatus = statusRaw;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _rstpUrlController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Style Input
    final inputDecoration = InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: const Color(0xFF2C2C2C), // Warna input lebih gelap dari dialog
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      hintStyle: TextStyle(color: Colors.grey[600]),
      labelStyle: const TextStyle(color: Colors.white70),
    );

    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E), // Background Dialog Gelap
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(widget.cctv == null ? Icons.add_circle : Icons.edit, color: Colors.blueAccent),
          const SizedBox(width: 10),
          Text(widget.cctv == null ? 'Tambah Kamera' : 'Edit Kamera', style: const TextStyle(color: Colors.white)),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration.copyWith(labelText: 'Nama CCTV', prefixIcon: const Icon(Icons.videocam, color: Colors.grey)),
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration.copyWith(labelText: 'Lokasi', prefixIcon: const Icon(Icons.location_on, color: Colors.grey)),
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _rstpUrlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration.copyWith(labelText: 'URL Stream (YouTube/RTSP)', prefixIcon: const Icon(Icons.link, color: Colors.grey)),
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  dropdownColor: const Color(0xFF2C2C2C),
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration.copyWith(labelText: 'Status', prefixIcon: const Icon(Icons.info_outline, color: Colors.grey)),
                  items: ['Online', 'Offline'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _selectedStatus = v!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: inputDecoration.copyWith(labelText: 'Latitude', prefixIcon: const Icon(Icons.map, size: 18, color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lonController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: inputDecoration.copyWith(labelText: 'Longitude'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _saveForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(widget.cctv == null ? 'Simpan' : 'Update'),
        ),
      ],
    );
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      final newCCTV = CCTV(
        id: widget.cctv?.id ?? DateTime.now().millisecondsSinceEpoch.toString(), 
        name: _nameController.text,
        location: _locationController.text,
        rstpUrl: _rstpUrlController.text,
        status: _selectedStatus,
        latitude: double.tryParse(_latController.text) ?? 0.0,
        longitude: double.tryParse(_lonController.text) ?? 0.0,
        lastUpdate: DateTime.now().toIso8601String(),
      );

      Navigator.pop(context, newCCTV);
    }
  }
}