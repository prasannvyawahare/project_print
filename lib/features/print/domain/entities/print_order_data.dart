enum PrintColorMode { color, blackWhite }

enum PrintOrientation { portrait, landscape }

enum PrintServiceOption { color, blackWhite, banner, spiral, other }

enum DeliveryAddressType { home, office }

class PrintDocument {
  const PrintDocument({
    required this.path,
    required this.name,
    required this.sizeInBytes,
    required this.pageCount,
  });

  final String path;
  final String name;
  final int sizeInBytes;
  final int pageCount;

  String get formattedSize {
    if (sizeInBytes >= 1024 * 1024) {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (sizeInBytes >= 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(0)} KB';
    }
    return '$sizeInBytes B';
  }
}

class PrintOrderData {
  const PrintOrderData({
    required this.documents,
    this.selectedDocumentIndex = 0,
    this.copies = 1,
    this.colorMode = PrintColorMode.color,
    this.pageFrom = 1,
    this.pageTo = 1,
    this.orientation = PrintOrientation.portrait,
    this.paperSize = 'A4 (Standard)',
    this.printOption = PrintServiceOption.color,
    this.deliveryAddressType = DeliveryAddressType.home,
    this.homeAddress = '221B Baker Street, London, NW1 6XE',
    this.officeAddress = 'Tech Hub Tower, 4th Floor, Suite 402',
    this.selectedLocationAddress,
    this.isLocationConfirmed = false,
    this.estimatedTotalUsd = 12.40,
  });

  final List<PrintDocument> documents;
  final int selectedDocumentIndex;
  final int copies;
  final PrintColorMode colorMode;
  final int pageFrom;
  final int pageTo;
  final PrintOrientation orientation;
  final String paperSize;
  final PrintServiceOption printOption;
  final DeliveryAddressType deliveryAddressType;
  final String homeAddress;
  final String officeAddress;
  final String? selectedLocationAddress;
  final bool isLocationConfirmed;
  final double estimatedTotalUsd;

  PrintDocument get selectedDocument => documents[selectedDocumentIndex];

  int get totalPages => selectedDocument.pageCount;

  String get currentDeliveryAddress =>
      deliveryAddressType == DeliveryAddressType.home
      ? homeAddress
      : officeAddress;

  PrintOrderData copyWith({
    List<PrintDocument>? documents,
    int? selectedDocumentIndex,
    int? copies,
    PrintColorMode? colorMode,
    int? pageFrom,
    int? pageTo,
    PrintOrientation? orientation,
    String? paperSize,
    PrintServiceOption? printOption,
    DeliveryAddressType? deliveryAddressType,
    String? homeAddress,
    String? officeAddress,
    String? selectedLocationAddress,
    bool? isLocationConfirmed,
    double? estimatedTotalUsd,
  }) {
    return PrintOrderData(
      documents: documents ?? this.documents,
      selectedDocumentIndex:
          selectedDocumentIndex ?? this.selectedDocumentIndex,
      copies: copies ?? this.copies,
      colorMode: colorMode ?? this.colorMode,
      pageFrom: pageFrom ?? this.pageFrom,
      pageTo: pageTo ?? this.pageTo,
      orientation: orientation ?? this.orientation,
      paperSize: paperSize ?? this.paperSize,
      printOption: printOption ?? this.printOption,
      deliveryAddressType: deliveryAddressType ?? this.deliveryAddressType,
      homeAddress: homeAddress ?? this.homeAddress,
      officeAddress: officeAddress ?? this.officeAddress,
      selectedLocationAddress:
          selectedLocationAddress ?? this.selectedLocationAddress,
      isLocationConfirmed: isLocationConfirmed ?? this.isLocationConfirmed,
      estimatedTotalUsd: estimatedTotalUsd ?? this.estimatedTotalUsd,
    );
  }
}

class FilePrintConfiguration {
  const FilePrintConfiguration({
    required this.copies,
    required this.colorMode,
    required this.pageFrom,
    required this.pageTo,
    required this.orientation,
    required this.paperSize,
    required this.printOption,
  });

  final int copies;
  final PrintColorMode colorMode;
  final int pageFrom;
  final int pageTo;
  final PrintOrientation orientation;
  final String paperSize;
  final PrintServiceOption printOption;
}
