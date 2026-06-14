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

  Future<void> _updateStock(String itemId, int currentQty, int change) async {
    final newQty = currentQty + change;
    if (newQty < 0) return;

    try {
      await SupabaseService.instance.updateStock(itemId, newQty);
      _fetchInventory();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Remove from Stores?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Are you sure you want to delete "${item['name']}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.instance.deleteInventoryItem(item['item_id'].toString());
        _fetchInventory();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('School Inventory', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.brown.shade900, Colors.brown.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.inventory_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.brown))
            : _inventory.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  itemCount: _inventory.length,
                  itemBuilder: (context, index) {
                    final item = _inventory[index];
                    final qty = item['quantity'] ?? 0;
                    final isLow = qty <= 5;

                    final content = ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (isLow ? Colors.red : Colors.brown).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isLow ? Icons.warning_amber_rounded : Icons.inventory_2, 
                          color: isLow ? Colors.red : Colors.brown,
                          size: 24,
                        ),
                      ),
                      title: Text(item['name'] ?? 'Unknown Item', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                      subtitle: Text('Category: ${item['category'] ?? 'General'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.grey), 
                                  onPressed: () => _updateStock(item['item_id'], qty, -1)
                                ),
                                Text('$qty', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isLow ? Colors.red : null)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.brown), 
                                  onPressed: () => _updateStock(item['item_id'], qty, 1)
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.grey),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            onSelected: (val) {
                              if (val == 'edit') _showAddItemDialog(itemToEdit: item);
                              if (val == 'delete') _deleteItem(item);
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_note_rounded, size: 20), title: Text('Edit Info', style: TextStyle(fontWeight: FontWeight.bold)), dense: true)),
                              const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_forever, color: Colors.red, size: 20), title: Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), dense: true)),
                            ],
                          ),
                        ],
                      ),
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: gemini?.buildGlowContainer(
                        borderRadius: 24,
                        borderThickness: 1,
                        backgroundColor: theme.cardColor.withOpacity(0.85),
                        padding: EdgeInsets.zero,
                        child: content,
                      ) ?? Card(child: content),
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: gemini?.buildGlowContainer(
        borderRadius: 30,
        borderThickness: 2,
        backgroundColor: Colors.brown,
        padding: EdgeInsets.zero,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddItemDialog(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_box_rounded),
          label: const Text('Add New Stock', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      ) ?? FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_box_rounded),
        label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showAddItemDialog({Map<String, dynamic>? itemToEdit}) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final isEditing = itemToEdit != null;
    final nameCtrl = TextEditingController(text: itemToEdit?['name']);
    final catCtrl = TextEditingController(text: itemToEdit?['category']);
    final qtyCtrl = TextEditingController(text: itemToEdit?['quantity']?.toString() ?? '0');

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
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text(isEditing ? 'EDIT STOCK' : 'ADD NEW STOCK', 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2)
                ),
                const SizedBox(height: 8),
                Text(isEditing ? 'Update Item Details' : 'Stock Registration', 
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)
                ),
                const SizedBox(height: 32),
                _buildInputField(nameCtrl, 'Item Name', Icons.inventory_2_outlined),
                const SizedBox(height: 16),
                _buildInputField(catCtrl, 'Category', Icons.category_outlined),
                const SizedBox(height: 16),
                _buildInputField(qtyCtrl, 'Quantity', Icons.numbers_rounded, keyboardType: TextInputType.number),
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
                      backgroundColor: Colors.brown.shade700, 
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                    ),
                    child: Text(isEditing ? 'UPDATE RECORDS' : 'SAVE TO INVENTORY', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ) ?? const SizedBox(),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.brown, size: 20),
        filled: true,
        fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('INVENTORY IS EMPTY', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
        ],
      ),
    );
  }
}
