/// Parsed response for `GET order/history`.
///
/// The backend wraps list payloads under a `data` envelope elsewhere in this
/// API (see `OrderSummaryResponse`), and may additionally nest the list
/// itself under an `orders`/`history`/`items` key — this parser tolerates a
/// bare list too, so it keeps working whichever shape actually comes back.
class OrderHistoryResponse {
  const OrderHistoryResponse({required this.orders});

  final List<OrderHistoryEntry> orders;

  factory OrderHistoryResponse.fromJson(dynamic json) {
    dynamic root = json;
    if (root is Map<String, dynamic> && root['data'] != null) {
      root = root['data'];
    }
    if (root is Map<String, dynamic>) {
      root = root['orders'] ?? root['history'] ?? root['items'] ?? root;
    }

    final rawList = root is List ? root : const <dynamic>[];
    return OrderHistoryResponse(
      orders: rawList
          .whereType<Map<String, dynamic>>()
          .map(OrderHistoryEntry.fromJson)
          .toList(growable: false),
    );
  }
}

class OrderHistoryEntry {
  const OrderHistoryEntry({
    required this.orderId,
    required this.orderStatus,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.grandTotal,
    required this.itemCount,
    required this.fileNames,
    required this.createdAt,
  });

  final String orderId;
  final String orderStatus;
  final String paymentStatus;
  final String paymentMethod;
  final num grandTotal;
  final int itemCount;
  final List<String> fileNames;
  final DateTime? createdAt;

  String get title => fileNames.isNotEmpty ? fileNames.first : 'Print order';

  factory OrderHistoryEntry.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final fileNames = rawItems is List
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map((item) {
                final details = item['details'];
                final name = details is Map<String, dynamic>
                    ? details['fileName']
                    : item['fileName'];
                return name?.toString() ?? '';
              })
              .where((name) => name.isNotEmpty)
              .toList(growable: false)
        : const <String>[];

    return OrderHistoryEntry(
      orderId: (json['orderId'] ?? json['_id'])?.toString() ?? '',
      orderStatus: json['orderStatus']?.toString() ?? '',
      paymentStatus: json['paymentStatus']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      grandTotal: _toNum(json['grandTotal'] ?? json['totalAmount']),
      itemCount: rawItems is List
          ? rawItems.length
          : (json['itemCount'] as num?)?.toInt() ?? 0,
      fileNames: fileNames,
      createdAt: DateTime.tryParse(
        (json['createdAt'] ?? json['orderDate'] ?? '').toString(),
      ),
    );
  }
}

num _toNum(Object? value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}
