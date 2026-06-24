import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';
import '../../app_settings.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _notices = [];
  bool _isLoading = true;
  String? _errorMessage;
  final String _roleId = 'parent';
  String _filter = 'all';
  late AnimationController _pulseController;

  // Responsive helpers
  double responsiveValue(double small, double medium, double large) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return small;
    if (width < 600) return medium;
    return large;
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _loadNotices();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadNotices() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await SupabaseService.instance.getNotifications(_roleId);
      if (mounted) {
        setState(() {
          _notices = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load announcements';
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredNotices() {
    if (_filter == 'all') return _notices;
    return _notices.where((n) {
      final priority = (n['priority'] ?? 'medium').toLowerCase();
      return priority == _filter;
    }).toList();
  }

  List<Map<String, dynamic>> _getPinnedNotices() {
    return _getFilteredNotices().where((n) => n['is_pinned'] == true).toList();
  }

  List<Map<String, dynamic>> _getUnpinnedNotices() {
    return _getFilteredNotices().where((n) => n['is_pinned'] != true).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dt = DT.of(context);
    final roleColor = RoleColors.of(_roleId);
    final compColor = RoleColors.complement(_roleId);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    final pinnedNotices = _getPinnedNotices();
    final unpinnedNotices = _getUnpinnedNotices();
    final filteredCount = _getFilteredNotices().length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: _buildAppBar(dt, isDark, roleColor, isSmallScreen),
      body: NeuralBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: compColor,
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: isDark,
          child: RefreshIndicator(
            onRefresh: _loadNotices,
            color: roleColor,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                      height: AppBar().preferredSize.height +
                          MediaQuery.of(context).padding.top +
                          responsiveValue(8, 12, 16)
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: responsiveValue(12, 16, 20)
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(dt, roleColor, isSmallScreen, _notices.length),
                        SizedBox(height: responsiveValue(12, 16, 20)),
                        _buildFilterChips(dt, roleColor, isSmallScreen),
                        SizedBox(height: responsiveValue(10, 14, 18)),
                        _buildStatsRow(dt, roleColor, isSmallScreen, _notices.length, filteredCount),
                        SizedBox(height: responsiveValue(12, 16, 20)),
                      ],
                    ),
                  ),
                ),
                if (_isLoading)
                  SliverFillRemaining(
                    child: _buildLoadingState(dt, roleColor, isSmallScreen),
                  )
                else if (_errorMessage != null)
                  SliverFillRemaining(
                    child: _buildErrorState(dt, roleColor, isSmallScreen),
                  )
                else if (_notices.isEmpty)
                    SliverFillRemaining(
                      child: _buildEmptyState(dt, roleColor, isSmallScreen),
                    )
                  else if (filteredCount == 0)
                      SliverFillRemaining(
                        child: _buildNoFilterResultState(dt, roleColor, isSmallScreen),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsiveValue(12, 16, 20),
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              final isPinnedSection = index == 0 && pinnedNotices.isNotEmpty;

                              if (isPinnedSection) {
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: responsiveValue(8, 10, 12),
                                    top: responsiveValue(4, 6, 8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.push_pin_rounded,
                                        size: isSmallScreen ? 14 : 16,
                                        color: roleColor,
                                      ),
                                      SizedBox(width: isSmallScreen ? 4 : 8),
                                      Text(
                                        'PINNED ANNOUNCEMENTS',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 10 : 12,
                                          fontWeight: FontWeight.w900,
                                          color: roleColor,
                                          letterSpacing: isSmallScreen ? 1 : 2,
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          margin: EdgeInsets.only(left: isSmallScreen ? 8 : 12),
                                          height: 1,
                                          color: roleColor.withValues(alpha: 0.2),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              if (index == (pinnedNotices.isNotEmpty ? pinnedNotices.length : 0) &&
                                  pinnedNotices.isNotEmpty &&
                                  unpinnedNotices.isNotEmpty) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: responsiveValue(12, 16, 20),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        'ALL ANNOUNCEMENTS',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 10 : 12,
                                          fontWeight: FontWeight.w900,
                                          color: dt.textMuted,
                                          letterSpacing: isSmallScreen ? 1 : 2,
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          margin: EdgeInsets.only(left: isSmallScreen ? 8 : 12),
                                          height: 1,
                                          color: dt.textMuted.withValues(alpha: 0.2),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final isPinned = index < pinnedNotices.length && pinnedNotices.isNotEmpty;
                              final noticeIndex = isPinned ? index : index - (pinnedNotices.isNotEmpty ? pinnedNotices.length + 1 : 0);
                              final notice = isPinned ? pinnedNotices[noticeIndex] : unpinnedNotices[noticeIndex];

                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: responsiveValue(10, 12, 16),
                                ),
                                child: _buildNoticeCard(
                                  dt,
                                  notice,
                                  roleColor,
                                  isSmallScreen,
                                  isPinned,
                                ),
                              );
                            },
                            childCount: pinnedNotices.length + unpinnedNotices.length +
                                (pinnedNotices.isNotEmpty ? 1 : 0) +
                                (pinnedNotices.isNotEmpty && unpinnedNotices.isNotEmpty ? 1 : 0),
                          ),
                        ),
                      ),
                SliverToBoxAdapter(
                  child: SizedBox(height: responsiveValue(60, 80, 100)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(DT dt, bool isDark, Color roleColor, bool isSmallScreen) {
    return AppBar(
      title: Text(
          isSmallScreen ? '📢 NEWS' : 'SCHOOL ANNOUNCEMENTS',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: isSmallScreen ? 1 : 3,
            fontSize: isSmallScreen ? 12 : 16,
            shadows: const [Shadow(color: Colors.black45, blurRadius: 10)],
          )
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.refresh_rounded,
            color: Colors.white,
            size: isSmallScreen ? 18 : 22,
          ),
          onPressed: _loadNotices,
        ),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: RoleColors.gradient(_roleId, dark: isDark),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
        ),
        child: Stack(
          children: [
            Positioned(
                right: -20,
                top: -10,
                child: Icon(
                    Icons.campaign_rounded,
                    size: isSmallScreen ? 80 : 140,
                    color: Colors.white.withValues(alpha: 0.1)
                )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(DT dt, Color roleColor, bool isSmallScreen, int totalCount) {
    return Container(
      padding: EdgeInsets.all(responsiveValue(14, 18, 24)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            roleColor.withValues(alpha: 0.08),
            roleColor.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(responsiveValue(20, 24, 28)),
        border: Border.all(
          color: roleColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 14),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.campaign_rounded,
              color: roleColor,
              size: isSmallScreen ? 24 : 32,
            ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${totalCount} Announcement${totalCount != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: isSmallScreen ? 16 : 20,
                    color: dt.textPrimary,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  'Stay informed with school updates',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 12,
                    color: dt.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_notices.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 6 : 10,
                vertical: isSmallScreen ? 3 : 5,
              ),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: roleColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                '${_getPinnedNotices().length} pinned',
                style: TextStyle(
                  fontSize: isSmallScreen ? 8 : 10,
                  fontWeight: FontWeight.w900,
                  color: roleColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(DT dt, Color roleColor, bool isSmallScreen) {
    final filters = [
      {'label': 'All', 'value': 'all'},
      {'label': '🔴 High', 'value': 'high'},
      {'label': '🟡 Medium', 'value': 'medium'},
      {'label': '🟢 Low', 'value': 'low'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _filter == filter['value'];
          return Padding(
            padding: EdgeInsets.only(right: isSmallScreen ? 6 : 10),
            child: FilterChip(
              label: Text(
                filter['label']!,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: isSmallScreen ? 10 : 12,
                  color: isSelected ? Colors.white : dt.textPrimary,
                ),
              ),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _filter = filter['value']!;
                });
              },
              backgroundColor: dt.cardBg.withValues(alpha: 0.6),
              selectedColor: roleColor,
              side: BorderSide(
                color: isSelected ? roleColor : dt.textMuted.withValues(alpha: 0.2),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 10 : 14,
                vertical: isSmallScreen ? 6 : 10,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsRow(DT dt, Color roleColor, bool isSmallScreen, int total, int filtered) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: dt.cardBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dt.textMuted.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            dt,
            Icons.announcement_rounded,
            '$total',
            'Total',
            roleColor,
            isSmallScreen,
          ),
          Container(
            width: 1,
            height: isSmallScreen ? 20 : 28,
            color: dt.textMuted.withValues(alpha: 0.1),
          ),
          _buildStatItem(
            dt,
            Icons.push_pin_rounded,
            '${_getPinnedNotices().length}',
            'Pinned',
            roleColor,
            isSmallScreen,
          ),
          Container(
            width: 1,
            height: isSmallScreen ? 20 : 28,
            color: dt.textMuted.withValues(alpha: 0.1),
          ),
          _buildStatItem(
            dt,
            Icons.filter_alt_rounded,
            '$filtered',
            'Showing',
            roleColor,
            isSmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(DT dt, IconData icon, String value, String label, Color color, bool isSmallScreen) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: isSmallScreen ? 12 : 14, color: color),
            SizedBox(width: isSmallScreen ? 4 : 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: isSmallScreen ? 14 : 16,
                color: dt.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 1 : 2),
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 8 : 10,
            color: dt.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNoticeCard(DT dt, Map<String, dynamic> notice, Color roleColor, bool isSmallScreen, bool isPinned) {
    final priority = (notice['priority'] ?? 'medium').toLowerCase();
    final priorityColor = priority == 'high'
        ? KagemaColors.parentRed
        : priority == 'medium'
        ? KagemaColors.accountantAmber
        : KagemaColors.teacherGreen;

    final priorityIcon = priority == 'high'
        ? Icons.priority_high_rounded
        : priority == 'medium'
        ? Icons.remove_rounded
        : Icons.circle_rounded;

    final createdAt = notice['created_at'] != null
        ? DateTime.parse(notice['created_at'].toString())
        : DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: dt.cardBg.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(responsiveValue(16, 20, 24)),
        border: Border.all(
          color: isPinned ? roleColor : dt.textMuted.withValues(alpha: 0.1),
          width: isPinned ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isPinned
                ? roleColor.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isPinned ? 16 : 8,
            offset: Offset(0, isPinned ? 6 : 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showNoticeDetail(dt, notice, roleColor, isSmallScreen),
          borderRadius: BorderRadius.circular(responsiveValue(16, 20, 24)),
          child: Container(
            padding: EdgeInsets.all(responsiveValue(14, 18, 24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isPinned) ...[
                      Icon(
                        Icons.push_pin_rounded,
                        size: isSmallScreen ? 14 : 16,
                        color: roleColor,
                      ),
                      SizedBox(width: isSmallScreen ? 4 : 8),
                    ],
                    Expanded(
                      child: Text(
                        notice['title'] ?? 'Notice',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: isSmallScreen ? 14 : 16,
                          color: dt.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 6 : 10,
                        vertical: isSmallScreen ? 2 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: priorityColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            priorityIcon,
                            size: isSmallScreen ? 10 : 12,
                            color: priorityColor,
                          ),
                          SizedBox(width: isSmallScreen ? 2 : 4),
                          Text(
                            priority.toUpperCase(),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 8 : 10,
                              fontWeight: FontWeight.w900,
                              color: priorityColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                Text(
                  notice['message'] ?? '',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: dt.textSecondary,
                    height: 1.5,
                  ),
                  maxLines: isSmallScreen ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isSmallScreen ? 10 : 14),
                Row(
                  children: [
                    CircleAvatar(
                      radius: isSmallScreen ? 12 : 14,
                      backgroundColor: roleColor.withValues(alpha: 0.12),
                      child: Text(
                        (notice['author'] ?? 'S')[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 10 : 12,
                          fontWeight: FontWeight.w900,
                          color: roleColor,
                        ),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notice['author'] ?? 'School Admin',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: isSmallScreen ? 10 : 12,
                              color: dt.textPrimary,
                            ),
                          ),
                          Text(
                            _timeAgo(createdAt),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 8 : 10,
                              color: dt.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showNoticeDetail(DT dt, Map<String, dynamic> notice, Color roleColor, bool isSmallScreen) {
    final priority = (notice['priority'] ?? 'medium').toLowerCase();
    final priorityColor = priority == 'high'
        ? KagemaColors.parentRed
        : priority == 'medium'
        ? KagemaColors.accountantAmber
        : KagemaColors.teacherGreen;

    final createdAt = notice['created_at'] != null
        ? DateTime.parse(notice['created_at'].toString())
        : DateTime.now();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: dt.pageBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
            border: Border.all(
              color: roleColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: dt.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 8 : 12,
                              vertical: isSmallScreen ? 3 : 5,
                            ),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: priorityColor.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  priority == 'high'
                                      ? Icons.priority_high_rounded
                                      : priority == 'medium'
                                      ? Icons.remove_rounded
                                      : Icons.circle_rounded,
                                  size: isSmallScreen ? 12 : 14,
                                  color: priorityColor,
                                ),
                                SizedBox(width: isSmallScreen ? 4 : 6),
                                Text(
                                  priority.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 10 : 12,
                                    fontWeight: FontWeight.w900,
                                    color: priorityColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (notice['is_pinned'] == true)
                            Row(
                              children: [
                                Icon(
                                  Icons.push_pin_rounded,
                                  size: isSmallScreen ? 16 : 18,
                                  color: roleColor,
                                ),
                                SizedBox(width: isSmallScreen ? 2 : 4),
                                Text(
                                  'PINNED',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 8 : 10,
                                    fontWeight: FontWeight.w900,
                                    color: roleColor,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      Text(
                        notice['title'] ?? 'Notice Details',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20 : 24,
                          fontWeight: FontWeight.w900,
                          color: dt.textPrimary,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: isSmallScreen ? 14 : 16,
                            backgroundColor: roleColor.withValues(alpha: 0.12),
                            child: Text(
                              (notice['author'] ?? 'S')[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                                fontWeight: FontWeight.w900,
                                color: roleColor,
                              ),
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 10 : 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notice['author'] ?? 'School Admin',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: isSmallScreen ? 12 : 14,
                                  color: dt.textPrimary,
                                ),
                              ),
                              Text(
                                _timeAgo(createdAt),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10 : 12,
                                  color: dt.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),
                      Container(
                        height: 1,
                        color: dt.textMuted.withValues(alpha: 0.1),
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),
                      Text(
                        notice['message'] ?? '',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          height: 1.8,
                          fontWeight: FontWeight.w500,
                          color: dt.textSecondary,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 30 : 40),
                      SizedBox(
                        width: double.infinity,
                        height: isSmallScreen ? 44 : 50,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            side: BorderSide(
                              color: roleColor.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            'DISMISS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: dt.textPrimary,
                              fontSize: isSmallScreen ? 12 : 14,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 20 : 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(DT dt, Color roleColor, bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: isSmallScreen ? 40 : 50,
            height: isSmallScreen ? 40 : 50,
            child: CircularProgressIndicator(
              color: roleColor,
              strokeWidth: isSmallScreen ? 3 : 4,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            'Loading announcements...',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              color: dt.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(DT dt, Color roleColor, bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              decoration: BoxDecoration(
                color: KagemaColors.parentRed.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: isSmallScreen ? 40 : 48,
                color: KagemaColors.parentRed,
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              'Failed to Load',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w900,
                color: dt.textPrimary,
              ),
            ),
            SizedBox(height: isSmallScreen ? 4 : 8),
            Text(
              _errorMessage ?? 'Something went wrong',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: dt.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            ElevatedButton.icon(
              onPressed: _loadNotices,
              icon: Icon(Icons.refresh_rounded, size: isSmallScreen ? 16 : 18),
              label: Text(
                'Try Again',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: roleColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : 24,
                  vertical: isSmallScreen ? 10 : 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(DT dt, Color roleColor, bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.campaign_outlined,
              size: isSmallScreen ? 60 : 80,
              color: dt.iconInactive,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            'No Announcements',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: isSmallScreen ? 16 : 20,
              color: dt.textPrimary,
            ),
          ),
          SizedBox(height: isSmallScreen ? 4 : 8),
          Text(
            'Check back later for updates',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              color: dt.textSecondary,
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          ElevatedButton.icon(
            onPressed: _loadNotices,
            icon: Icon(Icons.refresh_rounded, size: isSmallScreen ? 16 : 18),
            label: Text(
              'Refresh',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: roleColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 24,
                vertical: isSmallScreen ? 10 : 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFilterResultState(DT dt, Color roleColor, bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.filter_alt_off_rounded,
              size: isSmallScreen ? 40 : 50,
              color: dt.iconInactive,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            'No Matching Announcements',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: isSmallScreen ? 16 : 18,
              color: dt.textPrimary,
            ),
          ),
          SizedBox(height: isSmallScreen ? 4 : 8),
          Text(
            'Try changing the filter',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              color: dt.textSecondary,
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _filter = 'all';
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: roleColor,
              side: BorderSide(color: roleColor, width: 1.5),
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 24,
                vertical: isSmallScreen ? 10 : 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Show All',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.w900,
                color: roleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}