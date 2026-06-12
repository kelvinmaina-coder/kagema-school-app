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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cloud sync failed: $e')));
    }
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Stores?'),
        content: Text('Are you sure you want to delete "${item['name']}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: Colors.red))),
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
        title: const Text('Inventory & Stores', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.brown.shade800, Colors.brown.shade400]),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _inventory.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _inventory.length,
                  itemBuilder: (context, index) {
                    final item = _inventory[index];
                    final qty = item['quantity'] ?? 0;
                    final isLow = qty <= 5;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: ListTile(
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
                        title: Text(item['name'] ?? 'Unknown Item', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Category: ${item['category'] ?? 'General'}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
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
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Colors.grey),
                              onSelected: (val) {
                                if (val == 'edit') _showAddItemDialog(itemToEdit: item);
                                if (val == 'delete') _deleteItem(item);
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_note_rounded, size: 20), title: Text('Edit Info'), dense: true)),
                                const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_forever, color: Colors.red, size: 20), title: Text('Delete'), dense: true)),
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
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEditing ? 'Update Stock Item' : 'Add New Stock', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.brown)),
            const SizedBox(height: 24),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Item Name', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Current Quantity', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
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
                    await SupabaseService.instance.insertInventory(data); // insertInventory uses upsert
                    if (mounted) {
                      Navigator.pop(context);
                      _fetchInventory();
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
                child: Text(isEditing ? 'UPDATE CLOUD STORE' : 'SYNC TO WAREHOUSE', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
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
          Text('Inventory is empty.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
}
