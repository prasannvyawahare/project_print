import '../config/app_environment.dart';

/// Razorpay Key ID used to open the Checkout sheet from `razorpay_flutter`.
///
/// The right key is selected automatically from the running build flavor
/// (see [AppEnvironment]): the `internal`/`dev` flavors use the test key, and
/// only `prod` uses the live key. Only the Key ID is used client-side — the
/// Key Secret must never ship in the app; it belongs on the backend once
/// server-side order creation and payment signature verification are added.
String get kRazorpayKeyId =>
    AppEnvironment.isProduction ? _liveKeyId : _testKeyId;

const String _testKeyId = 'rzp_test_TWlMzQh43lG94H';

/// Fill in the real live Key ID before shipping the `prod` flavor.
const String _liveKeyId = 'TODO_YOUR_RAZORPAY_LIVE_KEY_ID';
