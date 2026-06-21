/// Parsed response for `GET order/order-summary`.
///
/// The backend wraps the payload either directly under an `items` key or
/// inside a `data` envelope (like the other endpoints), so the parser tolerates
/// both shapes.
class OrderSummaryResponse {
  const OrderSummaryResponse({
    required this.items,
    required this.totalAmount,
    required this.deliveryCharge,
  });

  final List<OrderSummaryItem> items;
  final num totalAmount;
  final num deliveryCharge;

  /// Subtotal + delivery charge.
  num get grandTotal => totalAmount + deliveryCharge;

  factory OrderSummaryResponse.fromJson(Map<String, dynamic> json) {
    // Unwrap a possible `data` envelope.
    final root = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    // The payload lives under an `items` object that itself holds an `items`
    // list plus the totals.
    final container = root['items'] is Map<String, dynamic>
        ? root['items'] as Map<String, dynamic>
        : root;

    final rawItems = container['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(OrderSummaryItem.fromJson)
              .toList(growable: false)
        : const <OrderSummaryItem>[];

    return OrderSummaryResponse(
      items: items,
      totalAmount: _toNum(container['totalAmount']),
      deliveryCharge: _toNum(container['deliveryCharge']),
    );
  }
}

class OrderSummaryItem {
  const OrderSummaryItem({
    required this.rate,
    required this.total,
    required this.details,
  });

  final num rate;
  final num total;
  final OrderSummaryItemDetails details;

  factory OrderSummaryItem.fromJson(Map<String, dynamic> json) {
    final details = json['details'] is Map<String, dynamic>
        ? OrderSummaryItemDetails.fromJson(
            json['details'] as Map<String, dynamic>,
          )
        : const OrderSummaryItemDetails.empty();

    return OrderSummaryItem(
      rate: _toNum(json['rate']),
      total: _toNum(json['total']),
      details: details,
    );
  }
}

class OrderSummaryItemDetails {
  const OrderSummaryItemDetails({
    required this.id,
    required this.orderId,
    required this.fileType,
    required this.fileName,
    required this.numberOfCopy,
    required this.samePage,
    required this.documentLinks,
    required this.printType,
  });

  const OrderSummaryItemDetails.empty()
    : id = '',
      orderId = '',
      fileType = '',
      fileName = 'Document',
      numberOfCopy = 1,
      samePage = false,
      documentLinks = const <String>[],
      printType = '';

  final String id;
  final String orderId;
  final String fileType;
  final String fileName;
  final int numberOfCopy;
  final bool samePage;
  final List<String> documentLinks;
  final String printType;

  factory OrderSummaryItemDetails.fromJson(Map<String, dynamic> json) {
    final links = json['documentLinks'];
    return OrderSummaryItemDetails(
      id: json['_id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      fileType: json['fileType']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? 'Document',
      numberOfCopy: (json['numberOfCopy'] as num?)?.toInt() ?? 1,
      samePage: json['samePage'] == true,
      documentLinks: links is List
          ? links.map((e) => e.toString()).toList(growable: false)
          : const <String>[],
      printType: json['printType']?.toString() ?? '',
    );
  }
}

num _toNum(Object? value) {
  if (value is num) {
    return value;
  }
  return num.tryParse(value?.toString() ?? '') ?? 0;
}
