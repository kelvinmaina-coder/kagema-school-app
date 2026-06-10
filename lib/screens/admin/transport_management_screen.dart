import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class TransportManagementScreen extends StatefulWidget {
  const TransportManagementScreen({super.key});

  @override
  State<TransportManagementScreen> createState() => _TransportManagementScreenState();
}

class _TransportManagementScreenState extends State<TransportManagementScreen> {
  List<Map<String, dynamic>> _routes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final routes = await SupabaseService.instance.getBusRoutes();
      if (mounted) {
        setState(() {
          _routes = routes;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading transport routes: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showRouteDialog({Map<String, dynamic>? route}) {
    final nameController = TextEditingController(text: route?['name']);
    final driverController = TextEditingController(text: route?['driver']);
    final capacityController = TextEditingController(text: route?['capacity']?.toString() ?? '40');
    final idController = TextEditingController(text: route?['route_id']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(route == null ? 'Create New Route' : 'Edit Route Details', 
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            if (route == null) TextField(controller: idController, decoration: const InputDecoration(labelText: 'Route ID (e.g. R-001)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Route Name (e.g. North Area)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: driverController, decoration: const InputDecoration(labelText: 'Driver Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: capacityController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Bus Capacity', border: OutlineInputBorder())),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty && (route != null || idController.text.isNotEmpty)) {
                    await SupabaseService.instance.saveBusRoute({
                      'route_id': route != null ? route['route_id'] : idController.text.trim(),
                      'name': nameController.text.trim(),
                      'driver': driverController.text.trim(),
                      'capacity': int.tryParse(capacityController.text) ?? 40,
                    });
                    if (mounted) {
                      Navigator.pop(context);
                      _loadData();
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor, 
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('SYNC TO CLOUD', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Transport Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)]),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : _routes.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _routes.length,
                      itemBuilder: (context, index) {
                        final route = _routes[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          color: theme.cardColor.withOpacity(0.9),
                          child: ExpansionTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.directions_bus_rounded, color: Colors.blue),
                            ),
                            title: Text(route['name'] ?? 'Route', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Driver: ${route['driver'] ?? 'N/A'} • ${route['students'] ?? 0} Students'),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _infoRow(Icons.person, 'Operator', route['driver'] ?? 'Unassigned'),
                                    const SizedBox(height: 10),
                                    _infoRow(Icons.map, 'Route Code', route['route_id'] ?? 'N/A'),
                                    const SizedBox(height: 10),
                                    _infoRow(Icons.group, 'Capacity', '${route['students'] ?? 0} / ${route['capacity'] ?? 0}'),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => _showRouteDialog(route: route), 
                                          icon: const Icon(Icons.edit), 
                                          label: const Text('Edit')
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          onPressed: () async {
                                            await SupabaseService.instance.deleteBusRoute(route['route_id']);
                                            _loadData();
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          onPressed: () {}, 
                                          icon: const Icon(Icons.list), 
                                          label: const Text('Passengers'),
                                          style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRouteDialog(),
        label: const Text('New Route'),
        icon: const Icon(Icons.add_location_alt_rounded),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blueGrey),
        const SizedBox(width: 10),
        Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bus_alert_rounded, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No transport routes configured.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
