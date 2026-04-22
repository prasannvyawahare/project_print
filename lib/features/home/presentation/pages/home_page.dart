import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/di/injection.dart';
import '../../../auth/domain/usecases/sign_out.dart';
import '../../domain/entities/print_category_entity.dart';
import '../../../upload/presentation/pages/upload_documents_page.dart'
    show UploadDocumentsPage;
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';

double _screenScale(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final widthScale = (size.width / 390).clamp(0.82, 1.0);
  final heightScale = (size.height / 844).clamp(0.82, 1.0);
  return (widthScale * 0.7 + heightScale * 0.3).toDouble();
}

double _r(BuildContext context, double value) => value * _screenScale(context);

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomeView();
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  bool _isLoggingOut = false;

  void _openUploadDocuments() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const UploadDocumentsPage()),
    );
  }

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HomeBloc>().add(const HomeRequested());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const pageBackground = Color(0xFFF5F2FA);
    const accent = Color(0xFF6233DD);
    const mutedText = Color(0xFF9A95A8);
    const primaryText = Color(0xFF242230);
    final compact = _screenScale(context);

    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            final greetingSubtitle = switch (state.status) {
              HomeStatus.loading => 'Loading your dashboard...',
              HomeStatus.failure =>
                state.error.isEmpty
                    ? 'Unable to load welcome message'
                    : state.error,
              HomeStatus.success => state.message,
              HomeStatus.initial => 'Ready for your next print order',
            };

            return Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.fromLTRB(
                    _r(context, 12),
                    _r(context, 8),
                    _r(context, 12),
                    _r(context, 10),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: _r(context, 20),
                        ),
                        color: accent,
                      ),
                      Expanded(
                        child: Text(
                          'PrintHub',
                          style: TextStyle(
                            fontSize: _r(context, 20),
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _isLoggingOut ? null : _logout,
                        icon: Icon(Icons.logout_rounded, size: _r(context, 22)),
                        color: accent,
                        tooltip: 'Logout',
                      ),
                    ],
                  ),
                ),
                if (state.status == HomeStatus.loading)
                  const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      _r(context, 18),
                      _r(context, 18),
                      _r(context, 18),
                      _r(context, 16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OVERVIEW',
                          style: TextStyle(
                            fontSize: _r(context, 26),
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1.1,
                            color: Color(0xFF494652),
                          ),
                        ),
                        SizedBox(height: _r(context, 4)),
                        Text(
                          'Hi, Alex👋',
                          style: TextStyle(
                            fontSize: _r(context, 38),
                            fontWeight: FontWeight.w700,
                            color: primaryText,
                            height: 1.05,
                          ),
                        ),
                        SizedBox(height: _r(context, 4)),
                        Text(
                          greetingSubtitle,
                          style: TextStyle(
                            color: state.status == HomeStatus.failure
                                ? Colors.red.shade600
                                : mutedText,
                            fontSize: _r(context, 13.5),
                          ),
                        ),
                        SizedBox(height: _r(context, 16)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: _r(context, 12),
                            vertical: _r(context, 10),
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFEBF7),
                            borderRadius: BorderRadius.circular(
                              _r(context, 12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search_rounded,
                                color: Color(0xFF8F8AA0),
                                size: _r(context, 22),
                              ),
                              SizedBox(width: _r(context, 8)),
                              Expanded(
                                child: Text(
                                  'Upload or search document',
                                  style: TextStyle(
                                    color: Color(0xFFABA6B7),
                                    fontSize: _r(context, 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: _r(context, 20)),
                        const _PriorityCard(),
                        SizedBox(height: _r(context, 20)),
                        Text(
                          'Print Categories',
                          style: TextStyle(
                            fontSize: _r(context, 25),
                            fontWeight: FontWeight.w700,
                            color: primaryText,
                          ),
                        ),
                        SizedBox(height: _r(context, 12)),
                        _ServicesGrid(
                          categories: state.categories,
                          onPrintTap: _openUploadDocuments,
                        ),
                        SizedBox(height: _r(context, 18)),
                        GestureDetector(
                          onTap: _openUploadDocuments,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: _r(context, 14),
                              vertical: _r(context, 22),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(
                                _r(context, 24),
                              ),
                              border: Border.all(
                                color: const Color(0xFFCBC4DD),
                                style: BorderStyle.solid,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: _r(context, 60),
                                  height: _r(context, 60),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE3DAFB),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.cloud_upload_rounded,
                                    color: accent,
                                    size: _r(context, 30),
                                  ),
                                ),
                                SizedBox(height: _r(context, 14)),
                                Text(
                                  'Upload Document',
                                  style: TextStyle(
                                    fontSize: _r(context, 17),
                                    fontWeight: FontWeight.w700,
                                    color: primaryText,
                                  ),
                                ),
                                SizedBox(height: _r(context, 8)),
                                Text(
                                  'PDF, DOCX or Images up to 50MB',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: _r(context, 13),
                                    color: Color(0xFF646074),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: _r(context, 16)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        color: pageBackground,
        padding: EdgeInsets.fromLTRB(
          _r(context, 12),
          _r(context, 4),
          _r(context, 12),
          _r(context, 10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _BottomItem(
              icon: Icons.home_rounded,
              label: 'HOME',
              active: true,
              compact: compact,
            ),
            _BottomItem(
              icon: Icons.cloud_upload_outlined,
              label: 'UPLOAD',
              compact: compact,
            ),
            _BottomItem(
              icon: Icons.description_outlined,
              label: 'ORDERS',
              compact: compact,
            ),
            _BottomItem(
              icon: Icons.person_outline,
              label: 'PROFILE',
              compact: compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityCard extends StatelessWidget {
  const _PriorityCard();

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20 * compact,
        18 * compact,
        20 * compact,
        18 * compact,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24 * compact),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A20C7), Color(0xFF1946F3)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                color: Colors.white,
                size: 18 * compact,
              ),
              SizedBox(width: 8 * compact),
              Text(
                'PRIORITY SERVICE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.5 * compact,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * compact),
          Text(
            '15-minute\nexpress\ndelivery',
            style: TextStyle(
              color: Colors.white,
              height: 1.15,
              fontSize: 38 * compact,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8 * compact),
          Text(
            'Fastest print-to-door in the city.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16 * compact,
            ),
          ),
          SizedBox(height: 12 * compact),
          Row(
            children: [
              SizedBox(
                height: 44 * compact,
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF3E2EC8),
                    textStyle: TextStyle(
                      fontSize: 14 * compact,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8 * compact),
                    child: Text('Track Live'),
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.bolt_rounded,
                color: Colors.white.withValues(alpha: 0.2),
                size: 62 * compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid({required this.categories, required this.onPrintTap});

  final List<PrintCategoryEntity> categories;
  final VoidCallback onPrintTap;

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    if (categories.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16 * compact),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20 * compact),
        ),
        child: Text(
          'No print categories available yet.',
          style: TextStyle(
            color: const Color(0xFF5D586B),
            fontSize: 14 * compact,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 12 * compact,
      crossAxisSpacing: 12 * compact,
      childAspectRatio: 0.95,
      children: List.generate(categories.length, (index) {
        final category = categories[index];
        return _ServiceTile(
          category: category,
          icon: _resolveCategoryIcon(category.printType),
          background: _resolveTileColor(index),
          titleColor: _resolveTitleColor(index),
          subtitleColor: _resolveSubtitleColor(index),
          onTap: onPrintTap,
        );
      }),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.category,
    required this.icon,
    required this.background,
    required this.titleColor,
    required this.subtitleColor,
    this.onTap,
  });

  final PrintCategoryEntity category;
  final IconData icon;
  final Color background;
  final Color titleColor;
  final Color subtitleColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final compact = _screenScale(context);
    return SizedBox(
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(24 * compact),
        child: InkWell(
          borderRadius: BorderRadius.circular(24 * compact),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(12 * compact),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: background.computeLuminance() < 0.4
                        ? Colors.white.withValues(
                            alpha: 0.15,
                          ) // light overlay for dark bg
                        : Colors.black.withValues(
                            alpha: 0.05,
                          ), // dark overlay for light bg
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: _AvatarIcon(
                      avatarUrl: category.avatar,
                      fallbackIcon: icon,
                      iconColor: background.computeLuminance() < 0.4
                          ? const Color(0xFFE6DAFF)
                          : const Color(0xFF6334DC),
                      compact: compact,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  category.printType,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 6 * compact),
                Text(
                  'Rate: Rs. ${category.rate}',
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 13 * compact,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarIcon extends StatelessWidget {
  const _AvatarIcon({
    required this.avatarUrl,
    required this.fallbackIcon,
    required this.iconColor,
    required this.compact,
  });

  final String avatarUrl;
  final IconData fallbackIcon;
  final Color iconColor;
  final double compact;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl.isEmpty) {
      return Icon(fallbackIcon, color: iconColor, size: 22 * compact);
    }

    return Image.network(
      avatarUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Icon(fallbackIcon, color: iconColor, size: 22 * compact);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Icon(fallbackIcon, color: iconColor, size: 22 * compact);
      },
    );
  }
}

IconData _resolveCategoryIcon(String printType) {
  final normalized = printType.toLowerCase();
  if (normalized.contains('color')) {
    return Icons.palette_outlined;
  }
  if (normalized.contains('lamination')) {
    return Icons.layers_outlined;
  }
  if (normalized.contains('jambo') || normalized.contains('poster')) {
    return Icons.view_agenda_outlined;
  }
  if (normalized.contains('black and white')) {
    return Icons.print_outlined;
  }
  return Icons.description_outlined;
}

Color _resolveTileColor(int index) {
  const palette = <Color>[
    Color(0xFFFFFFFF),
    Color(0xFF5B38D0),
    Color(0xFFE4DEEF),
    Color(0xFFFFFFFF),
  ];
  return palette[index % palette.length];
}

Color _resolveTitleColor(int index) {
  const palette = <Color>[
    Color(0xFF252230),
    Color(0xFFECE6FF),
    Color(0xFF272430),
    Color(0xFF24222B),
  ];
  return palette[index % palette.length];
}

Color _resolveSubtitleColor(int index) {
  const palette = <Color>[
    Color(0xFF4A4657),
    Color(0xFFD6CCF7),
    Color(0xFF4F4A5D),
    Color(0xFF4E495A),
  ];
  return palette[index % palette.length];
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.icon,
    required this.label,
    required this.compact,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final double compact;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF6436E0);
    final inactiveColor = const Color(0xFF99A0B5);

    return Container(
      width: 80 * compact,
      height: 56 * compact,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE8E2FA) : Colors.transparent,
        borderRadius: BorderRadius.circular(24 * compact),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20 * compact,
            color: active ? activeColor : inactiveColor,
          ),
          SizedBox(height: 3 * compact),
          Text(
            label,
            style: TextStyle(
              color: active ? activeColor : inactiveColor,
              fontSize: 10.5 * compact,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
