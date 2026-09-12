import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project_print/core/storage/active_job_store.dart';

void main() {
  late ActiveJobStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    store = ActiveJobStore(preferences: prefs);
  });

  ActiveJob job(String orderId, {int createdAtMs = 0, String step = ActiveJobStep.review}) {
    return ActiveJob(
      orderId: orderId,
      fileNames: const ['a.pdf', 'b.pdf'],
      step: step,
      status: 'Pending delivery details',
      createdAtMs: createdAtMs,
    );
  }

  group('ActiveJob', () {
    test('title falls back to "Print order" when fileNames is empty', () {
      const j = ActiveJob(
        orderId: 'o1',
        fileNames: [],
        step: ActiveJobStep.review,
        status: 'Pending',
        createdAtMs: 0,
      );
      expect(j.title, 'Print order');
      expect(j.fileCount, 1);
    });

    test('title/fileCount use fileNames when present', () {
      final j = job('o1');
      expect(j.title, 'a.pdf');
      expect(j.fileCount, 2);
    });

    test('grandTotal sums subtotal and deliveryCharge', () {
      const j = ActiveJob(
        orderId: 'o1',
        fileNames: [],
        step: ActiveJobStep.review,
        status: 'Pending',
        createdAtMs: 0,
        subtotal: 10,
        deliveryCharge: 5,
      );
      expect(j.grandTotal, 15);
    });

    test('copyWith overrides only provided fields', () {
      final original = job('o1', createdAtMs: 100);
      final updated = original.copyWith(step: ActiveJobStep.checkout, status: 'Paid');

      expect(updated.orderId, 'o1');
      expect(updated.fileNames, original.fileNames);
      expect(updated.createdAtMs, 100);
      expect(updated.step, ActiveJobStep.checkout);
      expect(updated.status, 'Paid');
      expect(updated.address, isNull);
    });

    test('toJson/fromJson round-trips all fields', () {
      final original = ActiveJob(
        orderId: 'o1',
        fileNames: const ['a.pdf'],
        step: ActiveJobStep.checkout,
        status: 'Paid',
        address: '123 Street',
        createdAtMs: 555,
        baseRate: 5,
        subtotal: 10,
        deliveryCharge: 20,
      );

      final decoded = ActiveJob.fromJson(original.toJson());

      expect(decoded.orderId, original.orderId);
      expect(decoded.fileNames, original.fileNames);
      expect(decoded.step, original.step);
      expect(decoded.status, original.status);
      expect(decoded.address, original.address);
      expect(decoded.createdAtMs, original.createdAtMs);
      expect(decoded.baseRate, original.baseRate);
      expect(decoded.subtotal, original.subtotal);
      expect(decoded.deliveryCharge, original.deliveryCharge);
    });

    test('fromJson defaults missing/invalid fields', () {
      final decoded = ActiveJob.fromJson(const {});
      expect(decoded.orderId, '');
      expect(decoded.fileNames, isEmpty);
      expect(decoded.step, ActiveJobStep.review);
      expect(decoded.status, 'Pending delivery details');
      expect(decoded.address, isNull);
      expect(decoded.createdAtMs, 0);
      expect(decoded.baseRate, 0);

      final withNonListNames = ActiveJob.fromJson(const {'fileNames': 'not-a-list'});
      expect(withNonListNames.fileNames, isEmpty);
    });
  });

  group('ActiveJobStore', () {
    test('getJobs returns empty list when nothing stored', () {
      expect(store.getJobs(), isEmpty);
    });

    test('upsert adds a job and getJobs returns it newest first', () async {
      await store.upsert(job('o1', createdAtMs: 1));
      await store.upsert(job('o2', createdAtMs: 2));

      final jobs = store.getJobs();
      expect(jobs.map((j) => j.orderId).toList(), ['o2', 'o1']);
    });

    test('upsert replaces an existing job with the same orderId', () async {
      await store.upsert(job('o1', createdAtMs: 1, step: ActiveJobStep.review));
      await store.upsert(job('o1', createdAtMs: 1, step: ActiveJobStep.checkout));

      final jobs = store.getJobs();
      expect(jobs, hasLength(1));
      expect(jobs.first.step, ActiveJobStep.checkout);
    });

    test('findById returns the matching job or null', () async {
      await store.upsert(job('o1'));
      expect(store.findById('o1')?.orderId, 'o1');
      expect(store.findById('missing'), isNull);
    });

    test('markStep updates step/status/address/billing on an existing job', () async {
      await store.upsert(job('o1'));

      await store.markStep(
        'o1',
        step: ActiveJobStep.checkout,
        status: 'Awaiting payment',
        address: 'Home',
        baseRate: 5,
        subtotal: 10,
        deliveryCharge: 20,
      );

      final updated = store.findById('o1')!;
      expect(updated.step, ActiveJobStep.checkout);
      expect(updated.status, 'Awaiting payment');
      expect(updated.address, 'Home');
      expect(updated.baseRate, 5);
      expect(updated.subtotal, 10);
      expect(updated.deliveryCharge, 20);
    });

    test('markStep is a no-op when the job does not exist', () async {
      await store.markStep('missing', step: ActiveJobStep.checkout);
      expect(store.getJobs(), isEmpty);
    });

    test('remove deletes a job by orderId', () async {
      await store.upsert(job('o1'));
      await store.upsert(job('o2'));

      await store.remove('o1');

      expect(store.getJobs().map((j) => j.orderId), ['o2']);
    });

    test('clear empties the store', () async {
      await store.upsert(job('o1'));
      await store.clear();
      expect(store.getJobs(), isEmpty);
    });

    test('getJobs returns empty and does not throw on corrupted JSON', () async {
      SharedPreferences.setMockInitialValues({'active_jobs': 'not-json'});
      final prefs = await SharedPreferences.getInstance();
      final corrupted = ActiveJobStore(preferences: prefs);

      expect(corrupted.getJobs(), isEmpty);
    });

    test('getJobs returns empty when the stored value is not a JSON list', () async {
      SharedPreferences.setMockInitialValues({'active_jobs': '{"not":"a list"}'});
      final prefs = await SharedPreferences.getInstance();
      final corrupted = ActiveJobStore(preferences: prefs);

      expect(corrupted.getJobs(), isEmpty);
    });

    test('getJobs skips list entries with an empty orderId', () async {
      SharedPreferences.setMockInitialValues({
        'active_jobs': '[{"orderId":"","fileNames":[]},{"orderId":"o1","fileNames":[]}]',
      });
      final prefs = await SharedPreferences.getInstance();
      final loaded = ActiveJobStore(preferences: prefs);

      expect(loaded.getJobs().map((j) => j.orderId), ['o1']);
    });
  });
}
