
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../app/app_state.dart';
import '../app/app_theme.dart';
import '../services/api_service.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key, required this.onSaved});

  final VoidCallback onSaved;

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  final MapController _mapController = MapController();
  final TextEditingController _titleController =
      TextEditingController(text: 'Aktivitas Saya');

  Timer? _timer;
  StreamSubscription<Position>? _positionStream;

  int _seconds = 0;
  bool _running = false;
  bool _paused = false;
  bool _saving = false;
  bool _gpsActive = false;
  bool _mapReady = false;

  String _type = 'Lari';
  String _locationStatus = 'GPS belum diaktifkan';

  double _distanceKm = 0;
  Position? _currentPosition;
  DateTime? _startedAt;

  // Semua titik GPS yang dilewati selama aktivitas.
  final List<LatLng> _routePoints = [];

  static const LatLng _defaultCenter = LatLng(-7.2575, 112.7521);

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    _titleController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  String get _time {
    final minutes = (_seconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _pace {
    if (_distanceKm <= 0 || _seconds <= 0) {
      return '--:-- /km';
    }

    final paceSeconds = (_seconds / _distanceKm).round();
    final minutes = (paceSeconds ~/ 60).toString();
    final seconds = (paceSeconds % 60).toString().padLeft(2, '0');

    return '$minutes:$seconds /km';
  }

  Future<bool> _checkLocationPermission() async {
    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return false;

        setState(() {
          _locationStatus = 'Layanan lokasi belum aktif';
        });

        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Lokasi belum aktif'),
            content: const Text(
              'Aktifkan layanan lokasi perangkat, kemudian coba lagi. '
              'Jika menggunakan Chrome, periksa juga izin lokasi situs.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Mengerti'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await Geolocator.openLocationSettings();
                },
                child: const Text('Pengaturan lokasi'),
              ),
            ],
          ),
        );

        return false;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return false;

        setState(() {
          _locationStatus = 'Izin lokasi ditolak';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Izinkan akses lokasi untuk merekam rute GPS.',
            ),
          ),
        );

        return false;
      }

      return true;
    } catch (error) {
      if (mounted) {
        setState(() {
          _locationStatus = 'Pemeriksaan lokasi gagal';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pemeriksaan lokasi gagal: $error')),
        );
      }
      return false;
    }
  }

  Future<void> _start() async {
    if (_running || _saving) return;

    final permitted = await _checkLocationPermission();
    if (!mounted || !permitted) return;

    setState(() {
      _running = true;
      _paused = false;
      _gpsActive = false;
      _seconds = 0;
      _distanceKm = 0;
      _currentPosition = null;
      _routePoints.clear();
      _startedAt = DateTime.now();
      _locationStatus = 'Mencari posisi GPS...';
    });

    _startTimer();
    await _startGpsTracking();
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_running || _paused || _saving) return;

      setState(() {
        _seconds++;
      });
    });
  }

  Future<void> _startGpsTracking() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      if (!mounted || !_running) return;

      _updatePosition(position, countDistance: false);

      const settings = LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1,
      );

      await _positionStream?.cancel();

      _positionStream = Geolocator.getPositionStream(
        locationSettings: settings,
      ).listen(
        (position) {
          if (!_running || _paused || !mounted) return;
          _updatePosition(position);
        },
        onError: (Object error) {
          if (!mounted) return;

          setState(() {
            _gpsActive = false;
            _locationStatus = 'Sinyal GPS terganggu';
          });
        },
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _gpsActive = false;
        _locationStatus = 'Tidak bisa mendapatkan posisi GPS';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('GPS belum mendapatkan posisi: $error'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _updatePosition(
    Position position, {
    bool countDistance = true,
  }) {
    final newPoint = LatLng(position.latitude, position.longitude);
    final previous = _currentPosition;

    if (countDistance && previous != null) {
      final meters = Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        position.latitude,
        position.longitude,
      );

      // Abaikan lonjakan posisi yang tidak masuk akal.
      if (meters >= 1 && meters <= 100) {
        _distanceKm += meters / 1000;
      } else if (meters > 100) {
        // Jangan menggambar garis panjang akibat lonjakan GPS.
        if (mounted) {
          setState(() {
            _currentPosition = position;
            _gpsActive = true;
            _locationStatus = 'GPS aktif';
          });
        }
        _moveMap(newPoint);
        return;
      }
    }

    _currentPosition = position;

    if (_routePoints.isEmpty ||
          Geolocator.distanceBetween(
        _routePoints.last.latitude,
        _routePoints.last.longitude,
        newPoint.latitude,
        newPoint.longitude,
        ) >= 1) {
      _routePoints.add(newPoint);
    }

    if (mounted) {
      setState(() {
        _gpsActive = true;
        _locationStatus = 'GPS aktif';
      });
    }

    _moveMap(newPoint);
  }

  void _moveMap(LatLng point) {
    if (!_mapReady) return;

    try {
      _mapController.move(point, 16);
    } catch (_) {
      // Peta mungkin sedang diinisialisasi; titik tetap disimpan.
    }
  }

  void _pauseResume() {
    if (!_running || _saving) return;

    setState(() {
      _paused = !_paused;
      _locationStatus = _paused
          ? 'Aktivitas dijeda'
          : (_gpsActive ? 'GPS aktif' : 'Menunggu sinyal GPS');
    });
  }

  Future<double?> _askDistance() async {
    final controller = TextEditingController(
      text: _distanceKm > 0 ? _distanceKm.toStringAsFixed(2) : '',
    );

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Simpan aktivitas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _distanceKm > 0
                  ? 'Jarak GPS: ${_distanceKm.toStringAsFixed(2)} km. '
                      'Kamu bisa mengoreksinya jika perlu.'
                  : 'Jarak GPS belum tersedia. Masukkan jarak secara manual.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Jarak (km)',
                hintText: 'Contoh: 2.5',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'CANCEL'),
            child: const Text('Lanjutkan nanti'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim(),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result == null || result == 'CANCEL') return null;

    final distance = double.tryParse(result.replaceAll(',', '.'));

    if (distance == null || !distance.isFinite || distance <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jarak tidak valid. Masukkan angka lebih dari 0.'),
          ),
        );
      }
      return null;
    }

    return distance;
  }

  Future<void> _finish() async {
    if (!_running || _seconds == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mulai aktivitas terlebih dahulu.'),
        ),
      );
      return;
    }

    if (_saving) return;

    setState(() {
      _saving = true;
      _paused = true;
    });

    final distance = await _askDistance();

    if (!mounted) return;

    if (distance == null) {
      setState(() {
        _saving = false;
        _paused = true;
        _locationStatus = 'Aktivitas dijeda';
      });
      return;
    }

    final sportType = switch (_type) {
      'Lari' => 'running',
      'Bersepeda' => 'cycling',
      'Jalan kaki' => 'walking',
      _ => 'running',
    };

    try {
      final activityResult = await ApiService.createActivity(
        sportType: sportType,
        distanceKm: distance,
        durationSeconds: _seconds,
        title: _titleController.text.trim().isEmpty
            ? 'Aktivitas Saya'
            : _titleController.text.trim(),
        startedAt: _startedAt ?? DateTime.now(),
      );

      // Ambil ID aktivitas yang baru dibuat di database.
      final activityData = activityResult['activity'];

      if (activityData is! Map ||
          activityData['id'] == null) {
        throw Exception(
          'Aktivitas tersimpan, tetapi ID aktivitas tidak ditemukan.',
        );
      }

      final activityId = int.parse(
        activityData['id'].toString(),
      );

      // Ubah koordinat GPS menjadi format JSON untuk Laravel.
      final routeData = _routePoints.asMap().entries.map((entry) {
        return <String, dynamic>{
          'sequence': entry.key,
          'latitude': entry.value.latitude,
          'longitude': entry.value.longitude,
        };
      }).toList();

      // Simpan rute apabila ada titik GPS yang berhasil direkam.
      if (routeData.isNotEmpty) {
        await ApiService.saveActivityRoute(
          activityId: activityId,
          routePoints: routeData,
        );
      }

      await AppState.instance.loadActivities();

      await AppState.instance.loadActivities();

      if (!mounted) return;

     
      _timer?.cancel();
      await _positionStream?.cancel();
      _positionStream = null;

      if (!mounted) return;

      setState(() {
        _seconds = 0;
        _distanceKm = 0;
        _running = false;
        _paused = false;
        _saving = false;
        _gpsActive = false;
        _currentPosition = null;
        _routePoints.clear();
        _startedAt = null;
        _locationStatus = 'GPS belum diaktifkan';
        _titleController.text = 'Aktivitas Saya';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aktivitas berhasil disimpan ke database!'),
        ),
      );

      widget.onSaved();

      widget.onSaved();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _saving = false;
        _paused = true;
        _locationStatus = 'Aktivitas dijeda';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Aktivitas gagal disimpan: '
            '${error.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Widget _buildMap() {
    final center = _currentPosition == null
        ? _defaultCenter
        : LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 330,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 15,
            onMapReady: () {
              _mapReady = true;
              if (_currentPosition != null) {
                _moveMap(center);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.strafit.app',
            ),
            if (_routePoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: List<LatLng>.from(_routePoints),
                    strokeWidth: 5,
                    color: kOrange,
                  ),
                ],
              ),
            if (_currentPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    width: 48,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: kOrange,
                          width: 3,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.navigation_rounded,
                        color: kOrange,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Activity')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const Text(
            'Waktunya bergerak!',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Catat aktivitas dan pantau progresmu.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 18),
          _buildMap(),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 18,
                color: _gpsActive ? Colors.green : kOrange,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _locationStatus,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Pusatkan peta ke posisi GPS',
                onPressed: _currentPosition == null
                    ? null
                    : () => _moveMap(
                          LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          ),
                        ),
                icon: const Icon(Icons.my_location_rounded),
              ),
            ],
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(
                      labelText: 'Jenis olahraga',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Lari',
                        child: Text('Lari'),
                      ),
                      DropdownMenuItem(
                        value: 'Bersepeda',
                        child: Text('Bersepeda'),
                      ),
                      DropdownMenuItem(
                        value: 'Jalan kaki',
                        child: Text('Jalan kaki'),
                      ),
                    ],
                    onChanged: _running
                        ? null
                        : (value) {
                            setState(() {
                              _type = value ?? 'Lari';
                            });
                          },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Nama aktivitas',
                    ),
                    enabled: !_running,
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'DURASI',
                    style: TextStyle(
                      color: Colors.black54,
                      letterSpacing: 1.5,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _time,
                    style: const TextStyle(
                      fontSize: 54,
                      fontWeight: FontWeight.w900,
                      color: kInk,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'JARAK TEMPUH',
                    style: TextStyle(
                      color: Colors.black54,
                      letterSpacing: 1.2,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_distanceKm.toStringAsFixed(2)} km',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: kOrange,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'PACE RATA-RATA',
                    style: TextStyle(
                      color: Colors.black54,
                      letterSpacing: 1.2,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _pace,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: kInk,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _running
                        ? (_paused
                            ? 'Aktivitas sedang dijeda'
                            : 'Aktivitas sedang berjalan')
                        : 'Tekan Mulai untuk merekam rute GPS.',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  if (!_running)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _start,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Mulai merekam'),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _saving ? null : _pauseResume,
                            icon: Icon(
                              _paused
                                  ? Icons.play_arrow_rounded
                                  : Icons.pause_rounded,
                            ),
                            label: Text(
                              _paused ? 'Lanjutkan' : 'Jeda',
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _finish,
                            icon: _saving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.stop_rounded),
                            label: Text(
                              _saving ? 'Menyimpan...' : 'Selesai',
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Peta membutuhkan koneksi internet. Garis rute terbentuk '
            'saat perangkat menerima perubahan posisi GPS. Rute saat '
            'ini ditampilkan selama sesi merekam; penyimpanan koordinat '
            'ke database belum ditambahkan.',
            style: TextStyle(
              color: Colors.black45,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
