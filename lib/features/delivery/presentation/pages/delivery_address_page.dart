import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../print/domain/entities/print_order_data.dart';

double _screenScale(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final widthScale = (size.width / 390).clamp(0.82, 1.0);
  final heightScale = (size.height / 844).clamp(0.82, 1.0);
  return (widthScale * 0.7 + heightScale * 0.3).toDouble();
}

double _r(BuildContext context, double value) => value * _screenScale(context);

class DeliveryAddressPage extends StatefulWidget {
  const DeliveryAddressPage({super.key, required this.initialOrder});

  final PrintOrderData initialOrder;

  @override
  State<DeliveryAddressPage> createState() => _DeliveryAddressPageState();
}

class _DeliveryAddressPageState extends State<DeliveryAddressPage> {
  late PrintOrderData _order;

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
  }

  Future<void> _selectLocationFromMap() async {
    final result = await showDialog<_MapSelectionResult>(
      context: context,
      builder: (_) =>
          _MapSelectionDialog(initialAddress: _order.currentDeliveryAddress),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _order = _order.copyWith(
        selectedLocationAddress: result.address,
        isLocationConfirmed: true,
        homeAddress: _order.deliveryAddressType == DeliveryAddressType.home
            ? result.address
            : _order.homeAddress,
        officeAddress: _order.deliveryAddressType == DeliveryAddressType.office
            ? result.address
            : _order.officeAddress,
      );
    });
  }

  Future<void> _addOrUpdateAddress() async {
    final initialType = _order.deliveryAddressType;
    final controller = TextEditingController(
      text: _order.currentDeliveryAddress,
    );
    var tempType = initialType;

    final didSave = await showModalBottomSheet<bool>(
      context: context,
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
                    'Add or Update Address',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F1F2E),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    children: [
                      ChoiceChip(
                        label: const Text('Home'),
                        selected: tempType == DeliveryAddressType.home,
                        onSelected: (_) {
                          setSheetState(() {
                            tempType = DeliveryAddressType.home;
                            controller.text = _order.homeAddress;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Office'),
                        selected: tempType == DeliveryAddressType.office,
                        onSelected: (_) {
                          setSheetState(() {
                            tempType = DeliveryAddressType.office;
                            controller.text = _order.officeAddress;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Enter complete address',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final value = controller.text.trim();
                        if (value.isEmpty) {
                          return;
                        }
                        setState(() {
                          _order = _order.copyWith(
                            deliveryAddressType: tempType,
                            homeAddress: tempType == DeliveryAddressType.home
                                ? value
                                : _order.homeAddress,
                            officeAddress:
                                tempType == DeliveryAddressType.office
                                ? value
                                : _order.officeAddress,
                          );
                        });
                        Navigator.of(sheetContext).pop(true);
                      },
                      child: const Text('Save Address'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    controller.dispose();

    if (didSave == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address updated successfully')),
      );
    }
  }

  void _selectAddressType(DeliveryAddressType type) {
    setState(() {
      _order = _order.copyWith(deliveryAddressType: type);
    });
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF3E34D3);

    return Scaffold(
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
                        color: Color(0xFF1F1F2E),
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
                    SizedBox(height: _r(context, 12)),
                    _MapCard(
                      isConfirming: !_order.isLocationConfirmed,
                      onChangeTap: _selectLocationFromMap,
                    ),
                    SizedBox(height: _r(context, 16)),
                    Row(
                      children: [
                        Text(
                          'Saved Locations',
                          style: TextStyle(
                            fontSize: _r(context, 20),
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF21202D),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _addOrUpdateAddress,
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
                    _AddressCard(
                      type: DeliveryAddressType.home,
                      icon: Icons.home_filled,
                      title: 'Home',
                      address: _order.homeAddress,
                      selected:
                          _order.deliveryAddressType ==
                          DeliveryAddressType.home,
                      onTap: () => _selectAddressType(DeliveryAddressType.home),
                    ),
                    SizedBox(height: _r(context, 10)),
                    _AddressCard(
                      type: DeliveryAddressType.office,
                      icon: Icons.work_outline_rounded,
                      title: 'Office',
                      address: _order.officeAddress,
                      selected:
                          _order.deliveryAddressType ==
                          DeliveryAddressType.office,
                      onTap: () =>
                          _selectAddressType(DeliveryAddressType.office),
                    ),
                    SizedBox(height: _r(context, 18)),
                    Text(
                      'Delivery Speed',
                      style: TextStyle(
                        fontSize: _r(context, 20),
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF21202D),
                      ),
                    ),
                    SizedBox(height: _r(context, 8)),
                    _SpeedCard(),
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
                    color: Color(0xFF3B3949),
                  ),
                ),
                Spacer(),
                Text(
                  '\$12.50',
                  style: TextStyle(
                    fontSize: _r(context, 22),
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1B27),
                  ),
                ),
              ],
            ),
            SizedBox(height: _r(context, 10)),
            SizedBox(
              width: double.infinity,
              height: _r(context, 54),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_r(context, 30)),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A23CC), Color(0xFF1248E7)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1F31B6).withValues(alpha: 0.24),
                      blurRadius: _r(context, 14),
                      offset: Offset(0, _r(context, 6)),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(_r(context, 30)),
                    onTap: () {},
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Proceed to Payment',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _r(context, 17),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: _r(context, 8)),
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
          ],
        ),
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({required this.isConfirming, required this.onChangeTap});

  final bool isConfirming;
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
                    Icon(
                      Icons.gps_fixed,
                      color: Color(0xFF4A23CC),
                      size: 16 * compact,
                    ),
                    SizedBox(width: 8 * compact),
                    Expanded(
                      child: Text(
                        isConfirming
                            ? 'Confirming location...'
                            : 'Location selected',
                        style: TextStyle(
                          fontSize: 14 * compact,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF252432),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onChangeTap,
                      borderRadius: BorderRadius.circular(8 * compact),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6 * compact,
                          vertical: 4 * compact,
                        ),
                        child: Text(
                          'CHANGE',
                          style: TextStyle(
                            color: Color(0xFF4A23CC),
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
    required this.type,
    required this.icon,
    required this.title,
    required this.address,
    required this.selected,
    required this.onTap,
  });

  final DeliveryAddressType type;
  final IconData icon;
  final String title;
  final String address;
  final bool selected;
  final VoidCallback onTap;

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
                      title,
                      style: TextStyle(
                        fontSize: 15 * compact,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF252432),
                        height: 1.0,
                      ),
                    ),
                    SizedBox(height: 5 * compact),
                    Text(
                      address,
                      style: TextStyle(
                        fontSize: 13 * compact,
                        color: Color(0xFF4F4C5D),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6 * compact),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected
                    ? const Color(0xFF4A23CC)
                    : const Color(0xFFB4AEC6),
                size: 26 * compact,
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

class _MapSelectionResult {
  const _MapSelectionResult({required this.address});

  final String address;
}

class _MapSelectionDialog extends StatefulWidget {
  const _MapSelectionDialog({required this.initialAddress});

  final String initialAddress;

  @override
  State<_MapSelectionDialog> createState() => _MapSelectionDialogState();
}

class _MapSelectionDialogState extends State<_MapSelectionDialog> {
  Offset _pin = const Offset(0.5, 0.5);

  String _buildAddress() {
    final lat = 51.50 + (_pin.dy - 0.5) * 0.06;
    final lng = -0.12 + (_pin.dx - 0.5) * 0.08;
    final block = (100 + (_pin.dx * 200)).round();
    return '$block Market Street, London (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
  }

  @override
  Widget build(BuildContext context) {
    final address = _buildAddress();

    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(Icons.map_outlined, color: Color(0xFF4A23CC)),
                SizedBox(width: 8),
                Text(
                  'Select location on map',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F1F2E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1.35,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onTapDown: (details) {
                      setState(() {
                        _pin = Offset(
                          (details.localPosition.dx / constraints.maxWidth)
                              .clamp(0.0, 1.0),
                          (details.localPosition.dy / constraints.maxHeight)
                              .clamp(0.0, 1.0),
                        );
                      });
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(painter: _MapPatternPainter()),
                          ),
                          Positioned(
                            left: _pin.dx * constraints.maxWidth - 16,
                            top: _pin.dy * constraints.maxHeight - 32,
                            child: const Icon(
                              Icons.location_on,
                              size: 32,
                              color: Color(0xFF4A23CC),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                address,
                style: const TextStyle(fontSize: 14, color: Color(0xFF4A465A)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(_MapSelectionResult(address: address)),
          child: const Text('Use this location'),
        ),
      ],
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
