import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/printhub_app_bar.dart';
import '../../data/datasources/order_remote_data_source.dart';
import '../../data/models/order_history_model.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import 'order_confirmation_page.dart' show OrderConfirmationPage;

double _screenScale(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final widthScale = (size.width / 390).clamp(0.82, 1.0);
  final heightScale = (size.height / 844).clamp(0.82, 1.0);
  return (widthScale * 0.7 + heightScale * 0.3).toDouble();
}

double _r(BuildContext context, double value) => value * _screenScale(context);

String _money(num value) => 'Rs. ${value.toStringAsFixed(2)}';

const _accent = AppColors.dashboardAccent;
const _primaryText = AppColors.dashboardPrimaryText;
const _mutedText = AppColors.dashboardMutedText;
const _bg = AppColors.dashboardBackground;

/// Orders tab (bottom nav) — lists the signed-in user's past orders via
/// `GET order/history`.
class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  late Future<OrderHistoryResponse> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _load();
  }

  Future<OrderHistoryResponse> _load() {
    return sl<OrderRemoteDataSource>().getOrderHistory();
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _historyFuture = future);
    await future;
  }

  void _openOrderDetails(OrderHistoryEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderConfirmationPage(
          orderId: entry.orderId,
          amountPaid: entry.grandTotal,
          paymentMethod: entry.paymentMethod.isEmpty
              ? 'N/A'
              : entry.paymentMethod,
          fromHistory: true,
        ),
      ),
    );
  }

  void _openProfile() {
    // ProfileBloc is a DI singleton (already fetched from the dashboard), so
    // reuse it here instead of creating a new one that would re-fetch.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<ProfileBloc>.value(
          value: sl<ProfileBloc>(),
          child: const ProfilePage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            const PrintHubAppBar(title: 'My Orders', centerTitle: false),
            Expanded(
              child: FutureBuilder<OrderHistoryResponse>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _ErrorView(
                      message: snapshot.error is OrderCreateException
                          ? (snapshot.error as OrderCreateException).message
                          : 'Failed to load your orders.',
                      onRetry: _refresh,
                    );
                  }

                  final orders = snapshot.data?.orders ?? const [];
                  if (orders.isEmpty) {
                    return _EmptyView(onRefresh: _refresh);
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    color: _accent,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        _r(context, 18),
                        _r(context, 16),
                        _r(context, 18),
                        _r(context, 16),
                      ),
                      itemCount: orders.length,
                      separatorBuilder: (_, _) =>
                          SizedBox(height: _r(context, 12)),
                      itemBuilder: (context, index) => _OrderHistoryCard(
                        entry: orders[index],
                        onTap: () => _openOrderDetails(orders[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 1,
        onHome: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
        onProfile: _openProfile,
      ),
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  const _OrderHistoryCard({required this.entry, required this.onTap});

  final OrderHistoryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    final shortId = entry.orderId.length > 8
        ? '#${entry.orderId.substring(entry.orderId.length - 8).toUpperCase()}'
        : '#${entry.orderId.toUpperCase()}';
    final (label, fg, bg) = _statusStyle(entry.orderStatus);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18 * compact),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18 * compact),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(14 * compact),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18 * compact),
            border: Border.all(color: const Color(0xFFE6E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44 * compact,
                    height: 44 * compact,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FE),
                      borderRadius: BorderRadius.circular(12 * compact),
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: _accent,
                      size: 22 * compact,
                    ),
                  ),
                  SizedBox(width: 12 * compact),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15 * compact,
                            fontWeight: FontWeight.w800,
                            color: _primaryText,
                          ),
                        ),
                        SizedBox(height: 2 * compact),
                        Text(
                          shortId,
                          style: TextStyle(
                            fontSize: 12 * compact,
                            color: _mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10 * compact,
                      vertical: 5 * compact,
                    ),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(8 * compact),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: fg,
                        fontSize: 10.5 * compact,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10 * compact),
                child: const Divider(height: 1, color: Color(0xFFF0F1F5)),
              ),
              Row(
                children: [
                  Text(
                    entry.itemCount == 1
                        ? '1 item'
                        : '${entry.itemCount} items',
                    style: TextStyle(
                      fontSize: 12.5 * compact,
                      color: _mutedText,
                    ),
                  ),
                  if (entry.createdAt != null) ...[
                    SizedBox(width: 8 * compact),
                    Text('•', style: TextStyle(color: _mutedText)),
                    SizedBox(width: 8 * compact),
                    Text(
                      _formatDate(entry.createdAt!),
                      style: TextStyle(
                        fontSize: 12.5 * compact,
                        color: _mutedText,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    _money(entry.grandTotal),
                    style: TextStyle(
                      fontSize: 15 * compact,
                      fontWeight: FontWeight.w800,
                      color: _primaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  (String, Color, Color) _statusStyle(String rawStatus) {
    final status = rawStatus.toUpperCase();
    if (status.contains('CANCEL') || status.contains('FAILED')) {
      return ('CANCELLED', const Color(0xFFD93025), const Color(0xFFFADAD7));
    }
    if (status.contains('DELIVER') || status.contains('COMPLETE')) {
      return ('DELIVERED', const Color(0xFF1B9E54), const Color(0xFFD7F5E3));
    }
    if (status.contains('OUT') || status.contains('DISPATCH')) {
      return ('OUT FOR DELIVERY', _accent, const Color(0xFFE8F0FE));
    }
    if (status.contains('PRINT')) {
      return ('PRINTING', _accent, const Color(0xFFE8F0FE));
    }
    if (status.isEmpty) {
      return ('PROCESSING', _mutedText, const Color(0xFFF1F1F5));
    }
    return ('IN PROGRESS', _accent, const Color(0xFFE8F0FE));
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFFB4AEC6),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6A667A)),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _accent),
              onPressed: onRetry,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: _accent,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 96),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 48,
                  color: Color(0xFFB4AEC6),
                ),
                SizedBox(height: 12),
                Text(
                  "You haven't placed any orders yet.",
                  style: TextStyle(fontSize: 14, color: Color(0xFF6A667A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
