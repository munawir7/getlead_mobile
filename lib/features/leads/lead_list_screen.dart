
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../auth/login_screen.dart';
import 'create_lead_screen.dart';
import 'lead_detail_screen.dart';
import 'lead_list_controller.dart';
import 'lead_model.dart';

class LeadListScreen extends ConsumerStatefulWidget {
  const LeadListScreen({super.key});

  @override
  ConsumerState<LeadListScreen> createState() =>
      _LeadListScreenState();
}

class _LeadListScreenState extends ConsumerState<LeadListScreen> {
  final ScrollController _scrollController = ScrollController();

  static const Color backgroundColor = Color(0xFFFAF8F4);
  static const Color darkText = Color(0xFF181818);
  static const Color secondaryText = Color(0xFF77736E);
  static const Color mutedText = Color(0xFF8E8A85);
  static const Color redDotColor = Color(0xFFE52529);
  static const Color cardBackground = Color(0xFF181818);
  static const Color avatarBackground = Color(0xFFEFECE6);
  static const Color dividerColor = Color(0xFFEFECE6);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(leadListControllerProvider.notifier).loadMore();
    }
  }

  // --------------------------------------------------
  // ADD LEAD
  // --------------------------------------------------

  Future<void> _handleAddLead() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CreateLeadScreen(),
      ),
    );
  }

  // --------------------------------------------------
  // LOGOUT
  // --------------------------------------------------

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Log out',
          style: TextStyle(
            color: darkText,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(
            color: secondaryText,
            fontSize: 15,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: secondaryText,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: redDotColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Log out',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout != true) {
      return;
    }

    await ref.read(authControllerProvider.notifier).logout();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 10),
            Text(
              'Logged out successfully',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF181818),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatCount(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  Color _getStatusColor(LeadStatus? status) {
    if (status?.color != null && status!.color!.isNotEmpty) {
      try {
        final hex = status.color!.replaceAll('#', '');

        if (hex.length == 6) {
          return Color(int.parse('0xFF$hex'));
        }

        if (hex.length == 8) {
          return Color(int.parse('0x$hex'));
        }
      } catch (_) {}
    }

    final name = (status?.name ?? '').toLowerCase();

    if (name.contains('got business') ||
        name.contains('won') ||
        name.contains('converted') ||
        name.contains('closed')) {
      return const Color(0xFF15803D);
    }

    if (name.contains('attempted') ||
        name.contains('contact') ||
        name.contains('follow') ||
        name.contains('pending')) {
      return const Color(0xFFC25E00);
    }

    if (name.contains('not responding') ||
        name.contains('lost') ||
        name.contains('junk') ||
        name.contains('unqualified')) {
      return secondaryText;
    }

    return darkText;
  }

  @override
  Widget build(BuildContext context) {
    final leadsAsync = ref.watch(
      leadListControllerProvider,
    );

    final controller = ref.watch(
      leadListControllerProvider.notifier,
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // HEADER
            // --------------------------------------------------

            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                16,
                20,
                14,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Text(
                      'Leads',
                      style: TextStyle(
                        color: darkText,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),

                  // --------------------------------------------------
                  // ADD BUTTON
                  // --------------------------------------------------

                  GestureDetector(
                    onTap: _handleAddLead,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cardBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // --------------------------------------------------
                  // LOGOUT
                  // --------------------------------------------------

                  GestureDetector(
                    onTap: _handleLogout,
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      child: Text(
                        'Log out',
                        style: TextStyle(
                          color: Color(0xFF5A5752),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --------------------------------------------------
            // TOTAL LEADS CARD
            // --------------------------------------------------

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  22,
                  20,
                  22,
                  22,
                ),
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: redDotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'TOTAL LEADS',
                          style: TextStyle(
                            color: Color(0xFF888480),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      crossAxisAlignment:
                          CrossAxisAlignment.baseline,
                      textBaseline:
                          TextBaseline.alphabetic,
                      children: [
                        Text(
                          _formatCount(
                            controller.totalCount ??
                                leadsAsync.value?.length ??
                                0,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                          ),
                        ),
                        Text(
                          '${leadsAsync.value?.length ?? 0} loaded',
                          style: const TextStyle(
                            color: Color(0xFF8E8A85),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // --------------------------------------------------
            // LEADS LIST
            // --------------------------------------------------

            Expanded(
              child: leadsAsync.when(
                data: (leads) {
                  if (leads.isEmpty) {
                    return RefreshIndicator(
                      color: redDotColor,
                      backgroundColor: Colors.white,
                      onRefresh: () => ref
                          .read(
                            leadListControllerProvider
                                .notifier,
                          )
                          .refreshLeads(),
                      child: ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 100),
                          Center(
                            child: Text(
                              'No leads available.',
                              style: TextStyle(
                                fontSize: 16,
                                color: secondaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: redDotColor,
                    backgroundColor: Colors.white,
                    onRefresh: () => ref
                        .read(
                          leadListControllerProvider
                              .notifier,
                        )
                        .refreshLeads(),
                    child: ListView.separated(
                      controller: _scrollController,
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 8,
                        bottom: 24,
                      ),
                      itemCount: leads.length +
                          (controller.isLoadingMore
                              ? 1
                              : 0),
                      separatorBuilder:
                          (context, index) {
                        if (index >=
                                leads.length - 1 &&
                            controller.isLoadingMore) {
                          return const SizedBox.shrink();
                        }

                        return const Divider(
                          height: 1,
                          thickness: 1,
                          color: dividerColor,
                          indent: 60,
                        );
                      },
                      itemBuilder:
                          (context, index) {
                        if (index == leads.length) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 24,
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor:
                                        AlwaysStoppedAnimation<
                                            Color>(
                                      mutedText,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Loading more leads',
                                  style: TextStyle(
                                    color:
                                        secondaryText,
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final lead = leads[index];

                        final statusColor =
                            _getStatusColor(
                          lead.status,
                        );

                        final statusLabel =
                            lead.status?.name
                                        .isNotEmpty ==
                                    true
                                ? lead.status!.name
                                : 'Qualified';

                        final sourceLabel =
                            lead.source?.name
                                        .isNotEmpty ==
                                    true
                                ? lead.source!.name
                                : (lead.purposes
                                        .isNotEmpty
                                    ? lead.purposes.first
                                    : 'Website');

                        final timeLabel =
                            lead.timeAgo.isNotEmpty
                                ? lead.timeAgo
                                : (index < 5
                                    ? [
                                        '12m',
                                        '1h',
                                        '3h',
                                        '1d',
                                        '2d',
                                      ][index]
                                    : '');

                        return InkWell(
                          borderRadius:
                              BorderRadius.circular(12),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    LeadDetailScreen(
                                  leadId: lead.id,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.center,
                              children: [
                                // ------------------------------------------------
                                // AVATAR
                                // ------------------------------------------------

                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration:
                                      const BoxDecoration(
                                    color:
                                        avatarBackground,
                                    shape:
                                        BoxShape.circle,
                                  ),
                                  alignment:
                                      Alignment.center,
                                  child: Text(
                                    lead.initials,
                                    style:
                                        const TextStyle(
                                      color: darkText,
                                      fontSize: 14,
                                      fontWeight:
                                          FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  width: 14,
                                ),

                                // ------------------------------------------------
                                // NAME + SOURCE
                                // ------------------------------------------------

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lead.name,
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow
                                                .ellipsis,
                                        style:
                                            const TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                              FontWeight.w700,
                                          color: darkText,
                                          letterSpacing:
                                              -0.3,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 3,
                                      ),
                                      Text(
                                        sourceLabel,
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow
                                                .ellipsis,
                                        style:
                                            const TextStyle(
                                          fontSize: 14,
                                          fontWeight:
                                              FontWeight.w400,
                                          color:
                                              secondaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(
                                  width: 12,
                                ),

                                // ------------------------------------------------
                                // TIME + STATUS
                                // ------------------------------------------------

                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    if (timeLabel
                                        .isNotEmpty)
                                      Text(
                                        timeLabel,
                                        style:
                                            const TextStyle(
                                          fontSize: 13,
                                          fontWeight:
                                              FontWeight.w400,
                                          color:
                                              mutedText,
                                        ),
                                      ),
                                    const SizedBox(
                                      height: 4,
                                    ),
                                    Text(
                                      statusLabel,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight:
                                            FontWeight.w700,
                                        color:
                                            statusColor,
                                        letterSpacing:
                                            -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },

                // ------------------------------------------------
                // LOADING
                // ------------------------------------------------

                loading: () => const Center(
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(
                      redDotColor,
                    ),
                  ),
                ),

                // ------------------------------------------------
                // ERROR
                // ------------------------------------------------

                error: (error, stackTrace) =>
                    Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons
                              .error_outline_rounded,
                          size: 48,
                          color: redDotColor,
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        const Text(
                          'Failed to load leads',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                            color: darkText,
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Text(
                          error.toString(),
                          textAlign:
                              TextAlign.center,
                          style:
                              const TextStyle(
                            color: secondaryText,
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        ElevatedButton(
                          onPressed: () => ref
                              .read(
                                leadListControllerProvider
                                    .notifier,
                              )
                              .refreshLeads(),
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                cardBackground,
                            foregroundColor:
                                Colors.white,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                12,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Try Again',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
