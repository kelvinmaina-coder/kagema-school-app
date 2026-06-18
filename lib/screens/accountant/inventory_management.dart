import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class InventoryManagement extends StatefulWidget {
  const InventoryManagement({super.key});

  @override
  State<InventoryManagement> createState() => _InventoryManagementState();
}

class _InventoryManagementState extends State<InventoryManagement> {
  List<Map<String, dynamic>> items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final list = await SupabaseService.instance.getInventory();
      if (mounted) {
        setState(() {
          items = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Inventory Sync Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showItemForm({Map<String, dynamic>? item}) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final nameCtrl = TextEditingController(text: item?['name']);
    final qtyCtrl = TextEditingController(text: item?['quantity']?.toString());
    final valCtrl = TextEditingController(text: item?['value']?.toString());
    String category = item?['category'] ?? 'Furniture';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: gemini?.buildCreativeBackground(
          isDark: theme.brightness == Brightness.dark,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 24),
                  Text(item == null ? 'NEW ASSET ENTRY' : 'EDIT ASSET DETAILS', 
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2)
                  ),
                  const SizedBox(height: 8),
                  Text(item == null ? 'Add Property' : 'Update Record', 
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)
                  ),
                  const SizedBox(height: 32),
                  _buildInputField('Asset Name', Icons.inventory_2_rounded, nameCtrl, theme),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: category,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    items: ['Furniture', 'Electronics', 'Books', 'Sports', 'Lab'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => category = v!,
                    decoration: _inputDecoration('Category', Icons.category_rounded, theme),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField('Quantity', Icons.numbers_rounded, qtyCtrl, theme, keyboardType: TextInputType.number),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInputField('Unit Price', Icons.payments_rounded, valCtrl, theme, keyboardType: TextInputType.number),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.isNotEmpty && qtyCtrl.text.isNotEmpty) {
                          final data = {
                            'item_id': item?['item_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                            'name': nameCtrl.text.trim(),
                            'category': category,
                            'quantity': int.tryParse(qtyCtrl.text) ?? 0,
                            'value': double.tryParse(valCtrl.text) ?? 0.0,
                          };
                          await SupabaseService.instance.insertInventory(data);
                          if (mounted) {
                            Navigator.pop(context);
                            _loadInventory();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor, 
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 8,
                      ),
                      child: Text(item == null ? 'SAVE ASSET' : 'UPDATE ASSET', 
                        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 13)
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ) ?? const SizedBox(),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, ThemeData theme) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      prefixIcon: Icon(icon, color: theme.primaryColor, size: 20),
      filled: true,
      fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
    );
  }

  Widget _buildInputField(String label, IconData icon, TextEditingController ctrl, ThemeData theme, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: _inputDecoration(label, icon, theme),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildHeroAppBar(theme, gemini),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(theme, gemini),
                    const SizedBox(height: 48),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text('SCHOOL ASSET REGISTRY', 
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2.5)
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInventoryList(theme, gemini),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: gemini?.buildGlowContainer(
        borderRadius: 30,
        borderThickness: 2,
        backgroundColor: theme.primaryColor,
        padding: EdgeInsets.zero,
        child: FloatingActionButton.extended(
          onPressed: () => _showItemForm(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_box_rounded),
          label: const Text('Add New Asset', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      ),
    );
  }

  Widget _buildHeroAppBar(ThemeData theme, GeminiThemeExtension? gemini) {
    return SliverAppBar(
      expandedHeight: 140.0,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text('ASSET MANAGEMENT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2, color: Colors.white)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.primaryColor, Colors.brown.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.inventory_rounded, size: 160, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, GeminiThemeExtension? gemini) {
    double totalValue = items.fold(0.0, (sum, item) => sum + ((item['value'] ?? 0.0) * (item['quantity'] ?? 0)));
    final content = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.analytics_rounded, color: theme.primaryColor, size: 30),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TOTAL ASSET VALUE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Text('Ksh ${NumberFormat("#,###").format(totalValue)}', 
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)
              ),
            ],
          ),
        ),
      ],
    );

    return gemini?.buildGlowContainer(
      borderRadius: 30,
      borderThickness: 2,
      backgroundColor: theme.cardColor.withOpacity(0.9),
      padding: const EdgeInsets.all(24),
      child: content,
    ) ?? Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(28)),
      child: content,
    );
  }

  Widget _buildInventoryList(ThemeData theme, GeminiThemeExtension? gemini) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Colors.brown));
    if (items.isEmpty) return _buildEmptyState();

    return Column(
      children: items.map((item) {
        final content = ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.category_rounded, color: theme.primaryColor, size: 24),
          ),
          title: Text(item['name'] ?? 'Unknown Item', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('${item['category']} • ${item['quantity']} units', 
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)
            ),
          ),
          trailing: Text('Ksh ${item['value']}', 
            style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.green, fontSize: 15)
          ),
          onTap: () => _showItemForm(item: item),
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: gemini?.buildGlowContainer(
            borderRadius: 28,
            borderThickness: 1,
            backgroundColor: theme.cardColor.withOpacity(0.85),
            padding: EdgeInsets.zero,
            child: content,
          ) ?? Card(child: content),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_clear_rounded, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('NO ASSETS FOUND', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
