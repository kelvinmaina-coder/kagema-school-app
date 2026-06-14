import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';
import 'package:uuid/uuid.dart';

class TransportManagementScreen extends StatefulWidget {
  const TransportManagementScreen({super.key});

  @override
  State<TransportManagementScreen> createState() => _TransportManagementScreenState();
}

class _TransportManagementScreenState extends State<TransportManagementScreen> {
  List<Map<String, dynamic>> _routes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getBusRoutes();
      setState(() {
        _routes = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddRouteDialog({Map<String, dynamic>? route}) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final nameCtrl = TextEditingController(text: route?['name']);
    final driverCtrl = TextEditingController(text: route?['driver']);
    final phoneCtrl = TextEditingController(text: route?['phone']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(35))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('NEURAL ROUTE ASSIGNMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2)),
            const SizedBox(height: 24),
            _buildField(nameCtrl, 'Route Designation (e.g. Westlands)', Icons.map_rounded, theme),
            const SizedBox(height: 16),
            _buildField(driverCtrl, 'Assigned Driver', Icons.person_outline, theme),
            const SizedBox(height: 16),
            _buildField(phoneCtrl, 'Driver Contact', Icons.phone_android_rounded, theme, keyboardType: TextInputType.phone),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isNotEmpty) {
                    final data = {
                      'route_id': route?['route_id'] ?? const Uuid().v4(),
                      'name': nameCtrl.text.trim(),
                      'driver': driverCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                    };
                    await SupabaseService.instance.saveBusRoute(data);
                    if (mounted) { Navigator.pop(context); _loadRoutes(); }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                child: const Text('AUTHORIZE LOGISTICS SYNC', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController c, String l, IconData i, ThemeData t, {TextInputType? keyboardType}) => TextField(controller: c, keyboardType: keyboardType, decoration: InputDecoration(labelText: l, prefixIcon: Icon(i, color: t.primaryColor), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20))));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Fleet Intelligence', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, Colors.deepPurple.shade900], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 20)],
          ),
          child: Stack(children: [Positioned(right: -20, top: -10, child: Icon(Icons.bus_alert_rounded, size: 140, color: Colors.white.withOpacity(0.1)))]),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _routes.isEmpty 
            ? _buildEmptyState()
            : ListView.builder(
                padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20, left: 20, right: 20, bottom: 100),
                itemCount: _routes.length,
                itemBuilder: (context, index) {
                  final route = _routes[index];
                  final content = ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.directions_bus_rounded, color: Colors.deepPurple, size: 24)),
                    title: Text(route['name'] ?? 'Neural Route', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    subtitle: Text('Driver: ${route['driver']}\nContact: ${route['phone']}', style: const TextStyle(fontSize: 11, height: 1.4)),
                    trailing: IconButton(icon: const Icon(Icons.edit_location_alt_rounded), onPressed: () => _showAddRouteDialog(route: route)),
                  );
                  return Padding(padding: const EdgeInsets.only(bottom: 12), child: gemini?.buildGlowContainer(borderRadius: 24, borderThickness: 1, backgroundColor: theme.cardColor.withOpacity(0.85), padding: EdgeInsets.zero, child: content) ?? Card(child: content));
                },
              ),
      ),
      floatingActionButton: gemini?.buildGlowContainer(
        borderRadius: 30, borderThickness: 2, backgroundColor: theme.primaryColor, padding: EdgeInsets.zero,
        child: FloatingActionButton.extended(onPressed: () => _showAddRouteDialog(), backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white, icon: const Icon(Icons.add_location_alt_rounded), label: const Text('Add Quantum Route', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1))),
      ),
    );
  }

  Widget _buildEmptyState() => const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.bus_alert_rounded, size: 80, color: Colors.grey), SizedBox(height: 16), Text('FLEET OFFLINE', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5))]));
}
