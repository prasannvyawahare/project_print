import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../auth/domain/usecases/sign_out.dart';
import '../../../upload/presentation/pages/order_history_page.dart'
    show OrderHistoryPage;
import '../../domain/entities/user_profile_entity.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

const _accent = AppColors.dashboardAccent;
const _pageBackground = AppColors.dashboardBackground;
const _primaryText = AppColors.dashboardPrimaryText;
const _mutedText = AppColors.dashboardMutedText;

const _heroGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF4A20C7), Color(0xFF40D9D9)],
);

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ProfileView();
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    setState(() => _isLoggingOut = true);
    final result = await sl<SignOut>()();
    if (!mounted) return;
    setState(() => _isLoggingOut = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(failure.message)));
      },
      (_) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRouter.auth, (route) => false);
      },
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log out?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _logout();
    }
  }

  @override
  void initState() {
    super.initState();
    // ProfileBloc is a shared singleton pre-fetched from the dashboard, so
    // only kick off a fetch here if nothing has requested one yet — avoids
    // flashing the loading state again every time this screen reopens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<ProfileBloc>();
      if (bloc.state.status == ProfileStatus.initial) {
        bloc.add(const ProfileRequested());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 2,
        onHome: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
        onOrders: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const OrderHistoryPage()),
          );
        },
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          switch (state.status) {
            case ProfileStatus.initial:
            case ProfileStatus.loading:
              return const _ProfileLoading();
            case ProfileStatus.failure:
              return _ProfileError(
                message: state.error.isEmpty
                    ? 'Unable to load your profile.'
                    : state.error,
                onRetry: () =>
                    context.read<ProfileBloc>().add(const ProfileRequested()),
              );
            case ProfileStatus.success:
              final profile = state.profile;
              if (profile == null) {
                return _ProfileError(
                  message: 'Unable to load your profile.',
                  onRetry: () =>
                      context.read<ProfileBloc>().add(const ProfileRequested()),
                );
              }
              return RefreshIndicator(
                color: _accent,
                onRefresh: () async {
                  context.read<ProfileBloc>().add(const ProfileRequested());
                  await context.read<ProfileBloc>().stream.firstWhere(
                    (s) => s.status != ProfileStatus.loading,
                  );
                },
                child: _ProfileContent(
                  profile: profile,
                  isLoggingOut: _isLoggingOut,
                  onLogout: _confirmLogout,
                ),
              );
          }
        },
      ),
    );
  }
}

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: _heroGradient),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: _heroGradient),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _accent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.isLoggingOut,
    required this.onLogout,
  });

  final UserProfileEntity profile;
  final bool isLoggingOut;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final displayName = profile.name.isEmpty ? 'PrintHub user' : profile.name;
    final initial = displayName.trim().isEmpty
        ? 'P'
        : displayName.trim()[0].toUpperCase();

    final details = <_DetailCard>[
      if (profile.mobile.isNotEmpty)
        _DetailCard(
          Icons.call_rounded,
          'Mobile',
          profile.mobile,
          const Color(0xFFDFF6F4),
          const Color(0xFF0FB6A6),
        ),
      if (profile.createdAt.isNotEmpty)
        _DetailCard(
          Icons.calendar_month_rounded,
          'Member since',
          _formatDate(profile.createdAt),
          const Color(0xFFEFE9FD),
          const Color(0xFF7C3AED),
        ),
      if (profile.email.isNotEmpty)
        _DetailCard(
          Icons.email_rounded,
          'Email',
          profile.email,
          const Color(0xFFE8F0FE),
          const Color(0xFF2563EB),
          fullWidth: true,
          verified: profile.emailVerified,
        ),
      if (profile.id.isNotEmpty)
        _DetailCard(
          Icons.badge_rounded,
          'User ID',
          profile.id,
          const Color(0xFFFDEEE2),
          const Color(0xFFF97316),
          fullWidth: true,
        ),
      for (final address in _dedupedAddresses(profile.extra))
        _DetailCard(
          Icons.location_on_rounded,
          address.label,
          _formatExtraValue(address.value),
          const Color(0xFFFCE7F3),
          const Color(0xFFDB2777),
          fullWidth: true,
        ),
      for (final entry in _nonAddressExtraEntries(profile.extra))
        _DetailCard(
          Icons.info_rounded,
          _titleCaseKey(entry.key),
          _formatExtraValue(entry.value),
          const Color(0xFFF1F3F8),
          const Color(0xFF8B8B9C),
          fullWidth: _formatExtraValue(entry.value).length > 18,
        ),
    ];

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: _ProfileHero(
            displayName: displayName,
            initial: initial,
            email: profile.email,
            photoUrl: profile.photoUrl,
          ),
        ),
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -20),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: _pageBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(18, 28, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('ACCOUNT DETAILS'),
                  const SizedBox(height: 14),
                  if (details.isEmpty)
                    _EmptyCard(
                      icon: Icons.person_search_rounded,
                      message: 'No additional profile details available.',
                    )
                  else
                    for (final row in _layoutDetailCards(details)) ...[
                      row,
                      const SizedBox(height: 14),
                    ],
                  const SizedBox(height: 18),
                  const _SectionLabel('ACTIONS'),
                  const SizedBox(height: 14),
                  _CardGroup(
                    children: [
                      _ActionRow(
                        icon: Icons.logout_rounded,
                        label: 'Log out',
                        iconBackground: const Color(0xFFFDEAEA),
                        iconColor: AppColors.error,
                        labelColor: AppColors.error,
                        isLoading: isLoggingOut,
                        onTap: isLoggingOut ? null : onLogout,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      AppConstants.appName,
                      style: TextStyle(
                        color: _mutedText.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.displayName,
    required this.initial,
    required this.email,
    required this.photoUrl,
  });

  final String displayName;
  final String initial;
  final String email;
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.paddingOf(context).top + 28,
        24,
        30,
      ),
      decoration: const BoxDecoration(
        gradient: _heroGradient,
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            padding: const EdgeInsets.all(3.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.7),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: photoUrl.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        photoUrl,
                        width: 77,
                        height: 77,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _HeroInitial(initial: initial),
                      ),
                    )
                  : _HeroInitial(initial: initial),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroInitial extends StatelessWidget {
  const _HeroInitial({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Text(
      initial,
      style: const TextStyle(
        color: _accent,
        fontSize: 28,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: _primaryText,
      ),
    );
  }
}

class _CardGroup extends StatelessWidget {
  const _CardGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: const Color(0xFFB4AEC6)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _mutedText, fontSize: 13.5),
          ),
        ],
      ),
    );
  }
}

/// Groups detail cards into rows: full-width cards get their own row, and
/// consecutive compact cards are paired two-per-row (a light bento layout).
List<Widget> _layoutDetailCards(List<_DetailCard> details) {
  final rows = <Widget>[];
  var i = 0;
  while (i < details.length) {
    final current = details[i];
    if (!current.fullWidth &&
        i + 1 < details.length &&
        !details[i + 1].fullWidth) {
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: current),
            const SizedBox(width: 12),
            Expanded(child: details[i + 1]),
          ],
        ),
      );
      i += 2;
    } else if (!current.fullWidth) {
      // A compact card with no partner to pair with — render it with the
      // horizontal layout instead of the two-line vertical one meant for
      // half-width tiles, so it doesn't leave a big empty gap when
      // stretched across the full row.
      rows.add(
        _DetailCard(
          current.icon,
          current.label,
          current.value,
          current.iconBackground,
          current.iconColor,
          fullWidth: true,
          verified: current.verified,
        ),
      );
      i += 1;
    } else {
      rows.add(current);
      i += 1;
    }
  }
  return rows;
}

class _AddressEntry {
  const _AddressEntry(this.label, this.value);

  final String label;
  final dynamic value;
}

/// Any extra field whose key mentions "address" (e.g. `address`,
/// `selectedAddress`, `defaultAddress`) is treated as an address. When two
/// such fields hold the same address, only one card is kept — labeled plainly
/// "Address" — instead of showing the identical address twice.
List<_AddressEntry> _dedupedAddresses(Map<String, dynamic> extra) {
  final addressFields = extra.entries.where(
    (e) => e.key.toLowerCase().contains('address'),
  );

  final unique = <MapEntry<String, dynamic>>[];
  for (final entry in addressFields) {
    final signature = _addressSignature(entry.value);
    final isDuplicate = unique.any(
      (u) => _addressSignature(u.value) == signature,
    );
    if (!isDuplicate) unique.add(entry);
  }

  final singleAddress = unique.length == 1;
  return [
    for (final entry in unique)
      _AddressEntry(
        singleAddress ? 'Address' : _titleCaseKey(entry.key),
        entry.value,
      ),
  ];
}

Iterable<MapEntry<String, dynamic>> _nonAddressExtraEntries(
  Map<String, dynamic> extra,
) {
  return extra.entries.where((e) => !e.key.toLowerCase().contains('address'));
}

/// Fields that identify *which physical address* this is, as opposed to
/// bookkeeping metadata (id, whether it's currently selected, timestamps)
/// that can legitimately differ between an `address` entry and a
/// `selectedAddress`/`defaultAddress` entry pointing at that same place.
const _addressIgnoredKeys = {
  'id',
  '_id',
  'selected',
  'isselected',
  'isdefault',
  'createdat',
  'updatedat',
  '__v',
  'userid',
  'user',
};

/// A key-order-independent signature of the address-identifying fields, used
/// to tell whether two address-like extra fields describe the same address.
String _addressSignature(dynamic value) {
  if (value is Map) {
    final parts =
        value.entries
            .where(
              (e) => !_addressIgnoredKeys.contains(e.key.toString().toLowerCase()),
            )
            .map((e) => '${e.key}:${e.value}')
            .toList()
          ..sort();
    return parts.join('|');
  }
  if (value is List) {
    return value.map(_addressSignature).join(',');
  }
  return value.toString();
}

/// Renders nested map/list extra fields (e.g. a saved address) as readable
/// "Key: value" text instead of Dart's raw `{key: value}` toString.
String _formatExtraValue(dynamic value) {
  if (value is Map) {
    return value.entries
        .map((e) => '${_titleCaseKey(e.key.toString())}: ${e.value}')
        .join(' • ');
  }
  if (value is List) {
    if (value.isEmpty) return 'None';
    return value.map(_formatExtraValue).join('\n');
  }
  return value.toString();
}

class _DetailCard extends StatelessWidget {
  const _DetailCard(
    this.icon,
    this.label,
    this.value,
    this.iconBackground,
    this.iconColor, {
    this.fullWidth = false,
    this.verified = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconBackground;
  final Color iconColor;
  final bool fullWidth;

  /// Shows a small neutral check badge next to the value (e.g. a verified
  /// email) instead of a separate "Email Verified" card.
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: fullWidth
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _DetailIconBadge(
                  icon: icon,
                  background: iconBackground,
                  color: iconColor,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _DetailText(
                    label: label,
                    value: value,
                    verified: verified,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailIconBadge(
                  icon: icon,
                  background: iconBackground,
                  color: iconColor,
                ),
                const SizedBox(height: 12),
                _DetailText(label: label, value: value, verified: verified),
              ],
            ),
    );
  }
}

class _DetailIconBadge extends StatelessWidget {
  const _DetailIconBadge({
    required this.icon,
    required this.background,
    required this.color,
  });

  final IconData icon;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 19, color: color),
    );
  }
}

class _DetailText extends StatelessWidget {
  const _DetailText({
    required this.label,
    required this.value,
    this.verified = false,
  });

  final String label;
  final String value;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: _mutedText,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // "In front of" the value: a neutral (uncolored) check badge
            // instead of a separate "Email Verified" card.
            if (verified) ...[
              Icon(
                Icons.check_circle_outline_rounded,
                size: 15,
                color: _mutedText,
              ),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                value,
                maxLines: value.contains('\n')
                    ? value.split('\n').length.clamp(1, 6)
                    : (value.length > 40 ? 3 : 2),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: _primaryText,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.iconBackground,
    required this.iconColor,
    required this.labelColor,
    required this.isLoading,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconBackground;
  final Color iconColor;
  final Color labelColor;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: iconColor,
                        ),
                      )
                    : Icon(icon, size: 19, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: labelColor.withValues(alpha: 0.6),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _monthNames = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatDate(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  return '${parsed.day} ${_monthNames[parsed.month - 1]} ${parsed.year}';
}

String _titleCaseKey(String key) {
  final withSpaces = key
      .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll('_', ' ');
  final words = withSpaces.split(' ').where((w) => w.isNotEmpty);
  return words
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}
