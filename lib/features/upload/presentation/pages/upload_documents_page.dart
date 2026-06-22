import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../core/di/injection.dart';
import '../../../delivery/presentation/pages/delivery_address_page.dart';
import '../../../print/domain/entities/print_order_data.dart';
import '../../../print/presentation/bloc/print_flow_bloc.dart';
import '../../../print/presentation/bloc/print_flow_event.dart';
import '../../../print/presentation/bloc/print_flow_state.dart';
import '../../../print/presentation/pages/configure_print_page.dart';
import '../../data/datasources/order_remote_data_source.dart';

double _screenScale(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final widthScale = (size.width / 390).clamp(0.82, 1.0);
  final heightScale = (size.height / 844).clamp(0.82, 1.0);
  return (widthScale * 0.7 + heightScale * 0.3).toDouble();
}

double _r(BuildContext context, double value) => value * _screenScale(context);

class UploadDocumentsPage extends StatefulWidget {
  const UploadDocumentsPage({super.key});

  @override
  State<UploadDocumentsPage> createState() => _UploadDocumentsPageState();
}

class _UploadDocumentsPageState extends State<UploadDocumentsPage> {
  final ImagePicker _imagePicker = ImagePicker();
  late final PrintFlowBloc _flowBloc;
  bool _isCreatingOrder = false;

  @override
  void initState() {
    super.initState();
    _flowBloc = PrintFlowBloc();
  }

  @override
  void dispose() {
    _flowBloc.close();
    super.dispose();
  }

  Future<void> _openConfigureAndSave({PrintDocument? targetItem}) async {
    final state = _flowBloc.state;
    if (targetItem == null && state.files.isEmpty) {
      return;
    }

    final item = targetItem ?? state.files.first;
    final initialOrder = state.buildOrderForFile(item);
    final updatedOrder = await Navigator.of(context).push<PrintOrderData>(
      MaterialPageRoute<PrintOrderData>(
        builder: (_) =>
            ConfigurePrintPage(initialOrder: initialOrder, saveOnlyMode: true),
      ),
    );

    if (!mounted || updatedOrder == null) {
      return;
    }

    _flowBloc.add(
      PrintFlowFileConfigSaved(
        path: item.path,
        config: FilePrintConfiguration(
          copies: updatedOrder.copies,
          colorMode: updatedOrder.colorMode,
          pageFrom: updatedOrder.pageFrom,
          pageTo: updatedOrder.pageTo,
          orientation: updatedOrder.orientation,
          paperSize: updatedOrder.paperSize,
          printOption: updatedOrder.printOption,
        ),
      ),
    );
  }

  Future<void> _configureEachAddedFile(List<PrintDocument> files) async {
    for (final file in files) {
      if (!mounted) {
        return;
      }
      await _openConfigureAndSave(targetItem: file);
    }
  }

  Future<void> _pickFromFileManager() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );

    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }

    final nextItems = result.files
        .where((file) => file.path != null)
        .map(
          (file) => PrintDocument(
            path: file.path!,
            name: file.name,
            sizeInBytes: file.size,
            pageCount: _inferPageCount(file.name, file.size),
          ),
        )
        .toList();

    if (nextItems.isEmpty) {
      return;
    }

    _flowBloc.add(PrintFlowFilesAdded(nextItems));
    await _configureEachAddedFile(nextItems);
  }

  Future<void> _pickFromCamera() async {
    final photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 92,
    );

    if (!mounted || photo == null) {
      return;
    }

    final item = await _buildItemFromPath(photo.path);
    if (item == null) {
      return;
    }

    _flowBloc.add(PrintFlowFilesAdded([item]));

    await _openConfigureAndSave(targetItem: item);
  }

  Future<void> _pickFromGallery() async {
    final photos = await _imagePicker.pickMultiImage(imageQuality: 92);

    if (!mounted) {
      return;
    }

    if (photos.isEmpty) {
      final singlePhoto = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );
      if (singlePhoto == null || !mounted) {
        return;
      }
      final singleItem = await _buildItemFromPath(singlePhoto.path);
      if (singleItem == null) {
        return;
      }
      _flowBloc.add(PrintFlowFilesAdded([singleItem]));
      await _configureEachAddedFile([singleItem]);
      return;
    }

    final items = <PrintDocument>[];
    for (final photo in photos) {
      final item = await _buildItemFromPath(photo.path);
      if (item != null) {
        items.add(item);
      }
    }

    if (items.isEmpty) {
      return;
    }

    _flowBloc.add(PrintFlowFilesAdded(items));
    await _configureEachAddedFile(items);
  }

  Future<PrintDocument?> _buildItemFromPath(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return null;
    }

    final stat = await file.stat();
    final name = _fileNameFromPath(path);
    return PrintDocument(
      path: path,
      name: name,
      sizeInBytes: stat.size,
      pageCount: _inferPageCount(name, stat.size),
    );
  }

  int _inferPageCount(String fileName, int sizeInBytes) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) {
      final estimate = (sizeInBytes / (1024 * 400)).round();
      return estimate.clamp(1, 120);
    }
    if (_isImageName(fileName)) {
      return 1;
    }
    final estimate = (sizeInBytes / (1024 * 700)).round();
    return estimate.clamp(1, 80);
  }

  bool _isImageName(String fileName) {
    final lower = fileName.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }

  String _fileNameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.split('/').last;
  }

  void _removeItem(PrintDocument item) {
    _flowBloc.add(PrintFlowFileRemoved(item.path));
  }

  Future<void> _viewItem(PrintDocument item) async {
    _flowBloc.add(PrintFlowDetailsToggled(item.path));
  }

  Future<void> _openDocument(PrintDocument item) async {
    final result = await OpenFilex.open(item.path);
    if (!mounted) {
      return;
    }

    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message.isEmpty
                ? 'Unable to open ${item.name}'
                : result.message,
          ),
        ),
      );
    }
  }

  Future<void> _showAddOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: const Text('File Manager'),
                  subtitle: const Text('Pick PDF, DOCX or images'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickFromFileManager();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Camera'),
                  subtitle: const Text('Capture a new photo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickFromCamera();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Gallery'),
                  subtitle: const Text('Select from existing photos'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickFromGallery();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _goToNextStep() async {
    if (_isCreatingOrder) {
      return;
    }

    final state = _flowBloc.state;
    if (state.files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one file to continue.'),
        ),
      );
      return;
    }

    if (state.lastOrder == null) {
      await _openConfigureAndSave(targetItem: state.files.first);
      if (!mounted || _flowBloc.state.lastOrder == null) {
        return;
      }
    }

    final mergedOrder = _flowBloc.state.buildMergedOrder();
    if (mergedOrder == null) {
      return;
    }

    final orderItems = _buildOrderItems(state);

    setState(() {
      _isCreatingOrder = true;
    });

    try {
      final orderId = await sl<OrderRemoteDataSource>().createOrder(
        items: orderItems,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              DeliveryAddressPage(initialOrder: mergedOrder, orderId: orderId),
        ),
      );
    } on OrderCreateException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingOrder = false;
        });
      }
    }
  }

  List<OrderCreateItem> _buildOrderItems(PrintFlowState state) {
    return state.files.map((file) {
      final config = state.configurations[file.path] ?? state.configFor(file);
      return OrderCreateItem(
        fileName: file.name,
        fileType: _fileTypeFor(file.name),
        numberOfCopy: config.copies,
        samePage: config.pageFrom == config.pageTo,
        printType: _printTypeFor(config),
      );
    }).toList();
  }

  String _fileTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    final dotIndex = lower.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == lower.length - 1) {
      return 'unknown';
    }
    return lower.substring(dotIndex + 1);
  }

  String _printTypeFor(FilePrintConfiguration config) {
    final paperSize = switch (config.paperSize) {
      'A4 (Standard)' => 'A4',
      'A3' => 'A3',
      'Letter' => 'Letter',
      _ => config.paperSize,
    };

    return switch (config.printOption) {
      PrintServiceOption.color => 'COLOR $paperSize',
      PrintServiceOption.blackWhite => 'B&W $paperSize',
      PrintServiceOption.banner => 'BANNER',
      PrintServiceOption.spiral => 'SPIRAL',
      PrintServiceOption.other => paperSize,
    };
  }

  @override
  Widget build(BuildContext context) {
    const pageBackground = Color(0xFFF5F2FA);
    const titleColor = Color(0xFF1F1F2E);
    const accent = Color(0xFF3E34D3);

    return BlocProvider.value(
      value: _flowBloc,
      child: Scaffold(
        backgroundColor: pageBackground,
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
                        'Upload Documents',
                        style: TextStyle(
                          fontSize: _r(context, 19),
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.search_rounded, size: _r(context, 22)),
                      color: const Color(0xFF1E2433),
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
                child: BlocBuilder<PrintFlowBloc, PrintFlowState>(
                  builder: (context, state) => SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      _r(context, 18),
                      _r(context, 18),
                      _r(context, 18),
                      _r(context, 14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STEP 01',
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
                              fontSize: _r(context, 38),
                              height: 1.05,
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                            ),
                            children: const [
                              TextSpan(text: 'Select your '),
                              TextSpan(
                                text: 'Precision',
                                style: TextStyle(color: Color(0xFF1B43D4)),
                              ),
                              TextSpan(text: '\nfiles.'),
                            ],
                          ),
                        ),
                        SizedBox(height: _r(context, 18)),
                        Row(
                          children: [
                            Expanded(
                              child: _UploadSourceCard(
                                icon: Icons.folder_outlined,
                                iconColor: const Color(0xFF5E36D4),
                                title: 'File Manager',
                                subtitle: 'Local storage',
                                onTap: _pickFromFileManager,
                              ),
                            ),
                            SizedBox(width: _r(context, 12)),
                            Expanded(
                              child: _UploadSourceCard(
                                icon: Icons.photo_camera_outlined,
                                iconColor: const Color(0xFF1D4FD2),
                                title: 'Camera',
                                subtitle: 'Capture now',
                                onTap: _pickFromCamera,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: _r(context, 12)),
                        _RecentFilesCard(onTap: _pickFromGallery),
                        SizedBox(height: _r(context, 18)),
                        Row(
                          children: [
                            Text(
                              'Selected Files',
                              style: TextStyle(
                                fontSize: _r(context, 20),
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${state.files.length} ITEMS',
                              style: TextStyle(
                                fontSize: _r(context, 14),
                                fontWeight: FontWeight.w800,
                                color: accent.withValues(alpha: 0.95),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: _r(context, 10)),
                        if (state.lastOrder != null)
                          Container(
                            width: double.infinity,
                            margin: EdgeInsets.only(bottom: _r(context, 10)),
                            padding: EdgeInsets.symmetric(
                              horizontal: _r(context, 12),
                              vertical: _r(context, 10),
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE6FA),
                              borderRadius: BorderRadius.circular(
                                _r(context, 14),
                              ),
                            ),
                            child: Text(
                              'Configured flow is active for ${state.configurations.length}/${state.files.length} files',
                              style: TextStyle(
                                color: Color(0xFF4A23CC),
                                fontSize: _r(context, 12),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        if (state.files.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(_r(context, 16)),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                _r(context, 20),
                              ),
                            ),
                            child: Text(
                              'No files selected yet. Use File Manager, Camera or Gallery.',
                              style: TextStyle(
                                color: Color(0xFF6A667A),
                                fontSize: _r(context, 13),
                              ),
                            ),
                          ),
                        ...state.files.map(
                          (item) => Padding(
                            padding: EdgeInsets.only(bottom: _r(context, 10)),
                            child: Column(
                              children: [
                                _SelectedFileCard(
                                  item: item,
                                  pageCount: state.configFor(item).pageTo,
                                  configured: state.isConfigured(item.path),
                                  onView: () => _viewItem(item),
                                  onRemove: () => _removeItem(item),
                                ),
                                if (state.expandedPath == item.path)
                                  _FileConfigDetails(
                                    config: state.configFor(item),
                                    onEdit: () =>
                                        _openConfigureAndSave(targetItem: item),
                                    onOpenDoc: () => _openDocument(item),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: _r(context, 6)),
                        _AddFileCard(onTap: _showAddOptions),
                      ],
                    ),
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
            _r(context, 18),
          ),
          child: SizedBox(
            height: _r(context, 54),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_r(context, 28)),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A23CC), Color(0xFF1248E7)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF1F31B6).withValues(alpha: 0.28),
                    blurRadius: _r(context, 16),
                    offset: Offset(0, _r(context, 7)),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(_r(context, 28)),
                  onTap: _isCreatingOrder ? null : _goToNextStep,
                  child: Center(
                    child: _isCreatingOrder
                        ? SizedBox(
                            width: _r(context, 22),
                            height: _r(context, 22),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue to Print',
                                style: TextStyle(
                                  fontSize: _r(context, 17),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: _r(context, 6)),
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
    );
  }
}

class _FileConfigDetails extends StatelessWidget {
  const _FileConfigDetails({
    required this.config,
    required this.onEdit,
    required this.onOpenDoc,
  });

  final FilePrintConfiguration config;
  final VoidCallback onEdit;
  final VoidCallback onOpenDoc;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1ECFA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'File Configuration',
            style: TextStyle(
              color: Color(0xFF4A23CC),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Copies: ${config.copies}   '
            'Color: ${config.colorMode == PrintColorMode.color ? 'Color' : 'B&W'}',
            style: const TextStyle(color: Color(0xFF4B475A), fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            'Range: ${config.pageFrom}-${config.pageTo}   '
            'Orientation: ${config.orientation == PrintOrientation.portrait ? 'Portrait' : 'Landscape'}',
            style: const TextStyle(color: Color(0xFF4B475A), fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            'Paper: ${config.paperSize}',
            style: const TextStyle(color: Color(0xFF4B475A), fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            'Print Option: ${switch (config.printOption) {
              PrintServiceOption.color => 'Color',
              PrintServiceOption.blackWhite => 'B&W',
              PrintServiceOption.banner => 'Banner',
              PrintServiceOption.spiral => 'Spiral',
              PrintServiceOption.other => 'Other',
            }}',
            style: const TextStyle(color: Color(0xFF4B475A), fontSize: 14),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton(
                onPressed: onEdit,
                child: const Text('Edit Config'),
              ),
              const SizedBox(width: 10),
              TextButton(onPressed: onOpenDoc, child: const Text('Open File')),
            ],
          ),
        ],
      ),
    );
  }
}

class _UploadSourceCard extends StatelessWidget {
  const _UploadSourceCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22 * compact),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22 * compact),
        child: Container(
          padding: EdgeInsets.all(14 * compact),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22 * compact),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF161426).withValues(alpha: 0.05),
                blurRadius: 8 * compact,
                offset: Offset(0, 3 * compact),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56 * compact,
                height: 56 * compact,
                decoration: const BoxDecoration(
                  color: Color(0xFFE4DDF8),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28 * compact, color: iconColor),
              ),
              SizedBox(height: 18 * compact),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16 * compact,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF222232),
                ),
              ),
              SizedBox(height: 3 * compact),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12 * compact,
                  color: Color(0xFF585568),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentFilesCard extends StatelessWidget {
  const _RecentFilesCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    return Material(
      color: const Color(0xFFEFEAF8),
      borderRadius: BorderRadius.circular(22 * compact),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22 * compact),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: 14 * compact,
            vertical: 12 * compact,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18 * compact,
                backgroundColor: Color(0xFFCBD1DF),
                child: Icon(
                  Icons.photo_library_outlined,
                  color: Color(0xFF49505C),
                  size: 22 * compact,
                ),
              ),
              SizedBox(width: 12 * compact),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gallery',
                      style: TextStyle(
                        fontSize: 16 * compact,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF232332),
                      ),
                    ),
                    SizedBox(height: 2 * compact),
                    Text(
                      'Choose images from your gallery',
                      style: TextStyle(
                        fontSize: 12 * compact,
                        color: Color(0xFF5C596A),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 24 * compact,
                color: Color(0xFF767084),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedFileCard extends StatelessWidget {
  const _SelectedFileCard({
    required this.item,
    required this.pageCount,
    required this.configured,
    required this.onView,
    required this.onRemove,
  });

  final PrintDocument item;
  final int pageCount;
  final bool configured;
  final VoidCallback onView;
  final VoidCallback onRemove;

  bool get _isImage {
    final lower = item.name.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12 * compact),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24 * compact),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20 * compact),
                child: Container(
                  width: 84 * compact,
                  height: 84 * compact,
                  color: const Color(0xFF101C29),
                  child: _isImage
                      ? Image.file(File(item.path), fit: BoxFit.cover)
                      : Icon(
                          Icons.description_outlined,
                          color: Colors.white,
                          size: 32 * compact,
                        ),
                ),
              ),
              Positioned(
                left: -7,
                top: -7,
                child: Container(
                  width: 30 * compact,
                  height: 30 * compact,
                  decoration: BoxDecoration(
                    color: configured
                        ? const Color(0xFF22A05B)
                        : const Color(0xFFA9A3B8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    configured ? Icons.check_rounded : Icons.pending_outlined,
                    color: Colors.white,
                    size: configured ? 16 * compact : 15 * compact,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 12 * compact),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16 * compact,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF252432),
                  ),
                ),
                SizedBox(height: 3 * compact),
                Text(
                  '${item.formattedSize} • $pageCount pages',
                  style: TextStyle(
                    fontSize: 12 * compact,
                    color: Color(0xFF575365),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8 * compact),
          _ActionCircle(
            icon: Icons.remove_red_eye_outlined,
            iconColor: const Color(0xFF53505E),
            onTap: onView,
          ),
          SizedBox(width: 8 * compact),
          _ActionCircle(
            icon: Icons.delete_outline_rounded,
            iconColor: const Color(0xFFC32222),
            onTap: onRemove,
          ),
        ],
      ),
    );
  }
}

class _ActionCircle extends StatelessWidget {
  const _ActionCircle({
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    return Material(
      color: const Color(0xFFF1ECF8),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 46 * compact,
          height: 46 * compact,
          child: Icon(icon, size: 24 * compact, color: iconColor),
        ),
      ),
    );
  }
}

class _AddFileCard extends StatelessWidget {
  const _AddFileCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 22 * compact),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24 * compact),
          border: Border.all(color: const Color(0xFFD8D2E3), width: 2),
        ),
        child: Column(
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              size: 40 * compact,
              color: Color(0xFF7B768A),
            ),
            SizedBox(height: 8 * compact),
            Text(
              'Add another file',
              style: TextStyle(
                fontSize: 16 * compact,
                fontWeight: FontWeight.w600,
                color: Color(0xFF777184),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
