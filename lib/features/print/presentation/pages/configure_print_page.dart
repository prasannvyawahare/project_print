import 'package:flutter/material.dart';

import '../../../../core/widgets/primary_action_button.dart';
import '../../../../core/widgets/printhub_app_bar.dart';
import '../../../delivery/presentation/pages/order_review_page.dart';
import '../../data/models/print_config_model.dart';
import '../../domain/entities/print_order_data.dart';

double _screenScale(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final widthScale = (size.width / 390).clamp(0.82, 1.0);
  final heightScale = (size.height / 844).clamp(0.82, 1.0);
  return (widthScale * 0.7 + heightScale * 0.3).toDouble();
}

double _r(BuildContext context, double value) => value * _screenScale(context);

class ConfigurePrintPage extends StatefulWidget {
  const ConfigurePrintPage({
    super.key,
    required this.initialOrder,
    this.saveOnlyMode = false,
    this.categoryName,
    this.categoryRate,
    this.printConfigId,
    this.paperQualities,
    this.paperSizes,
  });

  final PrintOrderData initialOrder;
  final bool saveOnlyMode;

  /// Print category selected on the home screen (e.g. "Color A4").
  final String? categoryName;

  /// Per-page rate for the selected category, as returned by the backend.
  final num? categoryRate;

  /// `_id` of the selected print config (from `print-config/get`), used to
  /// match the right config and sent to `order/create`.
  final String? printConfigId;

  /// Paper qualities/sizes for the selected category, sourced from the
  /// `print-config/get` data already loaded on the home screen. Used directly to
  /// populate the dropdowns — this screen makes no network call of its own.
  final List<PaperQualityOption>? paperQualities;
  final List<PaperSizeOption>? paperSizes;

  @override
  State<ConfigurePrintPage> createState() => _ConfigurePrintPageState();
}

class _ConfigurePrintPageState extends State<ConfigurePrintPage> {
  late PrintOrderData _order;
  late final TextEditingController _fromController;
  late final TextEditingController _toController;

  /// Paper sizes/qualities for the selected print category, passed in from the
  /// home screen's `print-config/get` data. No network call is made here.
  late final List<PaperSizeOption> _sizes;
  late final List<PaperQualityOption> _qualities;

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    _fromController = TextEditingController(text: _order.pageFrom.toString());
    _toController = TextEditingController(text: _order.pageTo.toString());
    _initFromConfig();
  }

  /// Populates the dropdowns from the values handed down by the home screen and
  /// resolves the selected quality/size (keeping the saved selection when it
  /// still exists, otherwise defaulting to the first option) so the matching
  /// ids are ready to send to `order/create`.
  void _initFromConfig() {
    _sizes = widget.paperSizes ?? const [];
    _qualities = widget.paperQualities ?? const [];

    final quality = _qualities.firstWhere(
      (q) => q.name == _order.paperQuality,
      orElse: () => _qualities.isEmpty
          ? const PaperQualityOption(id: '', name: '', gsm: '', extra: 0)
          : _qualities.first,
    );
    final size = _sizes.firstWhere(
      (s) => s.name == _order.paperSize,
      orElse: () => _sizes.isEmpty
          ? const PaperSizeOption(id: '', name: '', width: 0, height: 0, extra: 0)
          : _sizes.first,
    );

    _order = _order.copyWith(
      printConfigId: widget.printConfigId?.trim().isNotEmpty == true
          ? widget.printConfigId!.trim()
          : _order.printConfigId,
      paperQuality: _qualities.isEmpty ? _order.paperQuality : quality.name,
      paperQualityId: quality.id,
      paperSize: _sizes.isEmpty ? _order.paperSize : size.name,
      sizeId: size.id,
    );
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
        builder: (_) => OrderReviewPage(initialOrder: _order),
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
            PrintHubAppBar(
              title: 'Configure Print',
              showBack: true,
              onBack: () => Navigator.of(
                context,
              ).pop(widget.saveOnlyMode ? _order : null),
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
                  children: [
                    if (widget.categoryName != null &&
                        widget.categoryName!.isNotEmpty) ...[
                      _CategoryCard(
                        name: widget.categoryName!,
                        rate: widget.categoryRate,
                      ),
                      SizedBox(height: _r(context, 12)),
                    ],
                    _FileCard(document: _order.selectedDocument),
                    SizedBox(height: _r(context, 12)),
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
                                style: TextStyle(
                                  fontSize: _r(context, 30),
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
                    SizedBox(height: _r(context, 10)),
                    // _SectionCard(
                    //   title: 'COLOR MODE',
                    //   child: _ToggleRow(
                    //     leftLabel: 'COLOR',
                    //     rightLabel: 'B&W',
                    //     leftSelected: _order.colorMode == PrintColorMode.color,
                    //     onLeftTap: () => _updateOrder(
                    //       _order.copyWith(colorMode: PrintColorMode.color),
                    //     ),
                    //     onRightTap: () => _updateOrder(
                    //       _order.copyWith(colorMode: PrintColorMode.blackWhite),
                    //     ),
                    //   ),
                    // ),
                    // SizedBox(height: _r(context, 10)),
                    // _SectionCard(
                    //   title: 'PRINT OPTION',
                    //   child: Wrap(
                    //     spacing: 8,
                    //     runSpacing: 8,
                    //     children: [
                    //       _OptionChip(
                    //         label: 'Color',
                    //         selected:
                    //             _order.printOption == PrintServiceOption.color,
                    //         onTap: () => _updateOrder(
                    //           _order.copyWith(
                    //             printOption: PrintServiceOption.color,
                    //           ),
                    //         ),
                    //       ),
                    //       _OptionChip(
                    //         label: 'B&W',
                    //         selected:
                    //             _order.printOption ==
                    //             PrintServiceOption.blackWhite,
                    //         onTap: () => _updateOrder(
                    //           _order.copyWith(
                    //             printOption: PrintServiceOption.blackWhite,
                    //           ),
                    //         ),
                    //       ),
                    //       _OptionChip(
                    //         label: 'Banner',
                    //         selected:
                    //             _order.printOption == PrintServiceOption.banner,
                    //         onTap: () => _updateOrder(
                    //           _order.copyWith(
                    //             printOption: PrintServiceOption.banner,
                    //           ),
                    //         ),
                    //       ),
                    //       _OptionChip(
                    //         label: 'Spiral',
                    //         selected:
                    //             _order.printOption == PrintServiceOption.spiral,
                    //         onTap: () => _updateOrder(
                    //           _order.copyWith(
                    //             printOption: PrintServiceOption.spiral,
                    //           ),
                    //         ),
                    //       ),
                    //       _OptionChip(
                    //         label: 'Other',
                    //         selected:
                    //             _order.printOption == PrintServiceOption.other,
                    //         onTap: () => _updateOrder(
                    //           _order.copyWith(
                    //             printOption: PrintServiceOption.other,
                    //           ),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    // SizedBox(height: _r(context, 10)),
                    _SectionCard(
                      title: 'PAGE RANGE',
                      trailing: Text(
                        'All Pages (1-${_order.totalPages})',
                        style: TextStyle(
                          color: accent,
                          fontSize: _r(context, 12),
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
                    SizedBox(height: _r(context, 10)),
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
                    SizedBox(height: _r(context, 10)),
                    _SectionCard(
                      title: 'PAPER QUALITY',
                      child: _ConfigDropdown(
                        value:
                            _qualities.any(
                              (q) => q.name == _order.paperQuality,
                            )
                            ? _order.paperQuality
                            : null,
                        hint: 'No paper quality available',
                        items: [
                          for (final quality in _qualities)
                            DropdownMenuItem(
                              value: quality.name,
                              child: Text(quality.label),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          final option = _qualities.firstWhere(
                            (q) => q.name == value,
                          );
                          _updateOrder(
                            _order.copyWith(
                              paperQuality: option.name,
                              paperQualityId: option.id,
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: _r(context, 10)),
                    _SectionCard(
                      title: 'PAPER SIZE',
                      child: _ConfigDropdown(
                        value: _sizes.any((s) => s.name == _order.paperSize)
                            ? _order.paperSize
                            : null,
                        hint: 'No paper size available',
                        items: [
                          for (final size in _sizes)
                            DropdownMenuItem(
                              value: size.name,
                              child: Text(size.label),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          final option = _sizes.firstWhere(
                            (s) => s.name == value,
                          );
                          _updateOrder(
                            _order.copyWith(
                              paperSize: option.name,
                              sizeId: option.id,
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: _r(context, 14)),
                    _ProceedButton(
                      onTap: _proceedToDelivery,
                      label: widget.saveOnlyMode
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
    final compact = _screenScale(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12 * compact),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EBF8),
        borderRadius: BorderRadius.circular(24 * compact),
      ),
      child: Row(
        children: [
          Container(
            width: 64 * compact,
            height: 96 * compact,
            decoration: BoxDecoration(
              color: const Color(0xFF2B5565),
              borderRadius: BorderRadius.circular(8 * compact),
            ),
            child: Icon(
              Icons.description_outlined,
              color: Colors.white70,
              size: 32 * compact,
            ),
          ),
          SizedBox(width: 12 * compact),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16 * compact,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF262334),
                  ),
                ),
                SizedBox(height: 3 * compact),
                Text(
                  '${document.formattedSize} • ${document.pageCount} PAGES',
                  style: TextStyle(
                    fontSize: 11.5 * compact,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7A768A),
                  ),
                ),
                SizedBox(height: 6 * compact),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8 * compact,
                    vertical: 4 * compact,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4DDF8),
                    borderRadius: BorderRadius.circular(12 * compact),
                  ),
                  child: Text(
                    'READY TO PRINT',
                    style: TextStyle(
                      color: Color(0xFF4A23CC),
                      fontSize: 10 * compact,
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
    final compact = _screenScale(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        14 * compact,
        12 * compact,
        14 * compact,
        14 * compact,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24 * compact),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Color(0xFF4A465A),
                  fontSize: 13 * compact,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          SizedBox(height: 10 * compact),
          child,
        ],
      ),
    );
  }
}

/// Dropdown styled to match the Configure Print fields, used for the paper
/// quality and paper size options loaded from `print-config/get`.
class _ConfigDropdown extends StatelessWidget {
  const _ConfigDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final String? value;
  final String hint;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0EBF8),
        borderRadius: BorderRadius.circular(_r(context, 10)),
      ),
      padding: EdgeInsets.symmetric(horizontal: _r(context, 10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.expand_more_rounded),
          hint: Text(hint, style: const TextStyle(color: Color(0xFF8B8799))),
          items: items,
          onChanged: items.isEmpty ? null : onChanged,
        ),
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
    final compact = _screenScale(context);
    return Material(
      color: filled ? const Color(0xFF4A23CC) : Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 46 * compact,
          height: 46 * compact,
          child: Icon(
            icon,
            size: 20 * compact,
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
    final compact = _screenScale(context);
    return Material(
      color: selected ? const Color(0xFF4A23CC) : const Color(0xFFE8E2F4),
      borderRadius: BorderRadius.circular(18 * compact),
      child: InkWell(
        borderRadius: BorderRadius.circular(18 * compact),
        onTap: onTap,
        child: SizedBox(
          height: 44 * compact,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF5A5768),
                fontWeight: FontWeight.w800,
                fontSize: 13 * compact,
              ),
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
    final compact = _screenScale(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0EBF8),
        borderRadius: BorderRadius.circular(10 * compact),
      ),
      padding: EdgeInsets.symmetric(horizontal: 10 * compact),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              onSubmitted: onSubmitted,
              onEditingComplete: () => FocusScope.of(context).unfocus(),
              decoration: const InputDecoration(border: InputBorder.none),
              style: TextStyle(
                fontSize: 24 * compact,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 11 * compact,
              color: Color(0xFF8B8799),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProceedButton extends StatelessWidget {
  const _ProceedButton({required this.onTap, required this.label});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    return PrimaryActionButton(
      label: label,
      onPressed: onTap,
      height: 54 * compact,
      borderRadius: 30 * compact,
      fontSize: 16 * compact,
      iconSize: 20 * compact,
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.name, required this.rate});

  final String name;
  final num? rate;

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14 * compact),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24 * compact),
        gradient: const LinearGradient(
          colors: [Color(0xFF4A23CC), Color(0xFF1248E7)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48 * compact,
            height: 48 * compact,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_print_shop_outlined,
              color: Colors.white,
              size: 26 * compact,
            ),
          ),
          SizedBox(width: 12 * compact),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SELECTED SERVICE',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10.5 * compact,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 3 * compact),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18 * compact,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (rate != null && rate! > 0) ...[
            SizedBox(width: 8 * compact),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rs. $rate',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18 * compact,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2 * compact),
                Text(
                  'PER PAGE',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9.5 * compact,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
