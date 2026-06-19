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
  final String _roleId = 'admin';

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getBusRoutes();
      if (mounted) {
        setState(() {
          _routes = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddRouteDialog(DT dt, GeminiThemeExtension? theme, Color roleColor, {Map<String, dynamic>? route}) {
    final nameCtrl = TextEditingController(text: route?['name']);
    final driverCtrl = TextEditingController(text: route?['driver']);
    final phoneCtrl = TextEditingController(text: route?['phone']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: theme?.buildGlowContainer(
          accentColor: roleColor,
          borderRadius: 35,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: dt.divider, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text('ROUTE ASSIGNMENT CENTER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
                const SizedBox(height: 24),
                _buildField(dt, nameCtrl, 'Route Name (e.g. Westlands)', Icons.map_rounded, roleColor),
                const SizedBox(height: 16),
                _buildField(dt, driverCtrl, 'Assigned Driver', Icons.person_outline, roleColor),
                const SizedBox(height: 16),
                _buildField(dt, phoneCtrl, 'Driver Contact', Icons.phone_android_rounded, roleColor, keyboardType: TextInputType.phone),
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
                    child: const Text('COMMIT LOGISTICS DATA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ) ?? const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildField(DT dt, TextEditingController c, String l, IconData i, Color color, {TextInputType? keyboardType}) => TextField(controller: c, keyboardType: keyboardType, style: TextStyle(color: dt.textPrimary, fontWeight: FontWeight.bold), decoration: InputDecoration(labelText: l, prefixIcon: Icon(i, color: color)));

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final isDark = context.isDark;
    final roleColor = RoleColors.of(_roleId);
    final compColor = RoleColors.complement(_roleId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: AppBar(
        title: const Text('FLEET MANAGEMENT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 3, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: RoleColors.gradient(_roleId, dark: isDark),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(children: [Positioned(right: -20, top: -10, child: Icon(Icons.bus_alert_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)))]),
        ),
      ),
      body: theme?.buildCreativeBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: compColor,
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: isDark,
          child: _isLoading 
            ? Center(child: CircularProgressIndicator(color: roleColor))
            : _routes.isEmpty 
              ? _buildEmptyState(dt)
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(top: AppBar().preferredSize.height + context.pt + 20, left: 20, right: 20, bottom: 100),
                  itemCount: _routes.length,
                  itemBuilder: (context, index) {
                    final route = _routes[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12), 
                      child: theme.buildGlowContainer(
                        accentColor: KagemaColors.secretaryViolet, 
                        borderRadius: 24, 
                        padding: EdgeInsets.zero, 
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: dt.roleSoftBg(KagemaColors.secretaryViolet), shape: BoxShape.circle), child: const Icon(Icons.directions_bus_rounded, color: KagemaColors.secretaryViolet, size: 24)),
                          title: Text(route['name']?.toString().toUpperCase() ?? 'SCHOOL ROUTE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: dt.textPrimary, letterSpacing: 0.5)),
                          subtitle: Text('Driver: ${route['driver']}\nContact: ${route['phone']}', style: TextStyle(fontSize: 11, height: 1.4, color: dt.textSecondary, fontWeight: FontWeight.w600)),
                          trailing: IconButton(icon: Icon(Icons.edit_location_alt_rounded, color: roleColor), onPressed: () => _showAddRouteDialog(dt, theme, roleColor, route: route)),
                        ),
                      ) ?? const SizedBox.shrink(),
                    );
                  },
                ),
        ),
      ) ?? const SizedBox.shrink(),
      floatingActionButton: RolePlasma(
        color: roleColor,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddRouteDialog(dt, theme, roleColor),
          icon: const Icon(Icons.add_location_alt_rounded), 
          label: const Text('ADD SCHOOL ROUTE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11))
        ),
      ),
    );
  }

  Widget _buildEmptyState(DT dt) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.bus_alert_rounded, size: 80, color: dt.iconInactive), const SizedBox(height: 16), Text('FLEET OFFLINE', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2))]));
}
