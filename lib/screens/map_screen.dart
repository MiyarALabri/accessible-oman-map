import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_place_screen.dart';
import 'login_screen.dart';
import 'place_details_screen.dart';
import 'supabase_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  int currentIndex = 0;
  List<Map<String, dynamic>> places = [];
  bool loading = true;
  String searchQuery = '';

  final supabase = Supabase.instance.client;
  final mapController = MapController();

  @override
  void initState() {
    super.initState();
    fetchPlaces();
  }

  Future<void> fetchPlaces() async {
    if (mounted) setState(() => loading = true);

    try {
      final data = await supabase.from('places').select().order('name');
      if (!mounted) return;
      setState(() => places = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('FETCH ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load places: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> openAddPlace() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPlaceScreen()),
    );

    if (result == true) {
      await fetchPlaces();
      setState(() => currentIndex = 0);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Place added successfully ✅'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool isAccessible(Map<String, dynamic> p) {
    return p['has_ramp'] == true ||
        p['has_toilet'] == true ||
        p['has_wide_door'] == true ||
        p['has_elevator'] == true;
  }

  List<Map<String, dynamic>> get visiblePlaces {
    if (searchQuery.trim().isEmpty) return places;
    final q = searchQuery.toLowerCase().trim();
    return places.where((p) {
      return (p['name'] ?? '').toString().toLowerCase().contains(q) ||
          (p['description'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  List<Marker> getMarkers() {
    return visiblePlaces.map((p) {
      final lat = double.tryParse(p['lat'].toString()) ?? 23.5859;
      final lng = double.tryParse(p['lng'].toString()) ?? 58.4059;
      final accessible = isAccessible(p);

      return Marker(
        point: LatLng(lat, lng),
        width: 64,
        height: 64,
        child: GestureDetector(
          onTap: () => _showPlaceSheet(p),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              accessible ? Icons.accessible_forward : Icons.location_on,
              color: accessible ? Colors.green.shade700 : Colors.red.shade500,
              size: 36,
            ),
          ),
        ),
      );
    }).toList();
  }

  void _showPlaceSheet(Map<String, dynamic> place) {
    final accessible = isAccessible(place);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: accessible ? Colors.green.shade50 : Colors.red.shade50,
                    child: Icon(
                      accessible ? Icons.check_circle : Icons.info_outline,
                      color: accessible ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      place['name'] ?? 'No name',
                      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(place['description'] ?? 'No description'),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _featureChip('Ramp', place['has_ramp'] == true, Icons.accessible),
                  _featureChip('Toilet', place['has_toilet'] == true, Icons.wc),
                  _featureChip('Wide Door', place['has_wide_door'] == true, Icons.door_front_door),
                  _featureChip('Elevator', place['has_elevator'] == true, Icons.elevator),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PlaceDetailsScreen(place: place)),
                    );
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('View Details'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _featureChip(String label, bool enabled, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 18, color: enabled ? Colors.green.shade800 : Colors.grey),
      label: Text(label),
      backgroundColor: enabled ? Colors.green.shade50 : Colors.grey.shade100,
      side: BorderSide(color: enabled ? Colors.green.shade200 : Colors.grey.shade300),
    );
  }

  Widget mapPage() {
    if (loading) return const Center(child: CircularProgressIndicator());

    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: const MapOptions(
            initialCenter: LatLng(23.5859, 58.4059),
            initialZoom: 10,
          ),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
            MarkerLayer(markers: getMarkers()),
          ],
        ),
        Positioned(
          left: 16,
          right: 16,
          top: 16,
          child: Material(
            borderRadius: BorderRadius.circular(20),
            elevation: 6,
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: const InputDecoration(
                hintText: 'Search accessible places...',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget listPage() {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (visiblePlaces.isEmpty) {
      return const Center(child: Text('No places found'));
    }

    return RefreshIndicator(
      onRefresh: fetchPlaces,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: visiblePlaces.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: TextField(
                onChanged: (value) => setState(() => searchQuery = value),
                decoration: const InputDecoration(
                  hintText: 'Search by name or description',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            );
          }

          final p = visiblePlaces[index - 1];
          final accessible = isAccessible(p);
          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: CircleAvatar(
                backgroundColor: accessible ? Colors.green.shade50 : Colors.red.shade50,
                child: Icon(
                  accessible ? Icons.accessible_forward : Icons.location_on,
                  color: accessible ? Colors.green.shade700 : Colors.red.shade500,
                ),
              ),
              title: Text(
                p['name'] ?? 'No name',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(p['description'] ?? 'No description', maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PlaceDetailsScreen(place: p)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget homePage() {
    final accessibleCount = places.where(isAccessible).length;
    return RefreshIndicator(
      onRefresh: fetchPlaces,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Image.network(
                  'https://images.unsplash.com/photo-1604357209793-fca5dca89f97?auto=format&fit=crop&w=1200&q=80',
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 190, color: const Color(0xFF12372A)),
                ),
                Container(
                  height: 190,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.38)),
                  child: const Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      'Discover accessible places in Oman',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _statCard('Places', places.length.toString(), Icons.place)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Accessible', accessibleCount.toString(), Icons.accessible_forward)),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Accessibility Features', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: const [
                      Chip(label: Text('♿ Ramp')),
                      Chip(label: Text('🚻 Toilet')),
                      Chip(label: Text('🚪 Wide Door')),
                      Chip(label: Text('🛗 Elevator')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF12372A), size: 30),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            Text(title, style: TextStyle(color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  Widget filterPage() {
    return FilterScreen(
      onApply: (filteredPlaces) {
        setState(() {
          places = filteredPlaces;
          currentIndex = 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Filter applied ✅'), backgroundColor: Colors.blue),
        );
      },
    );
  }

  Widget getBody() {
    switch (currentIndex) {
      case 0:
        return homePage();
      case 1:
        return mapPage();
      case 2:
        return listPage();
      case 3:
        return filterPage();
      default:
        return homePage();
    }
  }

  String get title {
    switch (currentIndex) {
      case 0:
        return 'Accessible Oman';
      case 1:
        return 'Map';
      case 2:
        return 'Places';
      case 3:
        return 'Filter';
      default:
        return 'Accessible Oman';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: fetchPlaces,
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                color: const Color(0xFF12372A),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.accessible_forward, size: 48, color: Colors.white),
                    SizedBox(height: 10),
                    Text('Accessible Oman Map', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                    Text('Inclusive navigation for everyone', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              _drawerItem(Icons.home, 'Home', 0),
              _drawerItem(Icons.map, 'Map', 1),
              _drawerItem(Icons.list_alt, 'Places', 2),
              _drawerItem(Icons.filter_list, 'Filter', 3),
              ListTile(
                leading: const Icon(Icons.add_location_alt),
                title: const Text('Add Place'),
                onTap: () {
                  Navigator.pop(context);
                  openAddPlace();
                },
              ),
              const Spacer(),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout'),
                onTap: logout,
              ),
            ],
          ),
        ),
      ),
      body: getBody(),
      floatingActionButton: currentIndex == 1 || currentIndex == 2
          ? FloatingActionButton.extended(
              onPressed: openAddPlace,
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Add'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => setState(() => currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Places'),
          NavigationDestination(icon: Icon(Icons.filter_list_outlined), selectedIcon: Icon(Icons.filter_list), label: 'Filter'),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, int index) {
    return ListTile(
      selected: currentIndex == index,
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        setState(() => currentIndex = index);
      },
    );
  }
}
