import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/storage/active_job_store.dart';
import '../../../../core/widgets/printhub_app_bar.dart';
import '../../../print/domain/entities/print_order_data.dart';
import '../../../upload/data/datasources/order_remote_data_source.dart';
import '../../../upload/data/models/order_summary_model.dart';
import '../../../upload/presentation/pages/order_summary_page.dart';
import '../../domain/entities/address_entity.dart';
import '../bloc/address_bloc.dart';
import '../bloc/address_event.dart';
import '../bloc/address_state.dart';

double _screenScale(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final widthScale = (size.width / 390).clamp(0.82, 1.0);
  final heightScale = (size.height / 844).clamp(0.82, 1.0);
  return (widthScale * 0.7 + heightScale * 0.3).toDouble();
}

double _r(BuildContext context, double value) => value * _screenScale(context);

const _accent = Color(0xFF2563EB);
const _primaryText = Color(0xFF1B1B2F);
const _mutedText = Color(0xFF7B778C);

/// Review & Deliver — shows the uploaded file queue for the order and lets the
/// user pick a saved delivery address before continuing to checkout.
///
/// (Formerly `DeliveryAddressPage`. The GPS map and delivery-speed cards were
/// removed in favour of the simpler queue + address layout.)
class OrderReviewPage extends StatefulWidget {
  const OrderReviewPage({super.key, required this.initialOrder, this.orderId});

  final PrintOrderData initialOrder;
  final String? orderId;

  @override
  State<OrderReviewPage> createState() => _OrderReviewPageState();
}

class _OrderReviewPageState extends State<OrderReviewPage> {
  late final String? _orderId;
  String? _selectedAddressId;
  AddressEntity? _selectedAddress;
  Future<OrderSummaryResponse>? _queueFuture;

  @override
  void initState() {
    super.initState();
    final id = widget.orderId?.trim();
    _orderId = (id == null || id.isEmpty) ? null : id;
    final resolvedId = _orderId;
    if (resolvedId != null) {
      _queueFuture = sl<OrderRemoteDataSource>().getOrderSummary(
        orderId: resolvedId,
      );
    }
  }

  String _addressLabel(AddressEntity a) {
    final parts = <String>[
      if (a.flat.isNotEmpty) a.flat,
      if (a.address.isNotEmpty) a.address,
      if (a.pincode != 0) 'PIN ${a.pincode}',
    ];
    return parts.join(', ');
  }

  void _proceedToCheckout() {
    final orderId = _orderId;
    if (orderId == null || orderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order ID is missing. Please start the order again.'),
        ),
      );
      return;
    }

    final address = _selectedAddress;
    if (address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address.')),
      );
      return;
    }

    final addressLabel = _addressLabel(address);
    _recordActiveJob(orderId, addressLabel);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            OrderSummaryPage(orderId: orderId, deliveryAddress: addressLabel),
      ),
    );
  }

  void _recordActiveJob(String orderId, String addressLabel) {
    final documents = widget.initialOrder.documents;
    final title = documents.isNotEmpty ? documents.first.name : 'Print order';
    sl<ActiveJobStore>().upsert(
      ActiveJob(
        orderId: orderId,
        title: title,
        fileCount: documents.isEmpty ? 1 : documents.length,
        status: 'Awaiting payment',
        address: addressLabel,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> _showAddAddressSheet(BuildContext pageContext) async {
    final addressController = TextEditingController();
    final flatController = TextEditingController();
    final landmarkController = TextEditingController();
    final pincodeController = TextEditingController();
    var selectedType = 'home';

    await showModalBottomSheet<void>(
      context: pageContext,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add New Address',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _primaryText,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Address Type',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4F4C5D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: [
                      for (final type in ['home', 'office', 'other'])
                        ChoiceChip(
                          label: Text(
                            type[0].toUpperCase() + type.substring(1),
                          ),
                          selected: selectedType == type,
                          onSelected: (_) =>
                              setSheetState(() => selectedType = type),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: addressController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Address *',
                      hintText: 'e.g. Malad East, Mumbai',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: flatController,
                    decoration: InputDecoration(
                      labelText: 'Flat / House No. *',
                      hintText: 'e.g. 701 3A',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: landmarkController,
                    decoration: InputDecoration(
                      labelText: 'Landmark',
                      hintText: 'e.g. Near Xavier School',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pincodeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Pincode *',
                      hintText: 'e.g. 400097',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        final address = addressController.text.trim();
                        final flat = flatController.text.trim();
                        final pincodeText = pincodeController.text.trim();

                        if (address.isEmpty ||
                            flat.isEmpty ||
                            pincodeText.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please fill address, flat and pincode',
                              ),
                            ),
                          );
                          return;
                        }

                        final pincode = int.tryParse(pincodeText) ?? 0;
                        if (pincode == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid pincode'),
                            ),
                          );
                          return;
                        }

                        pageContext.read<AddressBloc>().add(
                          AddressCreateRequested(
                            addressType: selectedType,
                            address: address,
                            flat: flat,
                            landmark: landmarkController.text.trim(),
                            pincode: pincode,
                          ),
                        );
                        Navigator.of(sheetContext).pop();
                      },
                      child: const Text(
                        'Save Address',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            );
          },
        );
      },
    );

    addressController.dispose();
    flatController.dispose();
    landmarkController.dispose();
    pincodeController.dispose();
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'home':
        return Icons.home_filled;
      case 'office':
      case 'work':
        return Icons.work_outline_rounded;
      default:
        return Icons.location_on_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AddressBloc>(
      create: (_) => sl<AddressBloc>()..add(const AddressFetchRequested()),
      child: Builder(
        builder: (ctx) => BlocListener<AddressBloc, AddressState>(
          listener: (context, state) {
            if (state.status == AddressStatus.failure &&
                state.error.isNotEmpty) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.error)));
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFF6F8FC),
            body: SafeArea(
              child: Column(
                children: [
                  const PrintHubAppBar(
                    title: 'Review & Deliver',
                    showBack: true,
                  ),
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
                          _QueueSection(
                            queueFuture: _queueFuture,
                            fallbackDocuments: widget.initialOrder.documents,
                          ),
                          SizedBox(height: _r(context, 24)),
                          Row(
                            children: [
                              Text(
                                'Delivery Details',
                                style: TextStyle(
                                  fontSize: _r(context, 22),
                                  fontWeight: FontWeight.w800,
                                  color: _primaryText,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => _showAddAddressSheet(ctx),
                                child: Text(
                                  '+ Add Address',
                                  style: TextStyle(
                                    color: _accent,
                                    fontSize: _r(context, 14),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: _r(context, 12)),
                          BlocBuilder<AddressBloc, AddressState>(
                            builder: (context, state) {
                              if (state.status == AddressStatus.loading ||
                                  state.status == AddressStatus.creating) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              if (state.addresses.isEmpty) {
                                return _EmptyAddresses(
                                  onAdd: () => _showAddAddressSheet(ctx),
                                );
                              }
                              return Column(
                                children: [
                                  for (final addr in state.addresses) ...[
                                    _AddressCard(
                                      entity: addr,
                                      icon: _iconForType(addr.addressType),
                                      selected:
                                          (_selectedAddressId == null &&
                                              addr.selected) ||
                                          _selectedAddressId == addr.id,
                                      onTap: () {
                                        setState(() {
                                          _selectedAddressId = addr.id;
                                          _selectedAddress = addr;
                                        });
                                        ctx.read<AddressBloc>().add(
                                          AddressSelectRequested(
                                            addressId: addr.id,
                                          ),
                                        );
                                      },
                                      onDelete: () {
                                        ctx.read<AddressBloc>().add(
                                          AddressRemoveRequested(
                                            addressId: addr.id,
                                          ),
                                        );
                                      },
                                    ),
                                    SizedBox(height: _r(context, 12)),
                                  ],
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(
                _r(context, 18),
                _r(context, 12),
                _r(context, 18),
                _r(context, 14),
              ),
              child: SizedBox(
                width: double.infinity,
                height: _r(context, 56),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_r(context, 16)),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1248E7)],
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(_r(context, 16)),
                      onTap: _proceedToCheckout,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Next Step',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _r(context, 17),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: _r(context, 10)),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: _r(context, 22),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Queue section ────────────────────────────────────────────────────────────
class _QueueSection extends StatelessWidget {
  const _QueueSection({
    required this.queueFuture,
    required this.fallbackDocuments,
  });

  final Future<OrderSummaryResponse>? queueFuture;
  final List<PrintDocument> fallbackDocuments;

  @override
  Widget build(BuildContext context) {
    // No order id (e.g. reached straight from configure) — show local files.
    if (queueFuture == null) {
      return _buildList(
        context,
        fallbackDocuments
            .map((d) => _QueueEntry(name: d.name, fileType: d.name))
            .toList(),
      );
    }

    return FutureBuilder<OrderSummaryResponse>(
      future: queueFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context, null),
              SizedBox(height: _r(context, 12)),
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          );
        }

        final items = snapshot.data?.items ?? const <OrderSummaryItem>[];
        final entries = items.isEmpty
            ? fallbackDocuments
                  .map((d) => _QueueEntry(name: d.name, fileType: d.name))
                  .toList()
            : items
                  .map(
                    (i) => _QueueEntry(
                      name: i.details.fileName,
                      fileType: i.details.fileType,
                    ),
                  )
                  .toList();
        return _buildList(context, entries);
      },
    );
  }

  Widget _header(BuildContext context, int? count) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Queue',
          style: TextStyle(
            fontSize: _r(context, 26),
            fontWeight: FontWeight.w800,
            color: _primaryText,
          ),
        ),
        const Spacer(),
        if (count != null)
          Text(
            '$count item${count == 1 ? '' : 's'} detected',
            style: TextStyle(
              fontSize: _r(context, 13),
              color: _mutedText,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildList(BuildContext context, List<_QueueEntry> entries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(context, entries.length),
        SizedBox(height: _r(context, 12)),
        if (entries.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(_r(context, 16)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_r(context, 16)),
            ),
            child: Text(
              'No files in this order.',
              style: TextStyle(color: _mutedText, fontSize: _r(context, 14)),
            ),
          )
        else
          for (final entry in entries) ...[
            _QueueFileCard(entry: entry),
            SizedBox(height: _r(context, 12)),
          ],
      ],
    );
  }
}

class _QueueEntry {
  const _QueueEntry({required this.name, required this.fileType});

  final String name;
  final String fileType;
}

IconData _fileIcon(String nameOrType) {
  final v = nameOrType.toLowerCase();
  if (v.endsWith('.pdf') || v.contains('pdf')) {
    return Icons.picture_as_pdf_rounded;
  }
  if (v.endsWith('.png') ||
      v.endsWith('.jpg') ||
      v.endsWith('.jpeg') ||
      v.contains('image')) {
    return Icons.image_outlined;
  }
  if (v.endsWith('.ppt') || v.endsWith('.pptx') || v.contains('presentation')) {
    return Icons.slideshow_rounded;
  }
  return Icons.description_outlined;
}

class _QueueFileCard extends StatelessWidget {
  const _QueueFileCard({required this.entry});

  final _QueueEntry entry;

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);

    void notImplemented(String action) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('$action coming soon.')));
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12 * compact),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * compact),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44 * compact,
            height: 44 * compact,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(12 * compact),
            ),
            child: Icon(
              _fileIcon(entry.fileType.isEmpty ? entry.name : entry.fileType),
              color: _accent,
              size: 24 * compact,
            ),
          ),
          SizedBox(width: 12 * compact),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15 * compact,
                    fontWeight: FontWeight.w700,
                    color: _primaryText,
                  ),
                ),
                SizedBox(height: 6 * compact),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8 * compact,
                    vertical: 3 * compact,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7F5E3),
                    borderRadius: BorderRadius.circular(6 * compact),
                  ),
                  child: Text(
                    'UPLOADED',
                    style: TextStyle(
                      color: const Color(0xFF1B9E54),
                      fontSize: 10 * compact,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => notImplemented('Edit'),
            icon: Icon(
              Icons.edit_outlined,
              size: 20 * compact,
              color: _mutedText,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => notImplemented('Delete'),
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 20 * compact,
              color: const Color(0xFFD93025),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Address ──────────────────────────────────────────────────────────────────
class _EmptyAddresses extends StatelessWidget {
  const _EmptyAddresses({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: _r(context, 24)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_r(context, 18)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.location_off_outlined,
            size: _r(context, 44),
            color: const Color(0xFFB4AEC6),
          ),
          SizedBox(height: _r(context, 8)),
          Text(
            'No saved addresses yet',
            style: TextStyle(fontSize: _r(context, 14), color: _mutedText),
          ),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Address'),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.entity,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  final AddressEntity entity;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  String get _title {
    final t = entity.addressType;
    return t.isEmpty ? 'Address' : t[0].toUpperCase() + t.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18 * compact),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18 * compact),
        child: Container(
          padding: EdgeInsets.all(14 * compact),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18 * compact),
            border: Border.all(
              color: selected ? _accent : const Color(0xFFE6E8F0),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44 * compact,
                height: 44 * compact,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F0FE),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _accent, size: 22 * compact),
              ),
              SizedBox(width: 12 * compact),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      style: TextStyle(
                        fontSize: 16 * compact,
                        fontWeight: FontWeight.w800,
                        color: _primaryText,
                      ),
                    ),
                    SizedBox(height: 4 * compact),
                    Text(
                      entity.flat.isNotEmpty
                          ? '${entity.flat}, ${entity.address}'
                          : entity.address,
                      style: TextStyle(
                        fontSize: 13 * compact,
                        color: const Color(0xFF4F4C5D),
                        height: 1.35,
                      ),
                    ),
                    if (entity.landmark.isNotEmpty) ...[
                      SizedBox(height: 2 * compact),
                      Text(
                        'Near ${entity.landmark}',
                        style: TextStyle(
                          fontSize: 12 * compact,
                          color: _mutedText,
                        ),
                      ),
                    ],
                    SizedBox(height: 2 * compact),
                    Text(
                      'PIN: ${entity.pincode}',
                      style: TextStyle(
                        fontSize: 11 * compact,
                        color: const Color(0xFF9B97A8),
                      ),
                    ),
                    if (selected) ...[
                      SizedBox(height: 8 * compact),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10 * compact,
                          vertical: 4 * compact,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FE),
                          borderRadius: BorderRadius.circular(8 * compact),
                        ),
                        child: Text(
                          'Selected for delivery',
                          style: TextStyle(
                            color: _accent,
                            fontSize: 11 * compact,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 6 * compact),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: selected ? _accent : const Color(0xFFB4AEC6),
                    size: 24 * compact,
                  ),
                  SizedBox(height: 8 * compact),
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 28 * compact,
                      height: 28 * compact,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEB),
                        borderRadius: BorderRadius.circular(8 * compact),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: const Color(0xFFD93025),
                        size: 17 * compact,
                      ),
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
}
