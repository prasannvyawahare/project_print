import 'package:equatable/equatable.dart';

import '../../domain/entities/print_order_data.dart';

class PrintFlowState extends Equatable {
  const PrintFlowState({
    this.files = const [],
    this.configurations = const {},
    this.expandedPath,
    this.lastOrder,
  });

  final List<PrintDocument> files;
  final Map<String, FilePrintConfiguration> configurations;
  final String? expandedPath;
  final PrintOrderData? lastOrder;

  bool isConfigured(String path) => configurations.containsKey(path);

  FilePrintConfiguration configFor(PrintDocument file) {
    return configurations[file.path] ??
        FilePrintConfiguration(
          copies: 1,
          colorMode: PrintColorMode.color,
          pageFrom: 1,
          pageTo: file.pageCount,
          orientation: PrintOrientation.portrait,
          paperSize: 'A4 (Standard)',
          printOption: PrintServiceOption.color,
        );
  }

  PrintOrderData buildOrderForFile(PrintDocument file) {
    final config = configFor(file);
    return PrintOrderData(
      documents: [file],
      copies: config.copies,
      colorMode: config.colorMode,
      pageFrom: config.pageFrom.clamp(1, file.pageCount),
      pageTo: config.pageTo.clamp(1, file.pageCount),
      orientation: config.orientation,
      paperSize: config.paperSize,
      printOption: config.printOption,
      deliveryAddressType:
          lastOrder?.deliveryAddressType ?? DeliveryAddressType.home,
      homeAddress:
          lastOrder?.homeAddress ?? '221B Baker Street, London, NW1 6XE',
      officeAddress:
          lastOrder?.officeAddress ?? 'Tech Hub Tower, 4th Floor, Suite 402',
      selectedLocationAddress: lastOrder?.selectedLocationAddress,
      isLocationConfirmed: lastOrder?.isLocationConfirmed ?? false,
      estimatedTotalUsd: lastOrder?.estimatedTotalUsd ?? 12.40,
    );
  }

  PrintOrderData? buildMergedOrder() {
    if (files.isEmpty) {
      return null;
    }

    final selectedIndex = (lastOrder?.selectedDocumentIndex ?? 0).clamp(
      0,
      files.length - 1,
    );
    final selectedFile = files[selectedIndex];
    final selectedConfig = configFor(selectedFile);

    var estimatedTotal = 0.0;
    for (final file in files) {
      final config = configFor(file);
      final rate = switch (config.printOption) {
        PrintServiceOption.color => 0.25,
        PrintServiceOption.blackWhite => 0.10,
        PrintServiceOption.banner => 0.55,
        PrintServiceOption.spiral => 0.40,
        PrintServiceOption.other => 0.30,
      };
      final pages = (config.pageTo - config.pageFrom + 1).clamp(
        1,
        file.pageCount,
      );
      estimatedTotal += pages * config.copies * rate;
    }

    return PrintOrderData(
      documents: files,
      selectedDocumentIndex: selectedIndex,
      copies: selectedConfig.copies,
      colorMode: selectedConfig.colorMode,
      pageFrom: selectedConfig.pageFrom.clamp(1, selectedFile.pageCount),
      pageTo: selectedConfig.pageTo.clamp(1, selectedFile.pageCount),
      orientation: selectedConfig.orientation,
      paperSize: selectedConfig.paperSize,
      printOption: selectedConfig.printOption,
      deliveryAddressType:
          lastOrder?.deliveryAddressType ?? DeliveryAddressType.home,
      homeAddress:
          lastOrder?.homeAddress ?? '221B Baker Street, London, NW1 6XE',
      officeAddress:
          lastOrder?.officeAddress ?? 'Tech Hub Tower, 4th Floor, Suite 402',
      selectedLocationAddress: lastOrder?.selectedLocationAddress,
      isLocationConfirmed: lastOrder?.isLocationConfirmed ?? false,
      estimatedTotalUsd: estimatedTotal < 1 ? 1 : estimatedTotal,
    );
  }

  PrintFlowState copyWith({
    List<PrintDocument>? files,
    Map<String, FilePrintConfiguration>? configurations,
    String? expandedPath,
    bool clearExpandedPath = false,
    PrintOrderData? lastOrder,
  }) {
    return PrintFlowState(
      files: files ?? this.files,
      configurations: configurations ?? this.configurations,
      expandedPath: clearExpandedPath
          ? null
          : (expandedPath ?? this.expandedPath),
      lastOrder: lastOrder ?? this.lastOrder,
    );
  }

  @override
  List<Object?> get props => [files, configurations, expandedPath, lastOrder];
}
