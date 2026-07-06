/// Google Pay payment configuration used by the `pay` package.
///
/// This is the JSON `PaymentDataRequest` that the Google Pay sheet is built
/// from. It currently targets the `TEST` environment with an example gateway
/// so the sheet can be exercised end-to-end without charging a real card.
///
/// Before going live, replace:
///   * `environment` -> `PRODUCTION`
///   * `tokenizationSpecification.parameters.gateway` -> your PSP id
///     (e.g. `razorpay`, `stripe`, `cybersource`)
///   * `gatewayMerchantId` -> the merchant id issued by that PSP
///   * `merchantInfo.merchantId` -> your Google Pay merchant id (from the
///     Google Pay & Wallet Console)
const String kGooglePayConfig = '''
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
            "gatewayMerchantId": "exampleGatewayMerchantId"
          }
        },
        "parameters": {
          "allowedCardNetworks": ["VISA", "MASTERCARD", "RUPAY"],
          "allowedAuthMethods": ["PAN_ONLY", "CRYPTOGRAM_3DS"],
          "billingAddressRequired": false
        }
      }
    ],
    "merchantInfo": {
      "merchantId": "01234567890123456789",
      "merchantName": "PrintHub"
    },
    "transactionInfo": {
      "countryCode": "IN",
      "currencyCode": "INR"
    }
  }
}
''';
