import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/app_state.dart';
import '../app/app_theme.dart';
import '../widgets/activity_tile.dart';
import '../widgets/empty_state.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  String _category = 'Semua';
  String _query = '';

  final List<Map<String, dynamic>> _places = [
    {
      'name': 'Taman Bungkul',
      'area': 'Wonokromo, Surabaya',
      'type': 'Jalan kaki',
      'description':
          'Pilihan untuk jogging, jalan santai, dan olahraga ringan di taman kota.',
      'image':
          'https://images.unsplash.com/photo-1470252649378-9c29740c9fa8?w=900',
      'icon': Icons.park_rounded,
      'maps':
          'https://www.google.com/maps/search/?api=1&query=Taman+Bungkul+Surabaya',
    },
    {
      'name': 'Lapangan THOR',
      'area': 'Wonokromo, Surabaya',
      'type': 'Lari',
      'description':
          'Alternatif untuk latihan lari dan aktivitas atletik.',
      'image':
          'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?w=900',
      'icon': Icons.directions_run_rounded,
      'maps':
          'https://www.google.com/maps/search/?api=1&query=Lapangan+Thor+Surabaya',
    },
    {
      'name': 'Jatim Seger Athletic Field',
      'area': 'Mulyorejo, Surabaya',
      'type': 'Lari',
      'description':
          'Pilihan tempat untuk berlatih lari dan meningkatkan kebugaran.',
      'image':
          'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=900',
      'icon': Icons.sports_rounded,
      'maps':
          'https://www.google.com/maps/search/?api=1&query=Jatim+Seger+Athletic+Field+Surabaya',
    },
    {
      'name': 'Rute Bersepeda Surabaya',
      'area': 'Surabaya, Jawa Timur',
      'type': 'Bersepeda',
      'description':
          'Temukan rute bersepeda di sekitar kota sesuai titik keberangkatanmu.',
      'image':
          'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=900',
      'icon': Icons.directions_bike_rounded,
      'maps':
          'https://www.google.com/maps/search/?api=1&query=rute+bersepeda+Surabaya',
    },
  ];

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_refresh);

    if (AppState.instance.activities.isEmpty &&
        !AppState.instance.isLoadingActivities) {
      _loadActivities();
    }
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _loadActivities() async {
    try {
      await AppState.instance.loadActivities();
    } catch (_) {
      // Pesan error ditampilkan melalui AppState.
    }
  }

  bool _matchesCategory(String type) {
    if (_category == 'Semua') return true;
    return type == _category;
  }

  Future<void> _openMaps(String url) async {
    final uri = Uri.parse(url);

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Maps tidak dapat dibuka.'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi kendala saat membuka Google Maps.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    final query = _query.trim().toLowerCase();

    final matchingActivities = app.activities.where((activity) {
      final text = '${activity.title} ${activity.type}'.toLowerCase();

      return _matchesCategory(activity.type) &&
          text.contains(query);
    }).toList();

    final filteredPlaces = _places.where((place) {
      final text =
          '${place['name']} ${place['area']} ${place['type']}'
              .toString()
              .toLowerCase();

      return _matchesCategory(place['type'] as String) &&
          text.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text(
              'EX',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            Text(
              'PLORE',
              style: TextStyle(
                color: kOrange,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang aktivitas',
            onPressed: app.isLoadingActivities ? null : _loadActivities,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadActivities,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
          children: [
            // HERO
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: kInk,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -12,
                    bottom: -18,
                    child: Icon(
                      Icons.explore_rounded,
                      size: 120,
                      color: Colors.white.withValues(alpha: .06),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: kOrange.withValues(alpha: .18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'DISCOVER YOUR NEXT MOVE',
                          style: TextStyle(
                            color: kOrange,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Keluar dan\nmulai bergerak.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 29,
                          height: 1.12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Temukan tempat baru untuk mencapai target kebugaranmu.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // SEARCH
            TextField(
              onChanged: (value) {
                setState(() => _query = value);
              },
              decoration: InputDecoration(
                hintText: 'Cari tempat atau olahraga...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? const Icon(Icons.tune_rounded)
                    : IconButton(
                        onPressed: () {
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),

            const SizedBox(height: 14),

            // CATEGORY FILTER
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Semua', 'Lari', 'Jalan kaki', 'Bersepeda']
                    .map((item) {
                  final selected = _category == item;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(item),
                      selected: selected,
                      selectedColor: kOrange.withValues(alpha: .20),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: selected ? kInk : Colors.black54,
                      ),
                      side: BorderSide(
                        color: selected ? kOrange : Colors.black12,
                      ),
                      onSelected: (_) {
                        setState(() => _category = item);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 26),

            // PLACES
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Tempat olahraga',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.5,
                    ),
                  ),
                ),
                Text(
                  '${filteredPlaces.length} tempat',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            const Text(
              'Rekomendasi tempat untuk sesi berikutnya.',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 15),

            if (filteredPlaces.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 22),
                child: Text(
                  'Tempat tidak ditemukan. Coba kata kunci lain.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...filteredPlaces.map((place) {
                return _placeCard(place);
              }),

            const SizedBox(height: 26),

            // SAVED ACTIVITIES
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Aktivitas tersimpan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.5,
                    ),
                  ),
                ),
                Text(
                  '${matchingActivities.length} aktivitas',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (app.isLoadingActivities && app.activities.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (app.activitiesError != null &&
                app.activities.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 34,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Aktivitas belum dapat dimuat.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        app.activitiesError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _loadActivities,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                ),
              )
            else if (matchingActivities.isEmpty)
              const EmptyState(
                message: 'Belum ada aktivitas yang cocok.',
              )
            else
              ...matchingActivities.map(
                (activity) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ActivityTile(activity: activity),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeCard(Map<String, dynamic> place) {
    final image = place['image'] as String;
    final name = place['name'] as String;
    final area = place['area'] as String;
    final type = place['type'] as String;
    final description = place['description'] as String;
    final maps = place['maps'] as String;
    final icon = place['icon'] as IconData;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.black.withValues(alpha: .06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 170,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFF0F1F2),
                      child: Icon(
                        icon,
                        size: 56,
                        color: kOrange,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;

                    return Container(
                      color: const Color(0xFFF0F1F2),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .94),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 14, color: kOrange),
                        const SizedBox(width: 5),
                        Text(
                          type,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.3,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: kOrange,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        area,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF62666B),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _openMaps(maps),
                    icon: const Icon(Icons.map_outlined, size: 19),
                    label: const Text('Buka Google Maps'),
                    style: FilledButton.styleFrom(
                      backgroundColor: kInk,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
