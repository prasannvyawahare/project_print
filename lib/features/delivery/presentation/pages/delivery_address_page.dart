import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/primary_action_button.dart';
import '../../../print/domain/entities/print_order_data.dart';
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

class DeliveryAddressPage extends StatefulWidget {
  const DeliveryAddressPage({
    super.key,
    required this.initialOrder,
    this.orderId,
  });

  final PrintOrderData initialOrder;
  final String? orderId;

  @override
  State<DeliveryAddressPage> createState() => _DeliveryAddressPageState();
}

class _DeliveryAddressPageState extends State<DeliveryAddressPage> {
  late PrintOrderData _order;
  late final String? _orderId;
  String? _selectedAddressId;

  // Location state
  bool _isLocating = false;
  String _locationLabel = '';

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    _orderId = widget.orderId?.trim().isEmpty == true
        ? null
        : widget.orderId?.trim();
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    if (!mounted) return;
    setState(() {
      _isLocating = true;
      _locationLabel = '';
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isLocating = false;
            _locationLabel = 'Location permission denied';
          });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      String label;
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[
          if (p.subLocality != null && p.subLocality!.isNotEmpty)
            p.subLocality!,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
          if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
            p.administrativeArea!,
        ];
        label = parts.isNotEmpty
            ? parts.join(', ')
            : '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      } else {
        label =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      }

      if (mounted) {
        setState(() {
          _locationLabel = label;
          _isLocating = false;
          _order = _order.copyWith(isLocationConfirmed: true);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLocating = false;
          _locationLabel = 'Unable to detect location';
        });
      }
    }
  }

  Future<void> _changeLocation() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) => _ChangeLocationSheet(initialLabel: _locationLabel),
    );

    if (!mounted || result == null) return;

    if (result == '__gps__') {
      await _fetchCurrentLocation();
    } else if (result.isNotEmpty) {
      setState(() {
        _locationLabel = result;
        _order = _order.copyWith(isLocationConfirmed: true);
      });
    }
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

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderSummaryPage(
          orderId: orderId,
          deliveryAddress: _locationLabel.isEmpty ? null : _locationLabel,
        ),
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
                      color: Color(0xFF1F1F2E),
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
                        backgroundColor: const Color(0xFF4A23CC),
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
    const accent = Color(0xFF3E34D3);

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
            backgroundColor: const Color(0xFFF5F2FA),
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
                          color: const Color(0xFF1E2433),
                        ),
                        Expanded(
                          child: Text(
                            'Delivery Address',
                            style: TextStyle(
                              fontSize: _r(context, 19),
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F1F2E),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: Icon(
                            Icons.notifications_none_rounded,
                            size: _r(context, 22),
                          ),
                          color: const Color(0xFF1E2433),
                        ),
                      ],
                    ),
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
                          Text(
                            'STEP 02',
                            style: TextStyle(
                              fontSize: _r(context, 13),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 3,
                              color: accent,
                            ),
                          ),
                          if (_orderId != null) ...[
                            SizedBox(height: _r(context, 6)),
                            Text(
                              'Order ID: $_orderId',
                              style: TextStyle(
                                fontSize: _r(context, 12),
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6A667A),
                              ),
                            ),
                          ],
                          SizedBox(height: _r(context, 12)),
                          _MapCard(
                            isLocating: _isLocating,
                            locationLabel: _locationLabel,
                            onChangeTap: _changeLocation,
                          ),
                          SizedBox(height: _r(context, 16)),
                          Row(
                            children: [
                              Text(
                                'Saved Locations',
                                style: TextStyle(
                                  fontSize: _r(context, 20),
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF21202D),
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () => _showAddAddressSheet(ctx),
                                child: Text(
                                  '+ ADD NEW',
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: _r(context, 12),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: _r(context, 8)),
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
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 24,
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.location_off_outlined,
                                          size: _r(context, 48),
                                          color: const Color(0xFFB4AEC6),
                                        ),
                                        SizedBox(height: _r(context, 10)),
                                        Text(
                                          'No saved addresses yet',
                                          style: TextStyle(
                                            fontSize: _r(context, 14),
                                            color: const Color(0xFF7B778C),
                                          ),
                                        ),
                                        SizedBox(height: _r(context, 6)),
                                        TextButton.icon(
                                          onPressed: () =>
                                              _showAddAddressSheet(ctx),
                                          icon: const Icon(Icons.add),
                                          label: const Text('Add Address'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              return Column(
                                children: [
                                  for (
                                    int i = 0;
                                    i < state.addresses.length;
                                    i++
                                  ) ...[
                                    if (i > 0)
                                      SizedBox(height: _r(context, 10)),
                                    _AddressCard(
                                      entity: state.addresses[i],
                                      icon: _iconForType(
                                        state.addresses[i].addressType,
                                      ),
                                      selected:
                                          state.addresses[i].selected ||
                                          _selectedAddressId ==
                                              state.addresses[i].id,
                                      onTap: () {
                                        setState(() {
                                          _selectedAddressId =
                                              state.addresses[i].id;
                                        });
                                        ctx.read<AddressBloc>().add(
                                          AddressSelectRequested(
                                            addressId: state.addresses[i].id,
                                          ),
                                        );
                                      },
                                      onDelete: () {
                                        ctx.read<AddressBloc>().add(
                                          AddressRemoveRequested(
                                            addressId: state.addresses[i].id,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                          SizedBox(height: _r(context, 18)),
                          Text(
                            'Delivery Speed',
                            style: TextStyle(
                              fontSize: _r(context, 20),
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF21202D),
                            ),
                          ),
                          SizedBox(height: _r(context, 8)),
                          const _SpeedCard(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: Container(
              color: Colors.white.withValues(alpha: 0.65),
              padding: EdgeInsets.fromLTRB(
                _r(context, 18),
                _r(context, 12),
                _r(context, 18),
                _r(context, 16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'Total Delivery Cost',
                        style: TextStyle(
                          fontSize: _r(context, 16),
                          color: const Color(0xFF3B3949),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '\$12.50',
                        style: TextStyle(
                          fontSize: _r(context, 22),
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E1B27),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: _r(context, 10)),
                  PrimaryActionButton(
                    label: 'Proceed to CheckOut',
                    onPressed: _proceedToCheckout,
                    height: _r(context, 54),
                    fontSize: _r(context, 17),
                    iconSize: _r(context, 22),
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

// Bottom sheet widget for changing location — owns its TextEditingController
// so the controller is disposed correctly via State.dispose(), not after pop().
class _ChangeLocationSheet extends StatefulWidget {
  const _ChangeLocationSheet({required this.initialLabel});

  final String initialLabel;

  @override
  State<_ChangeLocationSheet> createState() => _ChangeLocationSheetState();
}

class _ChangeLocationSheetState extends State<_ChangeLocationSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialLabel);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            'Change Delivery Location',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1F2E),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Enter location / landmark',
              prefixIcon: const Icon(
                Icons.location_on_outlined,
                color: Color(0xFF4A23CC),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF4A23CC),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop('__gps__'),
            icon: const Icon(Icons.gps_fixed, color: Color(0xFF4A23CC)),
            label: const Text(
              'Use my current GPS location',
              style: TextStyle(color: Color(0xFF4A23CC)),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF4A23CC)),
              minimumSize: const Size.fromHeight(44),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4A23CC),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Confirm Location',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({
    required this.isLocating,
    required this.locationLabel,
    required this.onChangeTap,
  });

  final bool isLocating;
  final String locationLabel;
  final VoidCallback onChangeTap;

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28 * compact),
      child: Container(
        height: 260 * compact,
        color: const Color(0xFFE9DFC9),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _MapPatternPainter())),
            const Align(alignment: Alignment(0, -0.12), child: _MapPin()),
            Positioned(
              left: 14 * compact,
              right: 14 * compact,
              bottom: 16 * compact,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12 * compact,
                  vertical: 10 * compact,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(12 * compact),
                ),
                child: Row(
                  children: [
                    if (isLocating)
                      SizedBox(
                        width: 16 * compact,
                        height: 16 * compact,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: const Color(0xFF4A23CC),
                        ),
                      )
                    else
                      Icon(
                        Icons.gps_fixed,
                        color: Color(0xFF4A23CC),
                        size: 16 * compact,
                      ),
                    SizedBox(width: 8 * compact),
                    Expanded(
                      child: Text(
                        isLocating
                            ? 'Detecting your location...'
                            : locationLabel.isEmpty
                            ? 'Tap CHANGE to set location'
                            : locationLabel,
                        style: TextStyle(
                          fontSize: 14 * compact,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF252432),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: isLocating ? null : onChangeTap,
                      borderRadius: BorderRadius.circular(8 * compact),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6 * compact,
                          vertical: 4 * compact,
                        ),
                        child: Text(
                          'CHANGE',
                          style: TextStyle(
                            color: isLocating
                                ? Color(0xFFB0A8D0)
                                : Color(0xFF4A23CC),
                            fontSize: 13 * compact,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
    return t[0].toUpperCase() + t.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    return Material(
      color: selected ? Colors.white : const Color(0xFFECE7F4),
      borderRadius: BorderRadius.circular(24 * compact),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24 * compact),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            12 * compact,
            12 * compact,
            12 * compact,
            12 * compact,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24 * compact),
            border: selected
                ? const Border(
                    left: BorderSide(color: Color(0xFF4A23CC), width: 8),
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 68 * compact,
                height: 68 * compact,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFE2DBF7)
                      : const Color(0xFFE6E2EF),
                  borderRadius: BorderRadius.circular(4 * compact),
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? const Color(0xFF4A23CC)
                      : const Color(0xFF585567),
                  size: 30 * compact,
                ),
              ),
              SizedBox(width: 12 * compact),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      style: TextStyle(
                        fontSize: 15 * compact,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF252432),
                        height: 1.0,
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
                          color: const Color(0xFF7B778C),
                          height: 1.2,
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
                    color: selected
                        ? const Color(0xFF4A23CC)
                        : const Color(0xFFB4AEC6),
                    size: 26 * compact,
                  ),
                  SizedBox(height: 6 * compact),
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

class _SpeedCard extends StatelessWidget {
  const _SpeedCard();

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22 * compact),
        border: Border.all(color: const Color(0xFF2143D2), width: 3),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              12 * compact,
              12 * compact,
              12 * compact,
              10 * compact,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8 * compact,
                    runSpacing: 6 * compact,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const _PillLabel(label: 'EXPRESS DELIVERY'),
                      Text(
                        'Kinetic',
                        style: TextStyle(
                          color: Color(0xFF4A23CC),
                          fontWeight: FontWeight.w800,
                          fontSize: 13 * compact,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8 * compact),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '15',
                      style: TextStyle(
                        color: Color(0xFF3C2DC2),
                        fontSize: 30 * compact,
                        fontWeight: FontWeight.w800,
                        height: 0.95,
                      ),
                    ),
                    SizedBox(height: 2 * compact),
                    Text(
                      'MINUTES',
                      style: TextStyle(
                        color: Color(0xFF4D4A5A),
                        fontSize: 10 * compact,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              12 * compact,
              0,
              12 * compact,
              14 * compact,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Arriving by 10:45 AM',
                  style: TextStyle(
                    fontSize: 18 * compact,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1C28),
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 8 * compact),
                Text(
                  'Priority printing & lightning\ndispatch.',
                  style: TextStyle(
                    color: Color(0xFF4C495A),
                    fontSize: 12 * compact,
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

class _PillLabel extends StatelessWidget {
  const _PillLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10 * compact,
        vertical: 6 * compact,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFDCE2FF),
        borderRadius: BorderRadius.circular(14 * compact),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10 * compact,
          fontWeight: FontWeight.w800,
          color: Color(0xFF243278),
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    return Container(
      width: 78 * compact,
      height: 78 * compact,
      decoration: BoxDecoration(
        color: const Color(0xFF4A23CC).withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 56 * compact,
          height: 56 * compact,
          decoration: const BoxDecoration(
            color: Color(0xFF4A23CC),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.location_on,
            color: Colors.white,
            size: 24 * compact,
          ),
        ),
      ),
    );
  }
}

class _MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = const Color(0xFFF5EFE0)
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 16; i++) {
      final y = size.height * i / 15;
      road.strokeWidth = i % 5 == 0 ? 2.2 : 1.1;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), road);
    }

    for (var i = 0; i < 14; i++) {
      final x = size.width * i / 13;
      road.strokeWidth = i % 4 == 0 ? 2.0 : 1.0;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), road);
    }

    final curve = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFE3DAC3);

    final path = Path();
    path.moveTo(0, size.height * 0.25);
    path.quadraticBezierTo(
      size.width * 0.30,
      size.height * 0.55,
      size.width * 0.58,
      size.height * 0.4,
    );
    path.quadraticBezierTo(
      size.width * 0.78,
      size.height * 0.3,
      size.width,
      size.height * 0.62,
    );
    canvas.drawPath(path, curve);

    final park = Paint()
      ..color = const Color(0xFFD5DDBF).withValues(alpha: 0.75);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.03, size.height * 0.06, 58, 46),
        const Radius.circular(8),
      ),
      park,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.87, size.height * 0.72, 52, 36),
        const Radius.circular(8),
      ),
      park,
    );

    final noise = Paint()
      ..color = const Color(0xFFD9CFBA).withValues(alpha: 0.35);
    final random = math.Random(7);
    for (var i = 0; i < 120; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        0.8,
        noise,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
