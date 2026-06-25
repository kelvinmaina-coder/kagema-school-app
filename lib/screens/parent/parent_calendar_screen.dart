import 'package:flutter/material.dart';
import 'dart:ui';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class ParentCalendarScreen extends StatefulWidget {
  const ParentCalendarScreen({super.key});

  @override
  State<ParentCalendarScreen> createState() => _ParentCalendarScreenState();
}

class _ParentCalendarScreenState extends State<ParentCalendarScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;

  // Role Theme Color - Dynamic Parent Accent (Orange/Coral)
  final Color primaryAccent = const Color(0xFFF97316); 
  final Color slateDeep = const Color(0xFF334155); // Slate-700 equivalent for high contrast

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _loadEvents();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final events = await SupabaseService.instance.getEvents();
      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Calendar Load Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // INTELLIGENT RESPONSIVENESS: Adapts layout for Phone, Tablet, and Desktop
    double maxWidth = screenWidth > 1200 ? 1100 : (screenWidth > 800 ? 800 : screenWidth);
    int crossAxisCount = screenWidth > 900 ? 2 : 1;
    double horizontalPadding = screenWidth > 600 ? 40 : 24;

    return Scaffold(
      body: gemini?.buildCreativeBackground(
        isDark: isDark,
        maxWidth: maxWidth,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildElegantHeader(theme, gemini),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 32, horizontalPadding, 120),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('UPCOMING HUB EVENTS'),
                    const SizedBox(height: 32),
                    if (_isLoading)
                      Center(child: Padding(padding: const EdgeInsets.all(100), child: CircularProgressIndicator(color: primaryAccent, strokeWidth: 3)))
                    else if (_events.isEmpty)
                      _buildEmptyState(isDark)
                    else
                      _buildResponsiveGrid(crossAxisCount, isDark, gemini),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElegantHeader(ThemeData theme, GeminiThemeExtension? gemini) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white.withOpacity(0.2),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text('SCHOOL HUB CALENDAR', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 4, color: Colors.white)
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(decoration: BoxDecoration(gradient: gemini?.primaryGradient)),
            Positioned(
              right: -30, top: -10,
              child: Icon(Icons.event_note_rounded, size: 220, color: Colors.white.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveGrid(int columns, bool isDark, GeminiThemeExtension? gemini) {
    if (columns == 1) {
      return Column(
        children: _events.map((e) => _buildEventCard(e, isDark, gemini, isGrid: false)).toList(),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        mainAxisExtent: 115,
      ),
      itemCount: _events.length,
      itemBuilder: (context, index) => _buildEventCard(_events[index], isDark, gemini, isGrid: true),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> e, bool isDark, GeminiThemeExtension? gemini, {required bool isGrid}) {
    final color = _getEventColor(e['type']);
    
    return Container(
      margin: isGrid ? EdgeInsets.zero : const EdgeInsets.only(bottom: 16),
      child: gemini?.buildGlowContainer(
        borderRadius: 28,
        borderThickness: 1.5,
        padding: EdgeInsets.zero,
        backgroundColor: isDark ? const Color(0xF21A1C22) : Colors.white,
        child: InkWell(
          onTap: () => _showEventDetails(e),
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // FEATURE 1: GROWING GRADIENT BORDER FOR ICONS
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 58, height: 58,
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFA855F7), Color(0xFF6366F1), Color(0xFF3B82F6)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3 * _pulseController.value),
                            blurRadius: 12 * _pulseController.value,
                            spreadRadius: 2 * _pulseController.value,
                          )
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.calendar_today_rounded, color: color, size: 24),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e['title']?.toString().toUpperCase() ?? 'EVENT', 
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: isDark ? Colors.white : slateDeep)
                      ),
                      const SizedBox(height: 6),
                      Text(e['start_date'] ?? e['date'] ?? '', 
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : const Color(0xFF64748B))
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.blueGrey, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 12, height: 2, decoration: BoxDecoration(color: primaryAccent, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 3, color: slateDeep)), 
        const SizedBox(width: 12),
        Container(width: 12, height: 2, decoration: BoxDecoration(color: primaryAccent, borderRadius: BorderRadius.circular(2))),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.event_busy_rounded, size: 80, color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
          const SizedBox(height: 24),
          const Text('NO SCHEDULED EVENTS', 
            style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF475569), letterSpacing: 2, fontSize: 12)
          ),
        ],
      ),
    );
  }

  void _showEventDetails(Map<String, dynamic> e) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _getEventColor(e['type']);
    final screenWidth = MediaQuery.of(context).size.width;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: screenWidth > 800 ? 600 : screenWidth),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(45)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 40, spreadRadius: 10)],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.blueGrey.withOpacity(0.2), borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
                    child: Text(e['type']?.toString().toUpperCase() ?? 'GENERAL', 
                      style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2)
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(e['title'] ?? 'Event Details', 
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: isDark ? Colors.white : slateDeep, letterSpacing: -1)
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.calendar_month_rounded, color: color, size: 24)),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2)),
                          Text(e['start_date'] ?? e['date'] ?? 'N/A', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : slateDeep)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 40),
                  const Text('EVENT DESCRIPTION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2, color: Colors.blueGrey)),
                  const SizedBox(height: 16),
                  Text(e['description'] ?? 'No additional information available for this school event.',
                    style: TextStyle(fontSize: 17, height: 1.7, color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w500)
                  ),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: double.infinity,
                    height: 70,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAccent,
                        elevation: 10,
                        shadowColor: primaryAccent.withOpacity(0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Text('BACK TO HUB', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getEventColor(String? type) {
    switch (type) {
      case 'Exam': return const Color(0xFFEF4444);
      case 'Holiday': return const Color(0xFF10B981);
      case 'Meeting': return const Color(0xFFF59E0B);
      case 'Sports': return const Color(0xFF3B82F6);
      default: return const Color(0xFF8B5CF6);
    }
  }
}
