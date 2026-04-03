import 'package:flutter/material.dart';

import '../../../delivery/presentation/pages/delivery_address_page.dart';
import '../../domain/entities/print_order_data.dart';

class ConfigurePrintPage extends StatefulWidget {
  const ConfigurePrintPage({
    super.key,
    required this.initialOrder,
    this.saveOnlyMode = false,
  });

  final PrintOrderData initialOrder;
  final bool saveOnlyMode;

  @override
  State<ConfigurePrintPage> createState() => _ConfigurePrintPageState();
}

class _ConfigurePrintPageState extends State<ConfigurePrintPage> {
  late PrintOrderData _order;
  late final TextEditingController _fromController;
  late final TextEditingController _toController;

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    _fromController = TextEditingController(text: _order.pageFrom.toString());
    _toController = TextEditingController(text: _order.pageTo.toString());
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _updateOrder(PrintOrderData value) {
    setState(() {
      _order = value;
    });
  }

  void _updatePageRange() {
    final from = int.tryParse(_fromController.text.trim());
    final to = int.tryParse(_toController.text.trim());

    final maxPage = _order.totalPages;
    final safeFrom = (from ?? _order.pageFrom).clamp(1, maxPage);
    final safeTo = (to ?? _order.pageTo).clamp(1, maxPage);

    _updateOrder(
      _order.copyWith(
        pageFrom: safeFrom <= safeTo ? safeFrom : safeTo,
        pageTo: safeTo >= safeFrom ? safeTo : safeFrom,
      ),
    );

    _fromController.text = _order.pageFrom.toString();
    _toController.text = _order.pageTo.toString();
  }

  void _proceedToDelivery() {
    _updatePageRange();
    if (widget.saveOnlyMode) {
      Navigator.of(context).pop(_order);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DeliveryAddressPage(initialOrder: _order),
      ),
    );
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
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(widget.saveOnlyMode ? _order : null),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: accent,
                  ),
                  const Expanded(
                    child: Text(
                      'Configure Print',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F1F2E),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_none_rounded),
                    color: const Color(0xFF1E2433),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                child: Column(
                  children: [
                    _FileCard(document: _order.selectedDocument),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'NUMBER OF COPIES',
                      child: Row(
                        children: [
                          _RoundButton(
                            icon: Icons.remove,
                            filled: false,
                            onTap: () {
                              if (_order.copies > 1) {
                                _updateOrder(
                                  _order.copyWith(copies: _order.copies - 1),
                                );
                              }
                            },
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                _order.copies.toString().padLeft(2, '0'),
                                style: const TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF272434),
                                ),
                              ),
                            ),
                          ),
                          _RoundButton(
                            icon: Icons.add,
                            filled: true,
                            onTap: () {
                              _updateOrder(
                                _order.copyWith(copies: _order.copies + 1),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'COLOR MODE',
                      child: _ToggleRow(
                        leftLabel: 'COLOR',
                        rightLabel: 'B&W',
                        leftSelected: _order.colorMode == PrintColorMode.color,
                        onLeftTap: () => _updateOrder(
                          _order.copyWith(colorMode: PrintColorMode.color),
                        ),
                        onRightTap: () => _updateOrder(
                          _order.copyWith(colorMode: PrintColorMode.blackWhite),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'PRINT OPTION',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _OptionChip(
                            label: 'Color',
                            selected:
                                _order.printOption == PrintServiceOption.color,
                            onTap: () => _updateOrder(
                              _order.copyWith(
                                printOption: PrintServiceOption.color,
                              ),
                            ),
                          ),
                          _OptionChip(
                            label: 'B&W',
                            selected:
                                _order.printOption ==
                                PrintServiceOption.blackWhite,
                            onTap: () => _updateOrder(
                              _order.copyWith(
                                printOption: PrintServiceOption.blackWhite,
                              ),
                            ),
                          ),
                          _OptionChip(
                            label: 'Banner',
                            selected:
                                _order.printOption == PrintServiceOption.banner,
                            onTap: () => _updateOrder(
                              _order.copyWith(
                                printOption: PrintServiceOption.banner,
                              ),
                            ),
                          ),
                          _OptionChip(
                            label: 'Spiral',
                            selected:
                                _order.printOption == PrintServiceOption.spiral,
                            onTap: () => _updateOrder(
                              _order.copyWith(
                                printOption: PrintServiceOption.spiral,
                              ),
                            ),
                          ),
                          _OptionChip(
                            label: 'Other',
                            selected:
                                _order.printOption == PrintServiceOption.other,
                            onTap: () => _updateOrder(
                              _order.copyWith(
                                printOption: PrintServiceOption.other,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'PAGE RANGE',
                      trailing: Text(
                        'All Pages (1-${_order.totalPages})',
                        style: const TextStyle(
                          color: accent,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _RangeField(
                              controller: _fromController,
                              label: 'FROM',
                              onSubmitted: (_) => _updatePageRange(),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '-',
                              style: TextStyle(
                                fontSize: 30,
                                color: Color(0xFFB0AABF),
                              ),
                            ),
                          ),
                          Expanded(
                            child: _RangeField(
                              controller: _toController,
                              label: 'TO',
                              onSubmitted: (_) => _updatePageRange(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'ORIENTATION',
                      child: _ToggleRow(
                        leftLabel: 'PORTRAIT',
                        rightLabel: 'LANDSCAPE',
                        leftSelected:
                            _order.orientation == PrintOrientation.portrait,
                        onLeftTap: () => _updateOrder(
                          _order.copyWith(
                            orientation: PrintOrientation.portrait,
                          ),
                        ),
                        onRightTap: () => _updateOrder(
                          _order.copyWith(
                            orientation: PrintOrientation.landscape,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'PAPER SIZE',
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0EBF8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _order.paperSize,
                            isExpanded: true,
                            icon: const Icon(Icons.expand_more_rounded),
                            items: const [
                              DropdownMenuItem(
                                value: 'A4 (Standard)',
                                child: Text('A4 (Standard)'),
                              ),
                              DropdownMenuItem(value: 'A3', child: Text('A3')),
                              DropdownMenuItem(
                                value: 'Letter',
                                child: Text('Letter'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              _updateOrder(_order.copyWith(paperSize: value));
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _TotalCard(
                      total: _order.estimatedTotalUsd,
                      onTap: _proceedToDelivery,
                      buttonLabel: widget.saveOnlyMode
                          ? 'Save Configuration'
                          : 'Proceed to Delivery',
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

class _FileCard extends StatelessWidget {
  const _FileCard({required this.document});

  final PrintDocument document;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EBF8),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Container(
            width: 78,
            height: 118,
            decoration: BoxDecoration(
              color: const Color(0xFF2B5565),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: Colors.white70,
              size: 40,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF262334),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${document.formattedSize} • ${document.pageCount} PAGES',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7A768A),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4DDF8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'READY TO PRINT',
                    style: TextStyle(
                      color: Color(0xFF4A23CC),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF4A465A),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? const Color(0xFF4A23CC) : Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(
            icon,
            color: filled ? Colors.white : const Color(0xFF5E37D4),
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.leftLabel,
    required this.rightLabel,
    required this.leftSelected,
    required this.onLeftTap,
    required this.onRightTap,
  });

  final String leftLabel;
  final String rightLabel;
  final bool leftSelected;
  final VoidCallback onLeftTap;
  final VoidCallback onRightTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ToggleButton(
            label: leftLabel,
            selected: leftSelected,
            onTap: onLeftTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ToggleButton(
            label: rightLabel,
            selected: !leftSelected,
            onTap: onRightTap,
          ),
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF4A23CC) : const Color(0xFFE8E2F4),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: SizedBox(
          height: 54,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF5A5768),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF4A23CC) : const Color(0xFFE8E2F4),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF59566B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _RangeField extends StatelessWidget {
  const _RangeField({
    required this.controller,
    required this.label,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0EBF8),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              onSubmitted: onSubmitted,
              onEditingComplete: () => FocusScope.of(context).unfocus(),
              decoration: const InputDecoration(border: InputBorder.none),
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF8B8799),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.total,
    required this.onTap,
    required this.buttonLabel,
  });

  final double total;
  final VoidCallback onTap;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'ESTIMATED TOTAL',
                style: TextStyle(
                  color: Color(0xFF666275),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Text(
                'EARN ${(total * 1).round()} POINTS',
                style: const TextStyle(
                  color: Color(0xFF1A56DD),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4A23CC),
                ),
              ),
              const SizedBox(width: 8),
              const Text('USD', style: TextStyle(color: Color(0xFF6E6A7F))),
              const Spacer(),
              const Text(
                'Includes priority handling',
                style: TextStyle(color: Color(0xFF7D788D)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 66,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A23CC), Color(0xFF1248E7)],
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(36),
                  onTap: onTap,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        buttonLabel,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                      ),
                    ],
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
