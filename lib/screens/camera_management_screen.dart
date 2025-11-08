import 'package:flutter/material.dart';
import 'package:smarttrafficapp/services/api_service.dart';
import 'package:smarttrafficapp/models/cctv.dart';

class CameraManagementScreen extends StatefulWidget {
  const CameraManagementScreen({super.key});

  @override
  State<CameraManagementScreen> createState() => _CameraManagementScreenState();
}

class _CameraManagementScreenState extends State<CameraManagementScreen> {
  final ApiService _apiService = ApiService();
  List<CCTV> _cctvList = [];
  bool _isLoading = true;

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
      if (mounted) { // Tambahkan pengecekan mounted
        setState(() {
          _cctvList = cctvs;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching CCTV list: $e');
      if (mounted) { // Tambahkan pengecekan mounted
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _addOrEditCCTV({CCTV? cctvToEdit}) async {
    final result = await showDialog<CCTV>(
      context: context,
      builder: (context) => CCTVFormDialog(cctv: cctvToEdit),
    );

    if (result != null) {
      if (cctvToEdit == null) { // Tambah baru
        await _apiService.addCCTV(result);
      } else { // Edit
        await _apiService.updateCCTV(result.id, result);
      }
      _fetchCCTVs(); // Refresh list
    }
  }

  Future<void> _deleteCCTV(String cctvId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus CCTV ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _apiService.deleteCCTV(cctvId);
      _fetchCCTVs(); // Refresh list
      if (mounted) { // Tambahkan pengecekan mounted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CCTV $cctvId dihapus')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Manajemen Kamera', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildSearchBar(context),
          const SizedBox(height: 16),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildCameraList(context),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _addOrEditCCTV(),
            icon: const Icon(Icons.add),
            label: const Text('Tambah Kamera Baru'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: TextField(
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Cari kamera...',
            hintStyle: Theme.of(context).textTheme.bodyMedium,
            border: InputBorder.none,
            icon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraList(BuildContext context) {
    if (_cctvList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Tidak ada kamera yang terdaftar.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _cctvList.length,
      itemBuilder: (context, index) {
        final cctv = _cctvList[index];
        return Card(
          color: Theme.of(context).cardColor,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 60,
                  color: Colors.grey[700],
                  child: Center(
                    child: Text(cctv.id, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cctv.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lokasi: ${cctv.location}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: ${cctv.status}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cctv.status == 'Online' ? Colors.green : Colors.red),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _addOrEditCCTV(cctvToEdit: cctv),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteCCTV(cctv.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Widget dialog untuk menambah/mengedit CCTV
class CCTVFormDialog extends StatefulWidget {
  final CCTV? cctv;

  const CCTVFormDialog({super.key, this.cctv});

  @override
  State<CCTVFormDialog> createState() => _CCTVFormDialogState();
}

class _CCTVFormDialogState extends State<CCTVFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _idController;
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _rstpUrlController;
  late TextEditingController _statusController;
  late TextEditingController _latController;
  late TextEditingController _lonController;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.cctv?.id ?? '');
    _nameController = TextEditingController(text: widget.cctv?.name ?? '');
    _locationController = TextEditingController(text: widget.cctv?.location ?? '');
    _rstpUrlController = TextEditingController(text: widget.cctv?.rstpUrl ?? '');
    _statusController = TextEditingController(text: widget.cctv?.status ?? 'Online');
    _latController = TextEditingController(text: widget.cctv?.latitude.toString() ?? '');
    _lonController = TextEditingController(text: widget.cctv?.longitude.toString() ?? '');

    if (widget.cctv != null) {
      _idController.text = widget.cctv!.id;
      // Cursor ke akhir teks, karena readOnly, tidak terlalu penting, tapi tidak ada salahnya
      _idController.selection = TextSelection.fromPosition(TextPosition(offset: _idController.text.length));
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    _rstpUrlController.dispose();
    _statusController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.cctv == null ? 'Tambah CCTV Baru' : 'Edit CCTV'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _idController,
                readOnly: widget.cctv != null, // ID tidak bisa diubah saat edit
                decoration: const InputDecoration(labelText: 'ID CCTV'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'ID tidak boleh kosong';
                  return null;
                },
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama CCTV'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Nama tidak boleh kosong';
                  return null;
                },
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Lokasi'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Lokasi tidak boleh kosong';
                  return null;
                },
              ),
              TextFormField(
                controller: _rstpUrlController,
                decoration: const InputDecoration(labelText: 'RTSP URL'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'RTSP URL tidak boleh kosong';
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _statusController.text,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ['Online', 'Offline'].map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _statusController.text = value;
                    });
                  }
                },
              ),
              TextFormField(
                controller: _latController,
                decoration: const InputDecoration(labelText: 'Latitude'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Latitude tidak boleh kosong';
                  if (double.tryParse(value) == null) return 'Input harus angka';
                  return null;
                },
              ),
              TextFormField(
                controller: _lonController,
                decoration: const InputDecoration(labelText: 'Longitude'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Longitude tidak boleh kosong';
                  if (double.tryParse(value) == null) return 'Input harus angka';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newCCTV = CCTV(
                id: _idController.text,
                name: _nameController.text,
                location: _locationController.text,
                rstpUrl: _rstpUrlController.text,
                status: _statusController.text,
                latitude: double.parse(_latController.text),
                longitude: double.parse(_lonController.text),
              );
              Navigator.of(context).pop(newCCTV);
            }
          },
          child: Text(widget.cctv == null ? 'Tambah' : 'Simpan'),
        ),
      ],
    );
  }
}