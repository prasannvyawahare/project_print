import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../data/datasources/order_remote_data_source.dart';
import '../../data/models/order_summary_model.dart';

double _screenScale(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final widthScale = (size.width / 390).clamp(0.82, 1.0);
  final heightScale = (size.height / 844).clamp(0.82, 1.0);
  return (widthScale * 0.7 + heightScale * 0.3).toDouble();
}

double _r(BuildContext context, double value) => value * _screenScale(context);

String _money(num value) => 'Rs. ${value.toStringAsFixed(2)}';

/// Checkout screen shown after "Proceed to CheckOut". It loads the pending
/// products for [orderId] from `GET order/order-summary` and renders the
/// per-item rates/totals returned by the backend (the same rates exposed by
/// `print-type/get` on the home screen) plus the order totals.
class OrderSummaryPage extends StatefulWidget {
  const OrderSummaryPage({
    super.key,
    required this.orderId,
    this.deliveryAddress,
  });

  final String orderId;

  /// Address label to show in the delivery bar, when one was selected.
  final String? deliveryAddress;

  @override
  State<OrderSummaryPage> createState() => _OrderSummaryPageState();
}

class _OrderSummaryPageState extends State<OrderSummaryPage> {
  late Future<OrderSummaryResponse> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _loadSummary();
  }

  Future<OrderSummaryResponse> _loadSummary() {
    return sl<OrderRemoteDataSource>().getOrderSummary(orderId: widget.orderId);
  }

  void _retry() {
    setState(() {
      _summaryFuture = _loadSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF5F2FA);
    const accent = Color(0xFF4525CD);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(
                _r(context, 12),
                _r(context, 8),
                _r(context, 12),
                _r(context, 10),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: _r(context, 20),
                    ),
                    color: accent,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Checkout',
                        style: TextStyle(
                          fontSize: _r(context, 19),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F1F2E),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.notifications_none_rounded,
                      size: _r(context, 22),
                    ),
                    color: accent,
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<OrderSummaryResponse>(
                future: _summaryFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _ErrorView(
                      message: snapshot.error is OrderCreateException
                          ? (snapshot.error as OrderCreateException).message
                          : 'Failed to load order summary.',
                      onRetry: _retry,
                    );
                  }

                  final summary = snapshot.data;
                  if (summary == null || summary.items.isEmpty) {
                    return const _EmptyView();
                  }

                  return _SummaryContent(
                    summary: summary,
                    deliveryAddress: widget.deliveryAddress,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryContent extends StatelessWidget {
  const _SummaryContent({required this.summary, required this.deliveryAddress});

  final OrderSummaryResponse summary;
  final String? deliveryAddress;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF4525CD);

    return Column(
      children: [
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
                  'CONFIRM ORDER',
                  style: TextStyle(
                    fontSize: _r(context, 12),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: accent,
                  ),
                ),
                SizedBox(height: _r(context, 4)),
                Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: _r(context, 30),
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1726),
                  ),
                ),
                SizedBox(height: _r(context, 16)),
                for (final item in summary.items) ...[
                  _ItemCard(item: item),
                  SizedBox(height: _r(context, 14)),
                ],
                SizedBox(height: _r(context, 4)),
                _PriceBreakdown(summary: summary),
                SizedBox(height: _r(context, 14)),
                _DeliveryBar(address: deliveryAddress),
              ],
            ),
          ),
        ),
        _PaymentBar(total: summary.grandTotal),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});

  final OrderSummaryItem item;

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    final details = item.details;
    final copyLabel = details.numberOfCopy == 1 ? 'Copy' : 'Copies';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14 * compact),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24 * compact),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64 * compact,
            height: 64 * compact,
            decoration: BoxDecoration(
              color: const Color(0xFF1F2A3B),
              borderRadius: BorderRadius.circular(14 * compact),
            ),
            child: Icon(
              Icons.description_outlined,
              color: Colors.white70,
              size: 30 * compact,
            ),
          ),
          SizedBox(width: 12 * compact),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17 * compact,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF20202E),
                  ),
                ),
                SizedBox(height: 4 * compact),
                Text(
                  '${details.numberOfCopy} $copyLabel  •  ${_money(item.rate)}/copy',
                  style: TextStyle(
                    fontSize: 12.5 * compact,
                    color: const Color(0xFF6E6A7C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8 * compact),
                if (details.printType.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10 * compact,
                      vertical: 4 * compact,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4DDF8),
                      borderRadius: BorderRadius.circular(10 * compact),
                    ),
                    child: Text(
                      details.printType.toUpperCase(),
                      style: TextStyle(
                        color: const Color(0xFF4A23CC),
                        fontSize: 10.5 * compact,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 8 * compact),
          Text(
            _money(item.total),
            style: TextStyle(
              fontSize: 17 * compact,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1726),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceBreakdown extends StatelessWidget {
  const _PriceBreakdown({required this.summary});

  final OrderSummaryResponse summary;

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * compact),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE8F6),
        borderRadius: BorderRadius.circular(20 * compact),
      ),
      child: Column(
        children: [
          _PriceRow(label: 'Subtotal', value: _money(summary.totalAmount)),
          SizedBox(height: 10 * compact),
          _PriceRow(
            label: 'Delivery Fee',
            value: summary.deliveryCharge == 0
                ? 'FREE'
                : _money(summary.deliveryCharge),
            valueColor: summary.deliveryCharge == 0
                ? const Color(0xFF1A56DD)
                : null,
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12 * compact),
            child: Divider(height: 1, color: const Color(0xFFCFC7E0)),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GRAND TOTAL',
                    style: TextStyle(
                      color: const Color(0xFF4525CD),
                      fontSize: 11 * compact,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 2 * compact),
                  Text(
                    _money(summary.grandTotal),
                    style: TextStyle(
                      fontSize: 28 * compact,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1726),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15 * compact,
            color: const Color(0xFF54505F),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 15 * compact,
            fontWeight: FontWeight.w700,
            color: valueColor ?? const Color(0xFF272434),
          ),
        ),
      ],
    );
  }
}

class _DeliveryBar extends StatelessWidget {
  const _DeliveryBar({required this.address});

  final String? address;

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    final label = (address == null || address!.isEmpty)
        ? 'Add a delivery address'
        : address!;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12 * compact),
      decoration: BoxDecoration(
        color: const Color(0xFFE7E2F1),
        borderRadius: BorderRadius.circular(18 * compact),
      ),
      child: Row(
        children: [
          Container(
            width: 40 * compact,
            height: 40 * compact,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_shipping_outlined,
              color: const Color(0xFF4525CD),
              size: 22 * compact,
            ),
          ),
          SizedBox(width: 12 * compact),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DELIVERING TO',
                  style: TextStyle(
                    fontSize: 10 * compact,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: const Color(0xFF6E6A7C),
                  ),
                ),
                SizedBox(height: 2 * compact),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5 * compact,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF272434),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: const Color(0xFF8A8599),
            size: 24 * compact,
          ),
        ],
      ),
    );
  }
}

class _PaymentBar extends StatelessWidget {
  const _PaymentBar({required this.total});

  final num total;

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        18 * compact,
        12 * compact,
        18 * compact,
        16 * compact,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56 * compact,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30 * compact),
            gradient: const LinearGradient(
              colors: [Color(0xFF4A23CC), Color(0xFF1248E7)],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30 * compact),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Payment of ${_money(total)} coming soon.'),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Proceed to Payment',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17 * compact,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 10 * compact),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 22 * compact,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4A23CC),
              ),
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
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: Color(0xFFB4AEC6),
            ),
            SizedBox(height: 12),
            Text(
              'No pending products in this order.',
              style: TextStyle(fontSize: 14, color: Color(0xFF6A667A)),
            ),
          ],
        ),
      ),
    );
  }
}
