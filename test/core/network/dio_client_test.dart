import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:project_print/app/router/app_router.dart';
import 'package:project_print/core/network/dio_client.dart';
import 'package:project_print/core/storage/temporary_auth_store.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockTemporaryAuthStore extends Mock implements TemporaryAuthStore {}

/// A single canned response the [_QueueAdapter] will hand back, in order.
class _CannedResponse {
  _CannedResponse({
    required this.statusCode,
    this.data = const {'ok': true},
    this.delay,
  });

  final int statusCode;
  final Map<String, dynamic> data;

  /// Optional delay before resolving — used to simulate an in-flight request
  /// so cancellation can be exercised.
  final Duration? delay;
}

/// A fake [HttpClientAdapter] that hands back pre-scripted responses in
/// order and records every [RequestOptions] it was asked to fetch, so tests
/// can assert on headers/paths without touching the network.
class _QueueAdapter implements HttpClientAdapter {
  final List<_CannedResponse> responses = [];
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final canned = responses.removeAt(0);

    if (canned.delay != null) {
      final completer = Completer<void>();
      cancelFuture?.then((_) {
        if (!completer.isCompleted) completer.completeError(DioException.requestCancelled(requestOptions: options, reason: 'cancelled'));
      });
      await Future.any([
        Future<void>.delayed(canned.delay!).then((_) => completer.complete()),
        completer.future,
      ]);
    }

    return ResponseBody.fromString(
      jsonEncode(canned.data),
      canned.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late _QueueAdapter adapter;
  late MockFirebaseAuth firebaseAuth;
  late MockTemporaryAuthStore authStore;
  late DioClient client;

  setUp(() {
    dio = Dio();
    adapter = _QueueAdapter();
    dio.httpClientAdapter = adapter;
    firebaseAuth = MockFirebaseAuth();
    authStore = MockTemporaryAuthStore();
    when(() => authStore.token).thenReturn('stored-token');
    when(() => authStore.mobile).thenReturn('9999999999');
    when(() => authStore.save(mobile: any(named: 'mobile'), token: any(named: 'token')))
        .thenAnswer((_) async {});
    when(() => authStore.clear()).thenAnswer((_) async {});
    client = DioClient(
      dio: dio,
      temporaryAuthStore: authStore,
      firebaseAuth: firebaseAuth,
    );
  });

  group('request methods', () {
    test('get forwards path/data/queryParameters and returns the response', () async {
      when(() => firebaseAuth.currentUser).thenReturn(null);
      adapter.responses.add(_CannedResponse(statusCode: 200, data: {'hello': 'world'}));

      final response = await client.get(
        path: 'order/order-summary',
        data: {'orderId': 'o1'},
        queryParameters: {'x': '1'},
      );

      expect(response.statusCode, 200);
      expect(response.data, {'hello': 'world'});
      expect(adapter.requests.single.path, 'order/order-summary');
      expect(adapter.requests.single.queryParameters, {'x': '1'});
    });

    test('post forwards data and adds x-client-platform header', () async {
      when(() => firebaseAuth.currentUser).thenReturn(null);
      adapter.responses.add(_CannedResponse(statusCode: 200));

      await client.post(path: 'order/checkout', data: {'a': 1});

      final sent = adapter.requests.single;
      expect(sent.method, 'POST');
      expect(sent.headers['x-client-platform'], 'mobile');
    });

    test('delete forwards path/data', () async {
      when(() => firebaseAuth.currentUser).thenReturn(null);
      adapter.responses.add(_CannedResponse(statusCode: 200));

      await client.delete(path: 'order/cancel', data: {'orderId': 'o1'});

      expect(adapter.requests.single.method, 'DELETE');
    });

    test('patch forwards path/data', () async {
      when(() => firebaseAuth.currentUser).thenReturn(null);
      adapter.responses.add(_CannedResponse(statusCode: 200));

      await client.patch(path: 'order/o1', data: {'a': 1});

      expect(adapter.requests.single.method, 'PATCH');
    });

    test('omitContentType strips the Content-Type header', () async {
      when(() => firebaseAuth.currentUser).thenReturn(null);
      adapter.responses.add(_CannedResponse(statusCode: 200));

      await client.post(
        path: 'upload/complete',
        data: {'a': 1},
        omitContentType: true,
      );

      final sent = adapter.requests.single;
      expect(sent.headers.containsKey('Content-Type'), isFalse);
      expect(sent.headers.containsKey('content-type'), isFalse);
      expect(sent.contentType, isNull);
    });

    test('explicit headers (including Authorization) are preserved as-is', () async {
      adapter.responses.add(_CannedResponse(statusCode: 200));

      await client.post(
        path: 'order/checkout',
        data: {'a': 1},
        headers: {'Authorization': 'Bearer caller-supplied'},
      );

      final sent = adapter.requests.single;
      expect(sent.headers['Authorization'], 'Bearer caller-supplied');
      // Since a caller-supplied Authorization header was present, the
      // interceptor must not have consulted Firebase/the auth store at all.
      verifyNever(() => firebaseAuth.currentUser);
    });
  });

  group('auth header injection', () {
    test('uses the fresh Firebase ID token when a user is signed in', () async {
      final user = MockUser();
      when(() => firebaseAuth.currentUser).thenReturn(user);
      when(() => user.getIdToken()).thenAnswer((_) async => 'fresh-token');
      adapter.responses.add(_CannedResponse(statusCode: 200));

      await client.get(path: 'user/storage-exists');

      final sent = adapter.requests.single;
      expect(sent.headers['Authorization'], 'Bearer fresh-token');
    });

    test('persists the fresh token when it differs from the stored one', () async {
      final user = MockUser();
      when(() => firebaseAuth.currentUser).thenReturn(user);
      when(() => user.getIdToken()).thenAnswer((_) async => 'fresh-token');
      adapter.responses.add(_CannedResponse(statusCode: 200));

      await client.get(path: 'user/storage-exists');

      verify(() => authStore.save(mobile: '9999999999', token: 'fresh-token')).called(1);
    });

    test('does not re-save when the fresh token matches the stored one', () async {
      final user = MockUser();
      when(() => firebaseAuth.currentUser).thenReturn(user);
      when(() => user.getIdToken()).thenAnswer((_) async => 'stored-token');
      adapter.responses.add(_CannedResponse(statusCode: 200));

      await client.get(path: 'user/storage-exists');

      verifyNever(() => authStore.save(mobile: any(named: 'mobile'), token: any(named: 'token')));
    });

    test('falls back to the stored token when no Firebase user is signed in', () async {
      when(() => firebaseAuth.currentUser).thenReturn(null);
      adapter.responses.add(_CannedResponse(statusCode: 200));

      await client.get(path: 'user/storage-exists');

      final sent = adapter.requests.single;
      expect(sent.headers['Authorization'], 'Bearer stored-token');
    });

    test('falls back to the stored token when getIdToken throws', () async {
      final user = MockUser();
      when(() => firebaseAuth.currentUser).thenReturn(user);
      when(() => user.getIdToken()).thenThrow(Exception('network hiccup'));
      adapter.responses.add(_CannedResponse(statusCode: 200));

      await client.get(path: 'user/storage-exists');

      final sent = adapter.requests.single;
      expect(sent.headers['Authorization'], 'Bearer stored-token');
    });
  });

  group('401 handling', () {
    testWidgets('refreshes the token and retries once on 401, resolving on success', (tester) async {
      final navigatorKey = AppRouter.navigatorKey;
      await tester.pumpWidget(MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: SizedBox()),
      ));

      final user = MockUser();
      when(() => firebaseAuth.currentUser).thenReturn(user);
      // First call (non-force) used by the request-time header injection.
      when(() => user.getIdToken()).thenAnswer((_) async => 'stored-token');
      // Forced refresh used by the 401 handler.
      when(() => user.getIdToken(true)).thenAnswer((_) async => 'refreshed-token');

      adapter.responses.add(_CannedResponse(statusCode: 401, data: {'message': 'expired'}));
      adapter.responses.add(_CannedResponse(statusCode: 200, data: {'ok': true}));

      final response = await client.get(path: 'user/storage-exists');

      expect(response.statusCode, 200);
      expect(adapter.requests, hasLength(2));
      expect(adapter.requests.last.headers['Authorization'], 'Bearer refreshed-token');
      verify(() => authStore.save(mobile: '9999999999', token: 'refreshed-token')).called(1);
    });

    testWidgets('redirects to /auth when the retry also comes back 401', (tester) async {
      final navigatorKey = AppRouter.navigatorKey;
      await tester.pumpWidget(MaterialApp(
        navigatorKey: navigatorKey,
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          builder: (_) => Text(settings.name ?? 'unknown'),
          settings: settings,
        ),
        home: const Scaffold(body: SizedBox()),
      ));

      final user = MockUser();
      when(() => firebaseAuth.currentUser).thenReturn(user);
      when(() => user.getIdToken()).thenAnswer((_) async => 'stored-token');
      when(() => user.getIdToken(true)).thenAnswer((_) async => 'still-bad-token');

      adapter.responses.add(_CannedResponse(statusCode: 401));
      adapter.responses.add(_CannedResponse(statusCode: 401));

      await expectLater(
        client.get(path: 'user/storage-exists'),
        throwsA(isA<DioException>()),
      );

      await tester.pumpAndSettle();

      verify(() => authStore.clear()).called(1);
      expect(find.text(AppRouter.auth), findsOneWidget);
    });

    testWidgets('redirects to /auth on 401 when there is no Firebase user to refresh', (tester) async {
      final navigatorKey = AppRouter.navigatorKey;
      await tester.pumpWidget(MaterialApp(
        navigatorKey: navigatorKey,
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          builder: (_) => Text(settings.name ?? 'unknown'),
          settings: settings,
        ),
        home: const Scaffold(body: SizedBox()),
      ));

      when(() => firebaseAuth.currentUser).thenReturn(null);
      adapter.responses.add(_CannedResponse(statusCode: 401));

      await expectLater(
        client.get(path: 'user/storage-exists'),
        throwsA(isA<DioException>()),
      );

      await tester.pumpAndSettle();

      verify(() => authStore.clear()).called(1);
      expect(find.text(AppRouter.auth), findsOneWidget);
    });

    testWidgets('redirects to /auth on a plain 403 with no retry attempted', (tester) async {
      final navigatorKey = AppRouter.navigatorKey;
      await tester.pumpWidget(MaterialApp(
        navigatorKey: navigatorKey,
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          builder: (_) => Text(settings.name ?? 'unknown'),
          settings: settings,
        ),
        home: const Scaffold(body: SizedBox()),
      ));

      when(() => firebaseAuth.currentUser).thenReturn(null);
      adapter.responses.add(_CannedResponse(statusCode: 403));

      await expectLater(
        client.get(path: 'user/storage-exists'),
        throwsA(isA<DioException>()),
      );

      await tester.pumpAndSettle();

      expect(adapter.requests, hasLength(1));
      expect(find.text(AppRouter.auth), findsOneWidget);
    });

    test('does nothing when the navigator has no current state (no crash)', () async {
      when(() => firebaseAuth.currentUser).thenReturn(null);
      adapter.responses.add(_CannedResponse(statusCode: 401));

      // No MaterialApp pumped, so AppRouter.navigatorKey.currentState is
      // null — _handleUnauthorized should bail out without throwing.
      await expectLater(
        client.get(path: 'user/storage-exists'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('session cancellation', () {
    testWidgets('cancelSession cancels in-flight requests', (tester) async {
      await tester.pumpWidget(MaterialApp(
        navigatorKey: AppRouter.navigatorKey,
        home: const Scaffold(body: SizedBox()),
      ));

      when(() => firebaseAuth.currentUser).thenReturn(null);
      adapter.responses.add(
        _CannedResponse(statusCode: 200, delay: const Duration(seconds: 5)),
      );

      final future = client.get(path: 'order/order-summary');
      // Let the request actually reach the adapter before cancelling.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      client.cancelSession('logging out');

      await expectLater(future, throwsA(isA<DioException>()));
    });

    test('a new session token is issued after cancelSession, so later requests succeed', () async {
      when(() => firebaseAuth.currentUser).thenReturn(null);
      client.cancelSession('logging out');

      adapter.responses.add(_CannedResponse(statusCode: 200));
      final response = await client.get(path: 'order/order-summary');

      expect(response.statusCode, 200);
    });
  });
}
