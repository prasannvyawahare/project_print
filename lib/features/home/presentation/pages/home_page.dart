import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/storage/active_job_store.dart';
import '../../../../core/storage/temporary_auth_store.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/printhub_app_bar.dart';
import '../../../upload/data/datasources/order_remote_data_source.dart';
import '../../../upload/data/models/order_history_model.dart';
import '../../domain/entities/print_category_entity.dart';
import '../../../delivery/presentation/pages/order_review_page.dart'
    show OrderReviewPage;
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_event.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../upload/presentation/pages/order_history_page.dart'
    show OrderHistoryPage;
import '../../../upload/presentation/pages/order_summary_page.dart'
    show OrderSummaryPage;
import '../../../upload/presentation/pages/upload_documents_page.dart'
    show UploadDocumentsPage;
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';

double _screenScale(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final widthScale = (size.width / 390).clamp(0.82, 1.0);
  final heightScale = (size.height / 844).clamp(0.82, 1.0);
  return (widthScale * 0.7 + heightScale * 0.3).toDouble();
}

double _r(BuildContext context, double value) => value * _screenScale(context);

// ── Shared palette ─────────────────────────────────────────────────────────
// Sourced from AppColors (lib/core/constants/app_constants.dart) so the
// dashboard's palette is a named part of the app-wide theme, not a
// file-local duplicate.
const _accent = AppColors.dashboardAccent;
const _pageBackground = AppColors.dashboardBackground;
const _primaryText = AppColors.dashboardPrimaryText;
const _mutedText = AppColors.dashboardMutedText;
const _success = AppColors.success;

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomeView();
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  String _greetingName() {
    final displayName = sl<TemporaryAuthStore>().displayName.trim();
    if (displayName.isEmpty) {
      return 'Alex';
    }

    return displayName.split(RegExp(r'\s+')).first;
  }

  List<ActiveJob> _activeJobs = const <ActiveJob>[];

  void _loadActiveJobs() {
    setState(() => _activeJobs = sl<ActiveJobStore>().getJobs());
  }

  List<OrderHistoryEntry> _recentOrders = const <OrderHistoryEntry>[];
  bool _recentOrdersLoading = true;

  /// Fetches `GET order/history` and keeps just the most recent few for the
  /// dashboard preview — the full list lives on the Orders tab.
  Future<void> _loadRecentOrders() async {
    setState(() => _recentOrdersLoading = true);
    try {
      final history = await sl<OrderRemoteDataSource>().getOrderHistory();
      if (!mounted) return;
      setState(() {
        _recentOrders = history.orders.take(3).toList(growable: false);
        _recentOrdersLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _recentOrdersLoading = false);
    }
  }

  Future<void> _openUploadDocuments([PrintCategoryEntity? category]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UploadDocumentsPage(
          categoryName: category?.printType,
          categoryRate: category?.rate,
          printConfigId: category?.id,
          paperQualities: category?.paperQualities,
          paperSizes: category?.sizes,
        ),
      ),
    );
    if (!mounted) return;
    _loadActiveJobs();
  }

  Future<void> _openActiveJob(ActiveJob job) async {
    // Resume the job at the step it was left on.
    final Widget destination = job.step == ActiveJobStep.checkout
        ? OrderSummaryPage(orderId: job.orderId, deliveryAddress: job.address)
        : OrderReviewPage(orderId: job.orderId);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => destination),
    );
    if (!mounted) return;
    _loadActiveJobs();
  }

  Future<void> _removeActiveJob(ActiveJob job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel order?'),
        content: Text(
          'This removes "${job.title}" from your active jobs and cancels it. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFD93025)),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await sl<OrderRemoteDataSource>().cancelOrder(orderId: job.orderId);
      await sl<ActiveJobStore>().remove(job.orderId);
      if (!mounted) return;
      _loadActiveJobs();
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Order cancelled.')));
    } on OrderCreateException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Failed to cancel the order.')),
        );
    }
  }

  Future<void> _openOrders() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const OrderHistoryPage()),
    );
    if (!mounted) return;
    _loadRecentOrders();
  }

  Future<void> _openProfile() async {
    // ProfileBloc is a DI singleton already fetching/fetched from the
    // dashboard's initState below, so reuse it instead of creating a new
    // bloc that would re-fetch and flash a loading spinner.
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<ProfileBloc>.value(
          value: sl<ProfileBloc>(),
          child: const ProfilePage(),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _activeJobs = sl<ActiveJobStore>().getJobs();
    _loadRecentOrders();
    // Kick off the profile fetch as soon as the dashboard loads so it's
    // already available by the time the user taps the Profile tab.
    sl<ProfileBloc>().add(const ProfileRequested());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HomeBloc>().add(const HomeRequested());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            final greetingSubtitle = switch (state.status) {
              HomeStatus.loading => 'Loading your dashboard...',
              HomeStatus.failure =>
                state.error.isEmpty
                    ? 'Unable to load welcome message'
                    : state.error,
              HomeStatus.success =>
                state.message.isEmpty
                    ? "What's on your desk today?"
                    : state.message,
              HomeStatus.initial => "What's on your desk today?",
            };

            return Column(
              children: [
                // TODO: wire notificationCount to real notification data.
                const PrintHubAppBar(notificationCount: 0),
                if (state.status == HomeStatus.loading)
                  const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      _r(context, 18),
                      _r(context, 16),
                      _r(context, 18),
                      _r(context, 16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, ${_greetingName().capitalizeFirst()} 👋',
                          style: TextStyle(
                            fontSize: _r(context, 28),
                            fontWeight: FontWeight.w800,
                            color: _primaryText,
                            height: 1.05,
                          ),
                        ),
                        SizedBox(height: _r(context, 6)),
                        Text(
                          greetingSubtitle,
                          style: TextStyle(
                            color: state.status == HomeStatus.failure
                                ? Colors.red.shade600
                                : _mutedText,
                            fontSize: _r(context, 15),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: _r(context, 18)),
                        const _PriorityCard(),
                        SizedBox(height: _r(context, 22)),
                        _SectionHeader(
                          title: 'OUR SERVICES',
                          onViewAll: _openUploadDocuments,
                        ),
                        SizedBox(height: _r(context, 12)),
                        _ServicesGrid(
                          categories: state.categories,
                          onPrintTap: _openUploadDocuments,
                        ),
                        SizedBox(height: _r(context, 22)),
                        _SectionHeader(
                          title: _activeJobs.length > 1
                              ? 'ACTIVE JOBS'
                              : 'ACTIVE JOB',
                          onViewAll: () {},
                        ),
                        SizedBox(height: _r(context, 12)),
                        if (_activeJobs.isEmpty)
                          const _NoActiveJobs()
                        else
                          for (final job in _activeJobs) ...[
                            _ActiveJobCard(
                              job: job,
                              onTap: () => _openActiveJob(job),
                              onRemove: () => _removeActiveJob(job),
                            ),
                            SizedBox(height: _r(context, 12)),
                          ],
                        SizedBox(height: _r(context, 22)),
                        _SectionHeader(
                          title: _recentOrders.length > 1
                              ? 'RECENT ORDERS'
                              : 'RECENT ORDER',
                          onViewAll: _openOrders,
                        ),
                        SizedBox(height: _r(context, 12)),
                        if (_recentOrdersLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_recentOrders.isEmpty)
                          const _NoRecentOrders()
                        else
                          for (final order in _recentOrders) ...[
                            _RecentOrderCard(
                              entry: order,
                              onTap: _openOrders,
                            ),
                            SizedBox(height: _r(context, 12)),
                          ],
                        SizedBox(height: _r(context, 8)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 0,
        onOrders: _openOrders,
        onProfile: _openProfile,
      ),
    );
  }
}

// ── Priority delivery banner ─────────────────────────────────────────────────
class _PriorityCard extends StatelessWidget {
  const _PriorityCard();

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20 * compact,
        18 * compact,
        20 * compact,
        18 * compact,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24 * compact),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A20C7), Color(0xFF40D9D9)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                color: Colors.white,
                size: 18 * compact,
              ),
              SizedBox(width: 8 * compact),
              Text(
                'PRIORITY SERVICE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14 * compact,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * compact),
          const Text(
            '15-minute express\nDelivery',
            style: TextStyle(
              color: Colors.white,
              height: 1.08,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8 * compact),
          Text(
            'Fastest print-to-door in the city.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section header with "View all" ───────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onViewAll});

  final String title;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: _r(context, 14),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: _primaryText,
          ),
        ),
        GestureDetector(
          onTap: onViewAll,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View all',
                style: TextStyle(
                  fontSize: _r(context, 13),
                  fontWeight: FontWeight.w700,
                  color: _accent,
                ),
              ),
              SizedBox(width: _r(context, 4)),
              Icon(
                Icons.arrow_forward_rounded,
                size: _r(context, 15),
                color: _accent,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Services grid ────────────────────────────────────────────────────────────
class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid({required this.categories, required this.onPrintTap});

  final List<PrintCategoryEntity> categories;
  final ValueChanged<PrintCategoryEntity> onPrintTap;

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    if (categories.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16 * compact),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20 * compact),
        ),
        child: Text(
          'No print categories available yet.',
          style: TextStyle(
            color: const Color(0xFF5D586B),
            fontSize: 14 * compact,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    // Display services in a fixed sequence: B&W → Color → Binding → Posters.
    final ordered = [...categories]
      ..sort(
        (a, b) => _categorySortOrder(
          a.printType,
        ).compareTo(_categorySortOrder(b.printType)),
      );

    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 14 * compact,
      crossAxisSpacing: 14 * compact,
      childAspectRatio: 1.1,
      children: List.generate(ordered.length, (index) {
        final category = ordered[index];
        return _ServiceTile(
          category: category,
          title: _resolveCategoryTitle(category.printType),
          svgAsset: _resolveCategorySvg(category.printType),
          fallbackIcon: _resolveCategoryIcon(category.printType),
          description: _resolveCategoryDescription(category.printType),
          iconBackground: _iconBackgroundForIndex(index),
          iconColor: _iconColorForIndex(index),
          onTap: () => onPrintTap(category),
        );
      }),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.category,
    required this.title,
    required this.svgAsset,
    required this.fallbackIcon,
    required this.description,
    required this.iconBackground,
    required this.iconColor,
    this.onTap,
  });

  final PrintCategoryEntity category;
  final String title;
  final String? svgAsset;
  final IconData fallbackIcon;
  final String description;
  final Color iconBackground;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20 * compact),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(20 * compact),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(14 * compact),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (svgAsset != null)
                    SvgPicture.asset(
                      svgAsset!,
                      width: 44 * compact,
                      height: 44 * compact,
                    )
                  else
                    Container(
                      width: 44 * compact,
                      height: 44 * compact,
                      decoration: BoxDecoration(
                        color: iconBackground,
                        borderRadius: BorderRadius.circular(12 * compact),
                      ),
                      child: _AvatarIcon(
                        avatarUrl: category.avatar,
                        fallbackIcon: fallbackIcon,
                        iconColor: iconColor,
                        compact: compact,
                      ),
                    ),
                  const Spacer(),
                  Container(
                    width: 26 * compact,
                    height: 26 * compact,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F3F8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 18 * compact,
                      color: const Color(0xFF8B8B9C),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12 * compact),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _primaryText,
                  fontSize: 16 * compact,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 4 * compact),
              Text(
                '₹${category.rate} / page',
                style: TextStyle(
                  color: _accent,
                  fontSize: 14 * compact,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4 * compact),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _mutedText,
                  fontSize: 11.5 * compact,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Active job card ──────────────────────────────────────────────────────────
class _NoActiveJobs extends StatelessWidget {
  const _NoActiveJobs();

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 16 * compact,
        vertical: 22 * compact,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20 * compact),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 34 * compact,
            color: const Color(0xFFB4AEC6),
          ),
          SizedBox(height: 8 * compact),
          Text(
            'No active jobs yet',
            style: TextStyle(
              color: _primaryText,
              fontSize: 14 * compact,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 2 * compact),
          Text(
            'Start a print order and it will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _mutedText,
              fontSize: 12 * compact,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveJobCard extends StatelessWidget {
  const _ActiveJobCard({
    required this.job,
    required this.onTap,
    required this.onRemove,
  });

  final ActiveJob job;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    final extra = job.fileCount > 1 ? '  +${job.fileCount - 1} more' : '';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20 * compact),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: Stack(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20 * compact),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16 * compact,
                16 * compact,
                16 * compact,
                16 * compact,
              ),
              child: Row(
            children: [
              Container(
                width: 48 * compact,
                height: 48 * compact,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(12 * compact),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: _accent,
                  size: 26 * compact,
                ),
              ),
              SizedBox(width: 12 * compact),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${job.title}$extra',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _primaryText,
                        fontSize: 15 * compact,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6 * compact),
                    Row(
                      children: [
                        Container(
                          width: 8 * compact,
                          height: 8 * compact,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8 * compact),
                        Text(
                          job.status,
                          style: TextStyle(
                            color: _mutedText,
                            fontSize: 12.5 * compact,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (job.grandTotal > 0) ...[
                      SizedBox(height: 6 * compact),
                      Text(
                        'Base Rs. ${job.baseRate.toStringAsFixed(0)}'
                        '  •  Subtotal Rs. ${job.subtotal.toStringAsFixed(0)}'
                        '  •  Delivery Rs. ${job.deliveryCharge.toStringAsFixed(0)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _mutedText,
                          fontSize: 11.5 * compact,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8 * compact),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (job.grandTotal > 0)
                    Text(
                      'Rs. ${job.grandTotal.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 14 * compact,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: const Color(0xFF8A8599),
                    size: 24 * compact,
                  ),
                ],
              ),
            ],
              ),
            ),
          ),
          Positioned(
            top: 4 * compact,
            right: 4 * compact,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onRemove,
                child: Padding(
                  padding: EdgeInsets.all(6 * compact),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18 * compact,
                    color: const Color(0xFF8A8599),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent order card (dashboard preview of `GET order/history`) ────────────
class _NoRecentOrders extends StatelessWidget {
  const _NoRecentOrders();

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 16 * compact,
        vertical: 22 * compact,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20 * compact),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 34 * compact,
            color: const Color(0xFFB4AEC6),
          ),
          SizedBox(height: 8 * compact),
          Text(
            'No orders yet',
            style: TextStyle(
              color: _primaryText,
              fontSize: 14 * compact,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 2 * compact),
          Text(
            'Your completed orders will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _mutedText,
              fontSize: 12 * compact,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentOrderCard extends StatelessWidget {
  const _RecentOrderCard({required this.entry, required this.onTap});

  final OrderHistoryEntry entry;
  final VoidCallback onTap;

  (String, Color) _statusStyle(String rawStatus) {
    final status = rawStatus.toUpperCase();
    if (status.contains('CANCEL') || status.contains('FAILED')) {
      return ('Cancelled', const Color(0xFFD93025));
    }
    if (status.contains('DELIVER') || status.contains('COMPLETE')) {
      return ('Delivered', _success);
    }
    if (status.contains('OUT') || status.contains('DISPATCH')) {
      return ('Out for delivery', const Color(0xFFF59E0B));
    }
    if (status.contains('PRINT')) {
      return ('Printing', const Color(0xFFF59E0B));
    }
    if (status.isEmpty) {
      return ('Processing', const Color(0xFFF59E0B));
    }
    return ('In progress', const Color(0xFFF59E0B));
  }

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    final extra = entry.itemCount > 1 ? '  +${entry.itemCount - 1} more' : '';
    final (statusLabel, statusColor) = _statusStyle(entry.orderStatus);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20 * compact),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20 * compact),
        child: Padding(
          padding: EdgeInsets.all(16 * compact),
          child: Row(
            children: [
              Container(
                width: 48 * compact,
                height: 48 * compact,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(12 * compact),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: _accent,
                  size: 26 * compact,
                ),
              ),
              SizedBox(width: 12 * compact),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.title}$extra',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _primaryText,
                        fontSize: 15 * compact,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6 * compact),
                    Row(
                      children: [
                        Container(
                          width: 8 * compact,
                          height: 8 * compact,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8 * compact),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: _mutedText,
                            fontSize: 12.5 * compact,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8 * compact),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (entry.grandTotal > 0)
                    Text(
                      'Rs. ${entry.grandTotal.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 14 * compact,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: const Color(0xFF8A8599),
                    size: 24 * compact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalizeFirst() {
    if (this.isEmpty) return "";
    return this[0].toUpperCase() + this.substring(1).toLowerCase();
  }
}

class _AvatarIcon extends StatelessWidget {
  const _AvatarIcon({
    required this.avatarUrl,
    required this.fallbackIcon,
    required this.iconColor,
    required this.compact,
  });

  final String avatarUrl;
  final IconData fallbackIcon;
  final Color iconColor;
  final double compact;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl.isEmpty) {
      return Icon(fallbackIcon, color: iconColor, size: 22 * compact);
    }

    return Padding(
      padding: EdgeInsets.all(10 * compact),
      child: Image.network(
        avatarUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(fallbackIcon, color: iconColor, size: 22 * compact);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Icon(fallbackIcon, color: iconColor, size: 22 * compact);
        },
      ),
    );
  }
}

/// Returns the bundled SVG icon for a category, or null when none matches
/// (e.g. lamination), in which case a Material icon fallback is used.
String? _resolveCategorySvg(String printType) {
  final normalized = printType.toLowerCase();
  if (normalized.contains('color')) {
    return 'assets/decorations/color_icon.svg';
  }
  if (normalized.contains('binding')) {
    return 'assets/decorations/binding_icon.svg';
  }
  // "Photo Print" shares the lamination tile per product mapping.
  if (normalized.contains('lamination') || normalized.contains('photo')) {
    return 'assets/decorations/binding_icon.svg';
  }
  if (normalized.contains('jambo') || normalized.contains('poster')) {
    return 'assets/decorations/jambo_icon.svg';
  }
  if (normalized.contains('black') || normalized.contains('b&w')) {
    return 'assets/decorations/b&w_icon.svg';
  }
  return null;
}

IconData _resolveCategoryIcon(String printType) {
  final normalized = printType.toLowerCase();
  if (normalized.contains('color')) {
    return Icons.palette_outlined;
  }
  if (normalized.contains('binding')) {
    return Icons.menu_book_outlined;
  }
  if (normalized.contains('lamination') || normalized.contains('photo')) {
    return Icons.layers_outlined;
  }
  if (normalized.contains('jambo') || normalized.contains('poster')) {
    return Icons.image_outlined;
  }
  if (normalized.contains('black') || normalized.contains('b&w')) {
    return Icons.description_outlined;
  }
  return Icons.description_outlined;
}

/// Display sequence for the services grid: B&W → Color → Binding → Posters,
/// then lamination, then anything else (in backend order).
int _categorySortOrder(String printType) {
  final normalized = printType.toLowerCase();
  if (normalized.contains('black') || normalized.contains('b&w')) return 0;
  if (normalized.contains('color')) return 1;
  if (normalized.contains('binding')) return 2;
  if (normalized.contains('jambo') || normalized.contains('poster')) return 3;
  if (normalized.contains('lamination') || normalized.contains('photo')) {
    return 4;
  }
  return 5;
}

/// Title shown on the service tile. Black & white categories are shortened to
/// "B&W"; everything else uses its capitalized name.
String _resolveCategoryTitle(String printType) {
  final normalized = printType.toLowerCase();
  if (normalized.contains('black') || normalized.contains('b&w')) {
    return 'B&W';
  }
  return printType.capitalizeFirst();
}

String _resolveCategoryDescription(String printType) {
  final normalized = printType.toLowerCase();
  if (normalized.contains('color')) {
    return 'Vibrant and high quality color prints';
  }
  if (normalized.contains('binding')) {
    return 'Spiral, comb, thermal & more';
  }
  if (normalized.contains('photo')) {
    return 'Glossy & premium photo prints';
  }
  if (normalized.contains('lamination')) {
    return 'Protective glossy & matte finish';
  }
  if (normalized.contains('jambo') || normalized.contains('poster')) {
    return 'High quality posters in any size';
  }
  if (normalized.contains('black') || normalized.contains('b&w')) {
    return 'High quality black & white prints';
  }
  return 'High quality printing service';
}

Color _iconBackgroundForIndex(int index) {
  const palette = <Color>[
    Color(0xFFE8F0FE), // blue
    Color(0xFFDFF6F4), // teal
    Color(0xFFEFE9FD), // purple
    Color(0xFFFDEEE2), // orange
  ];
  return palette[index % palette.length];
}

Color _iconColorForIndex(int index) {
  const palette = <Color>[
    Color(0xFF2563EB), // blue
    Color(0xFF0FB6A6), // teal
    Color(0xFF7C3AED), // purple
    Color(0xFFF97316), // orange
  ];
  return palette[index % palette.length];
}

