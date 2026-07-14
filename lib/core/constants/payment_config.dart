import '../config/app_environment.dart';

/// Google Pay payment configuration used by the `pay` package.
///
/// The right config is selected automatically from the running build flavor
/// (see [AppEnvironment]): the `internal`/`dev` flavors use the sandbox
/// (`TEST`) profile, and only `prod` uses the live (`PRODUCTION`) profile. Both
/// transact in INR.
///
/// Returns the JSON `PaymentDataRequest` string consumed by
/// `PaymentConfiguration.fromJsonString`.
String get kGooglePayConfig =>
    AppEnvironment.isProduction ? _productionConfig : _testConfig;

/// Sandbox profile. Google Pay's `TEST` environment returns a dummy token via
/// the `example` gateway, so the flow can be exercised end-to-end without a
/// real charge.
///
/// Uses US/USD (like the reference demo) because that's what the TEST
/// environment reliably serves test cards for on most Google accounts;
/// requesting INR here needs a device account eligible for Google Pay India
/// and otherwise fails with error 412. Production (below) transacts in INR.
const String _testConfig = '''
{
  "provider": "google_pay",
  "data": {
    "environment": "TEST",
    "apiVersion": 2,
    "apiVersionMinor": 0,
    "allowedPaymentMethods": [
      {
        "type": "CARD",
        "tokenizationSpecification": {
          "type": "PAYMENT_GATEWAY",
          "parameters": {
            "gateway": "example",
            "gatewayMerchantId": "gatewayMerchantId"
          }
        },
        "parameters": {
          "allowedCardNetworks": ["VISA", "MASTERCARD", "AMEX", "DISCOVER"],
          "allowedAuthMethods": ["PAN_ONLY", "CRYPTOGRAM_3DS"],
          "billingAddressRequired": false
        }
      }
    ],
    "merchantInfo": {
      "merchantName": "PrintHub"
    },
    "transactionInfo": {
      "countryCode": "US",
      "currencyCode": "USD"
    }
  }
}
''';

/// Live profile. Fill in the real values before shipping the `prod` flavor:
///   * `tokenizationSpecification.parameters.gateway` -> your PSP id
///     (e.g. `razorpay`, `cybersource`, `stripe`)
///   * `gatewayMerchantId` -> the merchant id issued by that PSP
///   * `merchantInfo.merchantId` -> your Google Pay merchant id (from the
///     Google Pay & Wallet Console)
const String _productionConfig = '''
{
  "provider": "google_pay",
  "data": {
    "environment": "PRODUCTION",
    "apiVersion": 2,
    "apiVersionMinor": 0,
    "allowedPaymentMethods": [
      {
        "type": "CARD",
        "tokenizationSpecification": {
          "type": "PAYMENT_GATEWAY",
          "parameters": {
            "gateway": "TODO_YOUR_GATEWAY",
            "gatewayMerchantId": "TODO_YOUR_GATEWAY_MERCHANT_ID"
          }
        },
        "parameters": {
          "allowedCardNetworks": ["VISA", "MASTERCARD", "AMEX", "RUPAY"],
          "allowedAuthMethods": ["PAN_ONLY", "CRYPTOGRAM_3DS"],
          "billingAddressRequired": false
        }
      }
    ],
    "merchantInfo": {
      "merchantId": "TODO_YOUR_GOOGLE_PAY_MERCHANT_ID",
      "merchantName": "PrintHub"
    },
    "transactionInfo": {
      "countryCode": "IN",
      "currencyCode": "INR"
    }
  }
}
''';
