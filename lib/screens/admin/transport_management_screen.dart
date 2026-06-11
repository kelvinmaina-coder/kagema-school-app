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
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: Text(route['status'] ?? 'ACTIVE', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
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
