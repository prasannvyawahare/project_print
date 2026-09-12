import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/printhub_app_bar.dart';
import '../../data/datasources/order_remote_data_source.dart';

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
const _mutedText = AppColors.checkoutMutedText;
const _success = AppColors.success;
const _danger = AppColors.error;
const _bg = AppColors.dashboardBackground;

/// Order-tracking milestones shown on the confirmation screen, in order.
/// The backend's `orderStatus` values are mapped onto this fixed set so the
/// timeline stays legible even if a status we don't explicitly recognise
/// comes back.
enum _Milestone { placed, printing, outForDelivery, delivered }

const _milestoneLabels = <_Milestone, String>{
  _Milestone.placed: 'Order Placed',
  _Milestone.printing: 'Printing',
  _Milestone.outForDelivery: 'Out for Delivery',
  _Milestone.delivered: 'Delivered',
};

const _milestoneIcons = <_Milestone, IconData>{
  _Milestone.placed: Icons.receipt_long_rounded,
  _Milestone.printing: Icons.print_rounded,
  _Milestone.outForDelivery: Icons.delivery_dining_rounded,
  _Milestone.delivered: Icons.home_rounded,
};

/// Congratulations / order-status screen. Shown right after a payment is
/// confirmed, or opened from the Orders history list to view an order's
/// current status. Polls `GET order/<orderId>/status` on load and then every
/// 5 minutes so the tracker stays fresh while the user is on this screen.
class OrderConfirmationPage extends StatefulWidget {
  const OrderConfirmationPage({
    super.key,
    required this.orderId,
    required this.amountPaid,
    this.paymentMethod = 'UPI',
    this.fromHistory = false,
  });

  final String orderId;
  final num amountPaid;
  final String paymentMethod;

  /// True when opened from the Orders history list to view details, rather
  /// than right after paying. Swaps the forced "back goes Home" behaviour
  /// for a normal back button, and softens the celebratory copy.
  final bool fromHistory;

  @override
  State<OrderConfirmationPage> createState() => _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends State<OrderConfirmationPage> {
  static const _refreshInterval = Duration(minutes: 5);
  static const _terminalStatuses = {'DELIVERED', 'COMPLETED', 'CANCELLED'};

  Timer? _refreshTimer;
  OrderStatusResult? _status;
  DateTime? _lastUpdatedAt;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) => _refreshStatus());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      final result = await sl<OrderRemoteDataSource>().getOrderStatus(
        orderId: widget.orderId,
      );
      if (!mounted) return;
      setState(() {
        _status = result;
        _lastUpdatedAt = DateTime.now();
      });
      if (_terminalStatuses.contains(result.orderStatus.toUpperCase())) {
        _refreshTimer?.cancel();
      }
    } catch (_) {
      // Keep showing the last known status on a transient failure — the
      // periodic timer will retry in 5 minutes regardless.
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  void _goHome() {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRouter.home, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final rawStatus = _status?.orderStatus.toUpperCase() ?? '';
    final isCancelled = rawStatus == 'CANCELLED';

    return PopScope(
      canPop: widget.fromHistory,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !widget.fromHistory) _goHome();
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [
              if (widget.fromHistory)
                const PrintHubAppBar(
                  title: 'Order Details',
                  showBack: true,
                  centerTitle: false,
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    _r(context, 20),
                    _r(context, 28),
                    _r(context, 20),
                    _r(context, 16),
                  ),
                  child: Column(
                    children: [
                      _CelebrationHeader(
                        cancelled: isCancelled,
                        fromHistory: widget.fromHistory,
                      ),
                      SizedBox(height: _r(context, 28)),
                      _OrderInfoCard(
                        orderId: widget.orderId,
                        amountPaid: widget.amountPaid,
                        paymentMethod: widget.paymentMethod,
                      ),
                      SizedBox(height: _r(context, 20)),
                      if (!isCancelled) ...[
                        const _SectionLabel('ORDER STATUS'),
                        SizedBox(height: _r(context, 10)),
                        _StatusTimelineCard(orderStatus: rawStatus),
                        SizedBox(height: _r(context, 12)),
                        _AutoRefreshNote(
                          lastUpdatedAt: _lastUpdatedAt,
                          refreshing: _refreshing,
                          onRefreshNow: _refreshStatus,
                        ),
                      ] else
                        const _CancelledCard(),
                    ],
                  ),
                ),
              ),
              Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(
                  _r(context, 18),
                  _r(context, 12),
                  _r(context, 18),
                  _r(context, 16),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: _r(context, 56),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_r(context, 30)),
                      ),
                    ),
                    onPressed: _goHome,
                    child: Text(
                      'Back to Home',
                      style: TextStyle(
                        fontSize: _r(context, 17),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CelebrationHeader extends StatelessWidget {
  const _CelebrationHeader({required this.cancelled, required this.fromHistory});

  final bool cancelled;

  /// Softens the copy to a neutral "Order Status" when viewing an older
  /// order from history, instead of the post-payment "Payment Successful!".
  final bool fromHistory;

  @override
  Widget build(BuildContext context) {
    final color = cancelled ? _danger : _success;
    final bgColor = cancelled
        ? const Color(0xFFFADAD7)
        : const Color(0xFFD7F5E3);

    final title = cancelled
        ? 'Order Cancelled'
        : fromHistory
        ? 'Order Status'
        : 'Payment Successful!';
    final subtitle = cancelled
        ? 'This order was cancelled. Contact support if this was unexpected.'
        : fromHistory
        ? "Here's the latest status for this order."
        : 'Your order is confirmed and on its way to being printed.';

    return Column(
      children: [
        Container(
          width: _r(context, 96),
          height: _r(context, 96),
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(
            cancelled
                ? Icons.cancel_rounded
                : Icons.check_circle_rounded,
            color: color,
            size: _r(context, 56),
          ),
        ),
        SizedBox(height: _r(context, 20)),
        Text(
          title,
          style: TextStyle(
            fontSize: _r(context, 24),
            fontWeight: FontWeight.w800,
            color: _primaryText,
          ),
        ),
        SizedBox(height: _r(context, 8)),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: _r(context, 14),
            color: _mutedText,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: _r(context, 12.5),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: _mutedText,
        ),
      ),
    );
  }
}

class _OrderInfoCard extends StatelessWidget {
  const _OrderInfoCard({
    required this.orderId,
    required this.amountPaid,
    required this.paymentMethod,
  });

  final String orderId;
  final num amountPaid;
  final String paymentMethod;

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    final shortId = orderId.length > 10
        ? '#${orderId.substring(orderId.length - 10).toUpperCase()}'
        : '#${orderId.toUpperCase()}';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * compact),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20 * compact),
        border: Border.all(color: const Color(0xFFE6E8F0)),
      ),
      child: Column(
        children: [
          _InfoRow(label: 'Order ID', value: shortId),
          SizedBox(height: 10 * compact),
          _InfoRow(label: 'Payment Method', value: paymentMethod),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12 * compact),
            child: const Divider(height: 1, color: Color(0xFFE6E8F0)),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Amount Paid',
                style: TextStyle(
                  fontSize: 14 * compact,
                  fontWeight: FontWeight.w700,
                  color: _primaryText,
                ),
              ),
              const Spacer(),
              Text(
                _money(amountPaid),
                style: TextStyle(
                  fontSize: 22 * compact,
                  fontWeight: FontWeight.w800,
                  color: _accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14 * compact, color: _mutedText),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14 * compact,
            fontWeight: FontWeight.w700,
            color: _primaryText,
          ),
        ),
      ],
    );
  }
}

/// Maps a raw backend `orderStatus` onto the fixed 4-step timeline. Falls
/// back to keyword matching for statuses we don't explicitly know about, so
/// the tracker degrades gracefully instead of looking stuck.
_Milestone _milestoneFor(String orderStatus) {
  switch (orderStatus) {
    case 'PENDING_ACCEPTANCE':
    case 'ACCEPTED':
    case 'PAYMENT_PENDING':
      return _Milestone.placed;
    case 'PRINTING':
    case 'IN_PROGRESS':
      return _Milestone.printing;
    case 'OUT_FOR_DELIVERY':
    case 'DISPATCHED':
      return _Milestone.outForDelivery;
    case 'DELIVERED':
    case 'COMPLETED':
      return _Milestone.delivered;
  }
  if (orderStatus.contains('DELIVER') && !orderStatus.contains('OUT')) {
    return _Milestone.delivered;
  }
  if (orderStatus.contains('OUT') || orderStatus.contains('DISPATCH')) {
    return _Milestone.outForDelivery;
  }
  if (orderStatus.contains('PRINT')) return _Milestone.printing;
  return _Milestone.placed;
}

class _StatusTimelineCard extends StatelessWidget {
  const _StatusTimelineCard({required this.orderStatus});

  final String orderStatus;

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    final current = orderStatus.isEmpty
        ? _Milestone.placed
        : _milestoneFor(orderStatus);
    final currentIndex = _Milestone.values.indexOf(current);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * compact),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20 * compact),
        border: Border.all(color: const Color(0xFFE6E8F0)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _Milestone.values.length; i++)
            _TimelineStep(
              milestone: _Milestone.values[i],
              state: i < currentIndex
                  ? _StepState.done
                  : i == currentIndex
                  ? _StepState.active
                  : _StepState.upcoming,
              isLast: i == _Milestone.values.length - 1,
            ),
        ],
      ),
    );
  }
}

enum _StepState { done, active, upcoming }

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.milestone,
    required this.state,
    required this.isLast,
  });

  final _Milestone milestone;
  final _StepState state;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    final isDone = state == _StepState.done;
    final isActive = state == _StepState.active;
    final color = (isDone || isActive) ? _accent : const Color(0xFFB4AEC6);
    final bgColor = (isDone || isActive)
        ? const Color(0xFFE8F0FE)
        : const Color(0xFFF1F1F5);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 34 * compact,
                height: 34 * compact,
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(
                  isDone ? Icons.check_rounded : _milestoneIcons[milestone],
                  color: color,
                  size: 18 * compact,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: EdgeInsets.symmetric(vertical: 4 * compact),
                    color: isDone ? _accent : const Color(0xFFE6E8F0),
                  ),
                ),
            ],
          ),
          SizedBox(width: 12 * compact),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: 6 * compact,
                bottom: isLast ? 0 : 20 * compact,
              ),
              child: Text(
                _milestoneLabels[milestone]!,
                style: TextStyle(
                  fontSize: 14.5 * compact,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: (isDone || isActive) ? _primaryText : _mutedText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoRefreshNote extends StatelessWidget {
  const _AutoRefreshNote({
    required this.lastUpdatedAt,
    required this.refreshing,
    required this.onRefreshNow,
  });

  final DateTime? lastUpdatedAt;
  final bool refreshing;
  final VoidCallback onRefreshNow;

  String _timeLabel(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    final updated = lastUpdatedAt;
    return Row(
      children: [
        Icon(Icons.sync_rounded, size: 15 * compact, color: _mutedText),
        SizedBox(width: 6 * compact),
        Expanded(
          child: Text(
            updated == null
                ? 'Fetching the latest status…'
                : 'Auto-updates every 5 min • Last updated ${_timeLabel(updated)}',
            style: TextStyle(fontSize: 12 * compact, color: _mutedText),
          ),
        ),
        if (refreshing)
          SizedBox(
            width: 14 * compact,
            height: 14 * compact,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_accent),
            ),
          )
        else
          GestureDetector(
            onTap: onRefreshNow,
            child: Text(
              'Refresh',
              style: TextStyle(
                fontSize: 12.5 * compact,
                fontWeight: FontWeight.w700,
                color: _accent,
              ),
            ),
          ),
      ],
    );
  }
}

class _CancelledCard extends StatelessWidget {
  const _CancelledCard();

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * compact),
      decoration: BoxDecoration(
        color: const Color(0xFFFADAD7),
        borderRadius: BorderRadius.circular(18 * compact),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: _danger, size: 20 * compact),
          SizedBox(width: 10 * compact),
          Expanded(
            child: Text(
              'If you were charged, a refund will be processed automatically.',
              style: TextStyle(
                fontSize: 13 * compact,
                color: const Color(0xFF7A2A24),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
