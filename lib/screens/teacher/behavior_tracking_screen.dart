import 'package:flutter/material.dart';
import '../../app_theme.dart';

class BehaviorTrackingScreen extends StatefulWidget {
  const BehaviorTrackingScreen({super.key});

  @override
  State<BehaviorTrackingScreen> createState() => _BehaviorTrackingScreenState();
}

class _BehaviorTrackingScreenState extends State<BehaviorTrackingScreen> {
  final List<Map<String, dynamic>> _behaviorLogs = [
    {'name': 'John Doe', 'action': 'Excellence in Math', 'type': 'Positive', 'date': '2023-11-05', 'points': '+10'},
    {'name': 'Mary Wambui', 'action': 'Late to class', 'type': 'Negative', 'date': '2023-11-04', 'points': '-5'},
    {'name': 'Peter Kamau', 'action': 'Helping a peer', 'type': 'Positive', 'date': '2023-11-03', 'points': '+5'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Behavior & Discipline', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _behaviorLogs.length,
          itemBuilder: (context, index) {
            final log = _behaviorLogs[index];
            final bool isPos = log['type'] == 'Positive';
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isPos ? Colors.amber.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  child: Icon(isPos ? Icons.star_rounded : Icons.warning_rounded, 
                      color: isPos ? Colors.amber : Colors.red),
                ),
                title: Text(log['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(log['action']),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(log['points'], style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      color: isPos ? Colors.green : Colors.red,
                      fontSize: 14
                    )),
                    Text(log['date'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEntryDialog(),
        label: const Text('Log Behavior'),
        icon: const Icon(Icons.add_comment_rounded),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showAddEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Behavior Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(decoration: InputDecoration(labelText: 'Student Name')),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Behavior Observed')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              items: const [
                DropdownMenuItem(value: 'Positive', child: Text('Positive')),
                DropdownMenuItem(value: 'Negative', child: Text('Negative')),
              ],
              onChanged: (v) {},
              decoration: const InputDecoration(labelText: 'Type'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('LOG ENTRY')),
        ],
      ),
    );
  }
}
