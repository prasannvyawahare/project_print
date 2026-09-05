class ApiConstants {
  const ApiConstants._();
  static const String baseUrl = 'https://print-hub-mcd2.onrender.com/api/v1/';
  static const String verifyAndSaveUserPath = 'user/verify-and-save';

  static const String checkStorageExists = 'user/storage-exists';
  static const String createStorage = 'user/create-storage';
  static const String printTypePath = 'print-type/get';
  static const String printConfigPath = 'print-config/get';

  static const String uploadRequestPath = 'upload/request';
  static const String uploadCompletePath = 'upload/complete';

  static const String addressCreate = 'address/create';
  static const String addressGet = 'address/get';
  static const String addressRemove = 'address/remove';
  static const String addressSelect = 'address/select';

  static const String orderCreate = 'order/create';
  static const String orderSummary = 'order/order-summary';
  static const String orderCheckout = 'order/checkout';
  static const String orderCancel = 'order/cancel';

  /// Finalizes a single order item after its Drive upload PUT succeeds.
  /// [itemId] comes from the `order/create` response.
  static String orderItemUploadComplete(String itemId) =>
      'order/items/$itemId/upload-complete';

  /// Polls `{orderStatus, paymentStatus, paymentMethod}` for [orderId].
  /// Used to confirm a UPI payment once the Razorpay webhook has landed,
  /// since the client-side Checkout callback is not authoritative.
  static String orderStatus(String orderId) => 'order/$orderId/status';

  // Keep existing demo endpoint working with an absolute URL.
  static const String welcomePath =
      'https://jsonplaceholder.typicode.com/posts/1';
}
