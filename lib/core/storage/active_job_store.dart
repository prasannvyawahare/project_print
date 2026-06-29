import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// The step a job is currently parked at, so it can be resumed on the right
/// screen from the home "Active Jobs" list.
class ActiveJobStep {
  const ActiveJobStep._();

  /// Configured + order created, waiting on the Review & Deliver screen.
  static const String review = 'review';

  /// Delivery chosen, sitting on the Checkout screen.
  static const String checkout = 'checkout';
}

/// A print order the user has started. Persisted locally (the backend has no
/// "list my orders" endpoint yet) so it can be surfaced as an "Active Job" on
/// the home screen and resumed at the step it was left on — even offline.
class ActiveJob {
  const ActiveJob({
    required this.orderId,
    required this.fileNames,
    required this.step,
    required this.status,
    required this.createdAtMs,
    this.address,
    this.baseRate = 0,
    this.subtotal = 0,
    this.deliveryCharge = 0,
  });

  final String orderId;
  final List<String> fileNames;
  final String step;
  final String status;
  final String? address;
  final int createdAtMs;

  /// Billing totals captured from the `order/create` response, kept locally so
  /// the home "Active Jobs" card can show the price without a network call.
  final num baseRate;
  final num subtotal;
  final num deliveryCharge;

  String get title => fileNames.isNotEmpty ? fileNames.first : 'Print order';

  int get fileCount => fileNames.isEmpty ? 1 : fileNames.length;

  /// Subtotal + delivery charge.
  num get grandTotal => subtotal + deliveryCharge;

  ActiveJob copyWith({
    String? step,
    String? status,
    String? address,
    num? baseRate,
    num? subtotal,
    num? deliveryCharge,
  }) {
    return ActiveJob(
      orderId: orderId,
      fileNames: fileNames,
      step: step ?? this.step,
      status: status ?? this.status,
      address: address ?? this.address,
      createdAtMs: createdAtMs,
      baseRate: baseRate ?? this.baseRate,
      subtotal: subtotal ?? this.subtotal,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
    );
  }

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'fileNames': fileNames,
    'step': step,
    'status': status,
    'address': address,
    'createdAtMs': createdAtMs,
    'baseRate': baseRate,
    'subtotal': subtotal,
    'deliveryCharge': deliveryCharge,
  };

  factory ActiveJob.fromJson(Map<String, dynamic> json) {
    final rawNames = json['fileNames'];
    return ActiveJob(
      orderId: json['orderId']?.toString() ?? '',
      fileNames: rawNames is List
          ? rawNames.map((e) => e.toString()).toList(growable: false)
          : const <String>[],
      step: json['step']?.toString() ?? ActiveJobStep.review,
      status: json['status']?.toString() ?? 'Pending delivery details',
      address: json['address']?.toString(),
      createdAtMs: (json['createdAtMs'] as num?)?.toInt() ?? 0,
      baseRate: (json['baseRate'] as num?) ?? 0,
      subtotal: (json['subtotal'] as num?) ?? 0,
      deliveryCharge: (json['deliveryCharge'] as num?) ?? 0,
    );
  }
}

class ActiveJobStore {
  ActiveJobStore({required SharedPreferences preferences})
    : _preferences = preferences;

  static const String _key = 'active_jobs';

  final SharedPreferences _preferences;

  /// Active jobs, newest first.
  List<ActiveJob> getJobs() {
    final raw = _preferences.getString(_key);
    if (raw == null || raw.isEmpty) return const <ActiveJob>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <ActiveJob>[];
      final jobs = decoded
          .whereType<Map<String, dynamic>>()
          .map(ActiveJob.fromJson)
          .where((j) => j.orderId.isNotEmpty)
          .toList();
      jobs.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
      return jobs;
    } catch (_) {
      return const <ActiveJob>[];
    }
  }

  ActiveJob? findById(String orderId) {
    for (final job in getJobs()) {
      if (job.orderId == orderId) return job;
    }
    return null;
  }

  /// Insert or update a job, keyed by [ActiveJob.orderId].
  Future<void> upsert(ActiveJob job) async {
    final jobs = getJobs().toList()
      ..removeWhere((j) => j.orderId == job.orderId)
      ..add(job);
    await _save(jobs);
  }

  /// Advance an existing job to a new [step] (and optionally [status]/[address]),
  /// preserving its file list. No-op if the job is not found.
  Future<void> markStep(
    String orderId, {
    required String step,
    String? status,
    String? address,
    num? baseRate,
    num? subtotal,
    num? deliveryCharge,
  }) async {
    final existing = findById(orderId);
    if (existing == null) return;
    await upsert(
      existing.copyWith(
        step: step,
        status: status,
        address: address,
        baseRate: baseRate,
        subtotal: subtotal,
        deliveryCharge: deliveryCharge,
      ),
    );
  }

  Future<void> remove(String orderId) async {
    final jobs = getJobs().where((j) => j.orderId != orderId).toList();
    await _save(jobs);
  }

  Future<void> clear() => _preferences.remove(_key);

  Future<void> _save(List<ActiveJob> jobs) async {
    final encoded = jsonEncode(jobs.map((j) => j.toJson()).toList());
    await _preferences.setString(_key, encoded);
  }
}
