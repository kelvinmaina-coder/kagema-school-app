import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../models/school_models.dart';
import '../../app_theme.dart';

class SecretaryReportsScreen extends StatefulWidget {
  const SecretaryReportsScreen({super.key});

  @override
  State<SecretaryReportsScreen> createState() => _SecretaryReportsScreenState();
}

class _SecretaryReportsScreenState extends State<SecretaryReportsScreen> {
  String _selectedReport = 'Student List';
  List<dynamic> _data = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    setState(() => _isLoading = true);
    try {
      if (_selectedReport == 'Student List') {
        final students = await SupabaseService.instance.getAllStudents();
        setState(() => _data = students);
      } else if (_selectedReport == 'Admission Report') {
        final res = await SupabaseService.instance.client
            .from('students')
            .select()
            .order('admission_date', ascending: false);
        setState(() => _data = res);
      } else if (_selectedReport == 'Parent Contacts') {
        final res = await SupabaseService.instance.getParents();
        setState(() => _data = res);
      } else if (_selectedReport == 'Attendance Summary') {
        final res = await SupabaseService.instance.getSchoolAttendanceSummary();
        setState(() => _data = res);
      }
    } catch (e) {
      debugPrint("Report Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Cloud Reports', style: TextStyle(fontWeight: FontWeight.bold)),
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
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 10),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.cardColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedReport,
                  items: ['Student List', 'Admission Report', 'Parent Contacts', 'Attendance Summary']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.bold))))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _selectedReport = v!);
                    _fetchReportData();
                  },
                  decoration: const InputDecoration(labelText: 'Select Report Type', border: InputBorder.none),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _data.isEmpty
                        ? const Center(child: Text('No cloud data found.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _data.length,
                            itemBuilder: (context, i) {
                              final item = _data[i];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: _buildListItem(item),
                              );
                            },
                          ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.cloud_download),
                    label: const Text('SYNC & EXPORT PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor, 
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(dynamic item) {
    if (_selectedReport == 'Student List') {
      final s = Student.fromMap(item);
      return ListTile(
        leading: const Icon(Icons.person, color: Colors.blue),
        title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('ADM: ${s.admissionNumber} | ${s.grade}'),
      );
    } else if (_selectedReport == 'Parent Contacts') {
      return ListTile(
        leading: const Icon(Icons.family_restroom, color: Colors.green),
        title: Text(item['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(item['phone'] ?? 'No Phone'),
        trailing: const Icon(Icons.phone, size: 18, color: Colors.green),
      );
    } else if (_selectedReport == 'Admission Report') {
      return ListTile(
        leading: const Icon(Icons.assignment_ind, color: Colors.orange),
        title: Text(item['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Date: ${item['admission_date'] ?? 'N/A'}'),
        trailing: Text(item['admission_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
      );
    } else {
      return ListTile(
        leading: const Icon(Icons.fact_check, color: Colors.purple),
        title: Text('Grade: ${item['grade']}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Status: ${item['status']}'),
      );
    }
  }
}
