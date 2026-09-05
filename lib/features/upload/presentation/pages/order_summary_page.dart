import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/payment_config.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/storage/temporary_auth_store.dart';
import '../../../../core/widgets/primary_action_button.dart';
import '../../../../core/widgets/printhub_app_bar.dart';
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

// Sourced from AppColors (lib/core/constants/app_constants.dart) so the
// checkout palette is a named part of the app-wide theme, not a file-local
// duplicate.
const _accent = AppColors.dashboardAccent;
const _primaryText = AppColors.dashboardPrimaryText;
const _mutedText = AppColors.checkoutMutedText;
const _success = AppColors.success;
const _danger = AppColors.error;

/// Demo promo codes applied entirely on the client. The discount is a fraction
/// of the subtotal. The backend does not yet support promos, so this is
/// front-end-only until a coupons API exists.
const _promoCodes = <String, double>{
  'PROMO20': 0.20,
  'SAVE10': 0.10,
  'FIRST15': 0.15,
};

/// Checkout screen shown after "Next Step". It loads the pending products for
/// [orderId] from `GET order/order-summary` and renders the print
/// configuration, offers, billing breakdown and delivery destination.
class OrderSummaryPage extends StatefulWidget {
  const OrderSummaryPage({
    super.key,
    required this.orderId,
    this.deliveryAddress,
    this.addressId,
    this.createResult,
  });

  final String orderId;

  /// Address label to show in the delivery destination, when one was selected.
  final String? deliveryAddress;

  /// Mongo id of the chosen delivery address, sent to `order/checkout`.
  final String? addressId;

  /// `order/create` response, used for the billing breakdown (baseRate,
  /// totalAmount, deliveryCharge, grandTotal). Null when resumed from an
  /// active job, in which case the summary totals are used instead.
  final OrderCreateResult? createResult;

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
    const bg = Color(0xFFF6F8FC);
    const accent = Color(0xFF3E34D3);
    const titleColor = Color(0xFF1F1F2E);
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            const PrintHubAppBar(
              title: 'Checkout',
              showBack: true,
              centerTitle: false,
            ),
            Padding(
              padding: EdgeInsets.only(top: 10, left: 2, right: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STEP 03',
                    style: TextStyle(
                      fontSize: _r(context, 13),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      color: accent,
                    ),
                  ),
                  SizedBox(height: _r(context, 10)),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: _r(context, 18),
                        height: 1.05,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                      children: const [
                        TextSpan(text: 'Review your order and '),
                        TextSpan(
                          text: 'proceed to payment.',
                          style: TextStyle(color: Color(0xFF1B43D4)),
                        ),
                      ],
                    ),
                  ),
                  //  SizedBox(height: _r(context, 18)),
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
                    orderId: widget.orderId,
                    addressId: widget.addressId,
                    createResult: widget.createResult,
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

class _SummaryContent extends StatefulWidget {
  const _SummaryContent({
    required this.summary,
    required this.deliveryAddress,
    required this.orderId,
    required this.addressId,
    required this.createResult,
  });

  final OrderSummaryResponse summary;
  final String? deliveryAddress;
  final String orderId;
  final String? addressId;
  final OrderCreateResult? createResult;

  @override
  State<_SummaryContent> createState() => _SummaryContentState();
}

class _SummaryContentState extends State<_SummaryContent> {
  final TextEditingController _promoController = TextEditingController();
  String? _appliedCode;
  double _appliedRate = 0;

  /// Opens the Razorpay Checkout sheet and dispatches its result to
  /// [_onPaymentSuccess] / [_onPaymentError] / [_onExternalWallet].
  late final Razorpay _razorpay;

  /// True once `order/checkout` has succeeded. Keeps the Pay button hidden
  /// after the order is placed.
  bool _orderPlaced = false;

  /// Controls the progress bar shown in place of the Pay button while a
  /// checkout/payment step is in flight. [_placingLabel] controls its text.
  bool _showPlacingBar = false;
  String _placingLabel = 'Placing your order…';

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _promoController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  /// Calls `order/checkout` for UPI first — this is what creates the
  /// server-side Razorpay order and moves the order to `PAYMENT_PENDING` —
  /// then opens the Checkout sheet with that order's id attached, so the
  /// Razorpay webhook can trace the eventual payment back to this order.
  Future<void> _startRazorpayCheckout(double amountToPay) async {
    final addressId = widget.addressId;
    if (addressId == null || addressId.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Please select a delivery address.')),
        );
      return;
    }

    setState(() {
      _placingLabel = 'Creating your order…';
      _showPlacingBar = true;
    });

    try {
      final result = await sl<OrderRemoteDataSource>().checkout(
        orderId: widget.orderId,
        addressId: addressId,
        paymentMethod: 'UPI',
      );
      final razorpayOrderId = result.razorpayOrderId;
      if (razorpayOrderId == null || razorpayOrderId.isEmpty) {
        throw const OrderCreateException(
          'Payment could not be initiated. Please try again.',
        );
      }
      if (!mounted) return;
      setState(() => _showPlacingBar = false);
      _openCheckout(amountToPay, razorpayOrderId: razorpayOrderId);
    } on OrderCreateException catch (error) {
      if (!mounted) return;
      setState(() => _showPlacingBar = false);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _showPlacingBar = false);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Failed to start payment.')),
        );
    }
  }

  /// Opens the Razorpay Checkout sheet for [amountToPay] (in rupees) against
  /// the server-created [razorpayOrderId].
  void _openCheckout(double amountToPay, {required String razorpayOrderId}) {
    final mobile = sl<TemporaryAuthStore>().mobile;

    final options = <String, dynamic>{
      'key': kRazorpayKeyId,
      'order_id': razorpayOrderId,
      'amount': (amountToPay * 100).round(),
      'currency': 'INR',
      'name': 'PrintHub',
      'description': 'Order #${widget.orderId}',
      if (mobile.isNotEmpty) 'prefill': {'contact': mobile},
    };

    try {
      _razorpay.open(options);
    } catch (error) {
      debugPrint('Razorpay open failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Unable to open the payment sheet.')),
        );
    }
  }

  /// Called once the Razorpay sheet reports a successful payment. This is
  /// only a client-side hint, not confirmation — the order is already
  /// `PAYMENT_PENDING` from checkout, and only the Razorpay webhook actually
  /// flips it to paid. Poll the order status until that lands.
  void _onPaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('Razorpay payment success: ${response.paymentId}');
    if (!mounted) return;
    setState(() {
      _placingLabel = 'Confirming your payment…';
      _showPlacingBar = true;
    });
    unawaited(_pollPaymentStatus());
  }

  /// Called when the Razorpay sheet is cancelled or a payment fails
  /// client-side. Purely informational: the order stays `PAYMENT_PENDING`
  /// (retryable) until either a webhook confirms it or nothing ever arrives.
  void _onPaymentError(PaymentFailureResponse response) {
    debugPrint(
      'Razorpay payment error: ${response.code} ${response.message}',
    );
    if (!mounted) return;
    if (response.code == Razorpay.PAYMENT_CANCELLED) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text('Payment could not be completed.')),
      );
  }

  /// Called when the user picks an external wallet app. The result isn't
  /// known yet at this point, so this only informs the user — it doesn't
  /// place the order.
  void _onExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text('Opening ${response.walletName ?? 'wallet'}…')),
      );
  }

  /// Polls `GET order/<orderId>/status` until the Razorpay webhook has moved
  /// the order out of `PAYMENT_PENDING` (or we give up after ~1 minute).
  /// This — not the Razorpay client callback — is what actually confirms
  /// "payment complete, ready for print" to the user.
  Future<void> _pollPaymentStatus() async {
    const maxAttempts = 30;
    const interval = Duration(seconds: 2);

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      await Future<void>.delayed(interval);
      if (!mounted) return;

      try {
        final status = await sl<OrderRemoteDataSource>().getOrderStatus(
          orderId: widget.orderId,
        );

        if (status.orderStatus == 'PAYMENT_FAILED') {
          setState(() => _showPlacingBar = false);
          if (!mounted) return;
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              const SnackBar(
                content: Text('Payment failed. Please try again.'),
              ),
            );
          return;
        }

        if (status.orderStatus != 'PAYMENT_PENDING') {
          // Webhook landed: order moved on to PENDING_ACCEPTANCE (or beyond).
          setState(() {
            _showPlacingBar = false;
            _orderPlaced = true;
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  'Payment complete — your order is ready for print!',
                ),
              ),
            );
          return;
        }
      } catch (_) {
        // Transient network hiccup — keep polling rather than giving up on
        // a single failed check.
      }
    }

    if (!mounted) return;
    setState(() => _showPlacingBar = false);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            "Still confirming your payment — we'll update your order shortly.",
          ),
        ),
      );
  }

  void _applyPromo() {
    final code = _promoController.text.trim().toUpperCase();
    final rate = _promoCodes[code];
    if (code.isEmpty) return;
    if (rate == null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Invalid promo code.')));
      return;
    }
    setState(() {
      _appliedCode = code;
      _appliedRate = rate;
    });
    FocusScope.of(context).unfocus();
  }

  void _removePromo() {
    setState(() {
      _appliedCode = null;
      _appliedRate = 0;
      _promoController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final create = widget.createResult;
    // Billing breakdown comes from the order/create response when available,
    // falling back to the order summary totals (resumed jobs).
    final baseRate = (create?.baseRate ?? 0).toDouble();
    final subtotal = (create?.totalAmount ?? summary.totalAmount).toDouble();
    final delivery = (create?.deliveryCharge ?? summary.deliveryCharge)
        .toDouble();
    final grandTotal = (create?.grandTotal ?? summary.grandTotal).toDouble();
    final discount = subtotal * _appliedRate;
    final amountToPay = grandTotal - discount;

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
                const _SectionLabel('PRINT CONFIGURATION'),
                SizedBox(height: _r(context, 10)),
                for (final item in summary.items) ...[
                  _ConfigCard(item: item),
                  SizedBox(height: _r(context, 12)),
                ],
                SizedBox(height: _r(context, 8)),
                const _SectionLabel('OFFERS & DISCOUNTS'),
                SizedBox(height: _r(context, 10)),
                _PromoField(
                  controller: _promoController,
                  appliedCode: _appliedCode,
                  onApply: _applyPromo,
                  onRemove: _removePromo,
                ),
                SizedBox(height: _r(context, 20)),
                const _SectionLabel('BILLING BREAKDOWN'),
                SizedBox(height: _r(context, 10)),
                _BillingCard(
                  baseRate: baseRate,
                  subtotal: subtotal,
                  delivery: delivery,
                  grandTotal: grandTotal,
                  discount: discount,
                  appliedCode: _appliedCode,
                  amountToPay: amountToPay,
                ),
                SizedBox(height: _r(context, 20)),
                Row(
                  children: [
                    const _SectionLabel('DELIVERY DESTINATION'),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Text(
                        'Change',
                        style: TextStyle(
                          color: _accent,
                          fontSize: _r(context, 14),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: _r(context, 10)),
                _DestinationCard(address: widget.deliveryAddress),
              ],
            ),
          ),
        ),
        // While checkout runs (and for 2s after success) show the progress bar.
        // Once placed, the Pay button stays hidden (empty bottom area).
        if (_showPlacingBar)
          _PlacingOrderBar(label: _placingLabel)
        else if (_orderPlaced)
          const SizedBox.shrink()
        else
          _PaymentBar(
            total: amountToPay,
            onPay: () => _startRazorpayCheckout(amountToPay),
          ),
      ],
    );
  }
}

/// Bottom bar shown while `order/checkout` is in flight (or while polling for
/// webhook confirmation after Razorpay success), replacing the Pay button so
/// it can't be tapped again.
class _PlacingOrderBar extends StatelessWidget {
  const _PlacingOrderBar({this.label = 'Placing your order…'});

  final String label;

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
        height: 56 * compact,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 22 * compact,
              height: 22 * compact,
              child: const CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(_accent),
              ),
            ),
            SizedBox(width: 12 * compact),
            Text(
              label,
              style: TextStyle(
                color: _primaryText,
                fontSize: 16 * compact,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: _r(context, 12.5),
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: _mutedText,
      ),
    );
  }
}

class _ConfigCard extends StatelessWidget {
  const _ConfigCard({required this.item});

  final OrderSummaryItem item;

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    final details = item.details;
    final copyLabel = details.numberOfCopy == 1 ? 'COPY' : 'COPIES';
    final descParts = <String>[
      if (details.printType.isNotEmpty)
        '${_capitalize(details.printType)} Printing',
      '${details.numberOfCopy} ${details.numberOfCopy == 1 ? 'copy' : 'copies'}',
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14 * compact),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18 * compact),
        border: Border.all(color: const Color(0xFFE6E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56 * compact,
            height: 56 * compact,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(14 * compact),
            ),
            child: Icon(
              Icons.description_outlined,
              color: _accent,
              size: 28 * compact,
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
                    fontSize: 16 * compact,
                    fontWeight: FontWeight.w800,
                    color: _primaryText,
                  ),
                ),
                SizedBox(height: 4 * compact),
                Text(
                  descParts.join(' • '),
                  style: TextStyle(
                    fontSize: 12.5 * compact,
                    color: _mutedText,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 8 * compact),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10 * compact,
                    vertical: 4 * compact,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFF1F0),
                    borderRadius: BorderRadius.circular(8 * compact),
                  ),
                  child: Text(
                    '${details.numberOfCopy} $copyLabel',
                    style: TextStyle(
                      color: const Color(0xFF0F766E),
                      fontSize: 10.5 * compact,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoField extends StatelessWidget {
  const _PromoField({
    required this.controller,
    required this.appliedCode,
    required this.onApply,
    required this.onRemove,
  });

  final TextEditingController controller;
  final String? appliedCode;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                ],
                decoration: InputDecoration(
                  hintText: 'Enter Promo Code',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16 * compact,
                    vertical: 16 * compact,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14 * compact),
                    borderSide: const BorderSide(color: Color(0xFFE6E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14 * compact),
                    borderSide: const BorderSide(color: _accent, width: 1.5),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10 * compact),
            SizedBox(
              height: 52 * compact,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14 * compact),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 22 * compact),
                ),
                onPressed: onApply,
                child: Text(
                  'Apply',
                  style: TextStyle(
                    fontSize: 15 * compact,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (appliedCode != null) ...[
          SizedBox(height: 10 * compact),
          Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: _success,
                size: 18 * compact,
              ),
              SizedBox(width: 6 * compact),
              Text(
                '$appliedCode APPLIED',
                style: TextStyle(
                  color: _success,
                  fontSize: 13 * compact,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onRemove,
                child: Text(
                  'Remove',
                  style: TextStyle(
                    color: _danger,
                    fontSize: 13 * compact,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BillingCard extends StatelessWidget {
  const _BillingCard({
    required this.baseRate,
    required this.subtotal,
    required this.delivery,
    required this.grandTotal,
    required this.discount,
    required this.appliedCode,
    required this.amountToPay,
  });

  final double baseRate;
  final double subtotal;
  final double delivery;
  final double grandTotal;
  final double discount;
  final String? appliedCode;
  final double amountToPay;

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
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
          if (baseRate > 0) ...[
            _PriceRow(label: 'Base Rate', value: _money(baseRate)),
            SizedBox(height: 10 * compact),
          ],
          _PriceRow(label: 'Subtotal', value: _money(subtotal)),
          SizedBox(height: 10 * compact),
          _PriceRow(
            label: 'Delivery Fee',
            value: delivery == 0 ? 'FREE' : _money(delivery),
            valueColor: delivery == 0 ? _accent : null,
          ),
          //SizedBox(height: 10 * compact),
          //   _PriceRow(label: 'Grand Total', value: _money(grandTotal)),
          if (discount > 0) ...[
            SizedBox(height: 10 * compact),
            _PriceRow(
              label: 'Discount',
              labelChip: appliedCode,
              labelColor: _success,
              value: '-${_money(discount)}',
              valueColor: _success,
            ),
          ],
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12 * compact),
            child: const Divider(height: 1, color: Color(0xFFE6E8F0)),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Amount to Pay',
                    style: TextStyle(
                      fontSize: 14 * compact,
                      fontWeight: FontWeight.w700,
                      color: _primaryText,
                    ),
                  ),
                  SizedBox(height: 2 * compact),
                  Text(
                    _money(amountToPay),
                    style: TextStyle(
                      fontSize: 26 * compact,
                      fontWeight: FontWeight.w800,
                      color: _accent,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: 120 * compact,
                child: Text(
                  'Includes all applicable taxes and handling charges.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11 * compact,
                    color: _mutedText,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.labelColor,
    this.labelChip,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final Color? labelColor;
  final String? labelChip;

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15 * compact,
            color: labelColor ?? const Color(0xFF54505F),
            fontWeight: labelColor != null ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        if (labelChip != null) ...[
          SizedBox(width: 8 * compact),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8 * compact,
              vertical: 2 * compact,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFD7F5E3),
              borderRadius: BorderRadius.circular(6 * compact),
            ),
            child: Text(
              labelChip!,
              style: TextStyle(
                fontSize: 10 * compact,
                fontWeight: FontWeight.w800,
                color: _success,
              ),
            ),
          ),
        ],
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

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({required this.address});

  final String? address;

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    final hasAddress = address != null && address!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14 * compact),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1FB),
        borderRadius: BorderRadius.circular(18 * compact),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40 * compact,
            height: 40 * compact,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on_outlined,
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
                  hasAddress ? 'Delivery Address' : 'No address selected',
                  style: TextStyle(
                    fontSize: 15 * compact,
                    fontWeight: FontWeight.w800,
                    color: _primaryText,
                  ),
                ),
                SizedBox(height: 4 * compact),
                Text(
                  hasAddress
                      ? address!
                      : 'Go back to choose a delivery address.',
                  style: TextStyle(
                    fontSize: 13 * compact,
                    color: const Color(0xFF4F4C5D),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentBar extends StatelessWidget {
  const _PaymentBar({required this.total, required this.onPay});

  final num total;

  /// Opens the Razorpay Checkout sheet for [total].
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    final height = 56.0 * compact;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        18 * compact,
        12 * compact,
        18 * compact,
        16 * compact,
      ),
      child: PrimaryActionButton(
        label: 'Pay ${_money(total)}',
        onPressed: onPay,
        height: height,
        borderRadius: 30 * compact,
        fontSize: 17 * compact,
        iconSize: 22 * compact,
      ),
    );
  }
}

String _capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1).toLowerCase();
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
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Color(0xFFB4AEC6)),
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
