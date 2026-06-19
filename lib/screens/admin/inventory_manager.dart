import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class InventoryManagerScreen extends StatefulWidget {
  const InventoryManagerScreen({super.key});

  @override
  State<InventoryManagerScreen> createState() => _InventoryManagerScreenState();
}

class _InventoryManagerScreenState extends State<InventoryManagerScreen> {
  List<Map<String, dynamic>> _inventory = [];
  bool _isLoading = true;
  final String _roleId = 'admin';

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getInventory();
      if (mounted) {
        setState(() {
          _inventory = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _syncStock(String itemId, int currentQty, int change) async {
    final newQty = currentQty + change;
    if (newQty < 0) return;

    try {
      await SupabaseService.instance.updateStock(itemId, newQty);
      _fetchInventory();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: $e', style: const TextStyle(fontWeight: FontWeight.w700)),
          backgroundColor: KagemaColors.parentRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final dt = DT.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dt.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Remove from Stores?', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textPrimary)),
        content: Text('Are you sure you want to delete "${item['name']}"? This cannot be undone.', style: TextStyle(color: dt.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('CANCEL', style: TextStyle(color: dt.textMuted))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: KagemaColors.parentRed, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.instance.deleteInventoryItem(item['item_id'].toString());
        _fetchInventory();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: KagemaColors.parentRed));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dt = DT.of(context);
    final roleColor = RoleColors.of(_roleId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: AppBar(
        title: const Text('SCHOOL INVENTORY', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: RoleColors.gradient(_roleId, dark: isDark),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.inventory_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)),
              ),
            ],
          ),
        ),
      ),
      body: NeuralBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: RoleColors.complement(_roleId),
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: isDark,
          child: Padding(
            padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 10),
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: roleColor))
              : _inventory.isEmpty
                ? _buildEmptyState(dt)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _inventory.length,
                    itemBuilder: (context, index) {
                      final item = _inventory[index];
                      final qty = item['quantity'] ?? 0;
                      final isLow = qty <= 5;
                      final itemColor = isLow ? KagemaColors.parentRed : roleColor;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: LiquidGlassCard(
                          accentColor: itemColor,
                          borderRadius: 24,
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: dt.roleSoftBg(itemColor),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isLow ? Icons.warning_amber_rounded : Icons.inventory_2, 
                                color: itemColor,
                                size: 24,
                              ),
                            ),
                            title: Text(item['name'] ?? 'Unknown Item', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: dt.textPrimary)),
                            subtitle: Text('Category: ${item['category'] ?? 'General'}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dt.textMuted)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: dt.surfaceBg,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(color: dt.cardBorder),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.remove_circle_outline, size: 20, color: dt.iconInactive), 
                                        onPressed: () => _syncStock(item['item_id'], qty, -1)
                                      ),
                                      Text('$qty', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isLow ? KagemaColors.parentRed : dt.textPrimary)),
                                      IconButton(
                                        icon: Icon(Icons.add_circle_outline, size: 20, color: roleColor), 
                                        onPressed: () => _syncStock(item['item_id'], qty, 1)
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert, color: dt.iconInactive),
                                  color: dt.cardBg,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  onSelected: (val) {
                                    if (val == 'edit') _showAddItemDialog(dt, itemToEdit: item);
                                    if (val == 'delete') _deleteItem(item);
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_note_rounded, size: 20, color: dt.textPrimary), title: Text('Edit Info', style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary)), dense: true)),
                                    const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_forever, color: KagemaColors.parentRed, size: 20), title: Text('Delete', style: TextStyle(color: KagemaColors.parentRed, fontWeight: FontWeight.bold)), dense: true)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
      floatingActionButton: RolePlasma(
        color: roleColor,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddItemDialog(dt),
          backgroundColor: roleColor,
          elevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_box_rounded),
          label: const Text('ADD NEW STOCK', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
        ),
      ),
    );
  }

  void _showAddItemDialog(DT dt, {Map<String, dynamic>? itemToEdit}) {
    final isEditing = itemToEdit != null;
    final nameCtrl = TextEditingController(text: itemToEdit?['name']);
    final catCtrl = TextEditingController(text: itemToEdit?['category']);
    final qtyCtrl = TextEditingController(text: itemToEdit?['quantity']?.toString() ?? '0');
    final roleColor = RoleColors.of(_roleId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: LiquidGlassCard(
          borderRadius: 35,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: dt.divider, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text(isEditing ? 'EDIT STOCK' : 'ADD NEW STOCK', 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)
                ),
                const SizedBox(height: 8),
                Text(isEditing ? 'Sync Item Details' : 'Stock Registration', 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1, color: dt.textPrimary)
                ),
                const SizedBox(height: 32),
                _buildInputField(dt, nameCtrl, 'Item Name', Icons.inventory_2_outlined),
                const SizedBox(height: 16),
                _buildInputField(dt, catCtrl, 'Category', Icons.category_outlined),
                const SizedBox(height: 16),
                _buildInputField(dt, qtyCtrl, 'Quantity', Icons.numbers_rounded, keyboardType: TextInputType.number),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.isNotEmpty) {
                        final data = {
                          'name': nameCtrl.text.trim(),
                          'category': catCtrl.text.trim(),
                          'quantity': int.tryParse(qtyCtrl.text) ?? 0,
                        };
                        if (isEditing) {
                          data['item_id'] = itemToEdit['item_id'];
                        }
                        await SupabaseService.instance.insertInventory(data);
                        if (mounted) {
                          Navigator.pop(context);
                          _fetchInventory();
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: roleColor, 
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isEditing ? 'COMMIT SYNC' : 'SAVE TO INVENTORY', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(DT dt, TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: RoleColors.of(_roleId), size: 20),
      ),
    );
  }

  Widget _buildEmptyState(DT dt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: dt.iconInactive),
          const SizedBox(height: 16),
          Text('INVENTORY IS EMPTY', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
        ],
      ),
    );
  }
}
