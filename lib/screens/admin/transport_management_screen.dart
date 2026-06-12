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
    if (!mounted) return;
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
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showRouteDialog({Map<String, dynamic>? routeToEdit}) {
    final theme = Theme.of(context);
    final isEditing = routeToEdit != null;
    final nameCtrl = TextEditingController(text: routeToEdit?['name']);
    final driverCtrl = TextEditingController(text: routeToEdit?['driver_name']);
    final vehicleCtrl = TextEditingController(text: routeToEdit?['vehicle_number']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEditing ? 'Adjust Transport Route' : 'Deploy New Route', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.deepPurple.shade700)),
              const SizedBox(height: 8),
              Text(isEditing ? 'Modify fleet details for this route' : 'Add a new transport path to the cloud logistics', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 32),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Route Name (e.g. Route A)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.map_rounded))),
              const SizedBox(height: 16),
              TextField(controller: driverCtrl, decoration: const InputDecoration(labelText: 'Driver Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
              const SizedBox(height: 16),
              TextField(controller: vehicleCtrl, decoration: const InputDecoration(labelText: 'Vehicle Plate Number', border: OutlineInputBorder(), prefixIcon: Icon(Icons.directions_bus_filled_rounded))),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.isNotEmpty) {
                      final data = {
                        'name': nameCtrl.text.trim(),
                        'driver_name': driverCtrl.text.trim(),
                        'vehicle_number': vehicleCtrl.text.trim(),
                        'status': routeToEdit?['status'] ?? 'ACTIVE',
                      };
                      if (isEditing) {
                        data['route_id'] = routeToEdit['route_id'];
                      }
                      await SupabaseService.instance.saveBusRoute(data);
                      if (mounted) {
                        Navigator.pop(context);
                        _loadData();
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(isEditing ? 'UPDATE LOGISTICS' : 'INITIALIZE ROUTE', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteRoute(Map<String, dynamic> route) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decommission Route?'),
        content: Text('Are you sure you want to delete "${route['name']}"? All student links to this route will be broken.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await SupabaseService.instance.deleteBusRoute(route['route_id'].toString());
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Transport Fleet', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, Colors.deepPurple.shade900]),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _routes.length,
                      itemBuilder: (context, index) {
                        final route = _routes[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: Colors.deepPurple.withOpacity(0.1),
                              child: const Icon(Icons.directions_bus_filled_rounded, color: Colors.deepPurple),
                            ),
                            title: Text(route['name'] ?? 'Route', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Driver: ${route['driver_name'] ?? "Pending"} • ${route['vehicle_number'] ?? "No Van"}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                  child: Text(route['status'] ?? 'ACTIVE', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (val) {
                                    if (val == 'edit') _showRouteDialog(routeToEdit: route);
                                    if (val == 'delete') _deleteRoute(route);
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_note_rounded, size: 20), title: Text('Edit'), dense: true)),
                                    const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_forever_rounded, color: Colors.red, size: 20), title: Text('Delete'), dense: true)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRouteDialog(),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('Add Route', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bus_alert_rounded, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No transport data in cloud.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
}
