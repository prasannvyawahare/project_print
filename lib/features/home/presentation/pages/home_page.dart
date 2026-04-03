import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../upload/presentation/pages/upload_documents_page.dart'
    show UploadDocumentsPage;
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';

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
  void _openUploadDocuments() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const UploadDocumentsPage()),
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
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: accent,
                      ),
                      const Expanded(
                        child: Text(
                          'PrintHub',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          context.read<HomeBloc>().add(const HomeRequested());
                        },
                        icon: const Icon(Icons.notifications_none_rounded),
                        color: accent,
                      ),
                    ],
                  ),
                ),
                if (state.status == HomeStatus.loading)
                  const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'OVERVIEW',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1.1,
                            color: Color(0xFF494652),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Hi, Alex👋',
                          style: TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.w700,
                            color: primaryText,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          greetingSubtitle,
                          style: TextStyle(
                            color: state.status == HomeStatus.failure
                                ? Colors.red.shade600
                                : mutedText,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFEBF7),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.search_rounded,
                                color: Color(0xFF8F8AA0),
                                size: 26,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Upload or search document',
                                  style: TextStyle(
                                    color: Color(0xFFABA6B7),
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        const _PriorityCard(),
                        const SizedBox(height: 30),
                        const Text(
                          'Print Services',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                            color: primaryText,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ServicesGrid(onPrintTap: _openUploadDocuments),
                        const SizedBox(height: 26),
                        GestureDetector(
                          onTap: _openUploadDocuments,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 32,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: const Color(0xFFCBC4DD),
                                style: BorderStyle.solid,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 74,
                                  height: 74,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE3DAFB),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.cloud_upload_rounded,
                                    color: accent,
                                    size: 36,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                const Text(
                                  'Upload Document',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: primaryText,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'PDF, DOCX or Images up to 50MB',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF646074),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
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
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            _BottomItem(icon: Icons.home_rounded, label: 'HOME', active: true),
            _BottomItem(icon: Icons.cloud_upload_outlined, label: 'UPLOAD'),
            _BottomItem(icon: Icons.description_outlined, label: 'ORDERS'),
            _BottomItem(icon: Icons.person_outline, label: 'PROFILE'),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
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
          const Row(
            children: [
              Icon(Icons.timer_outlined, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'PRIORITY SERVICE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            '15-minute\nexpress\ndelivery',
            style: TextStyle(
              color: Colors.white,
              height: 1.15,
              fontSize: 52,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Fastest print-to-door in the city.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF3E2EC8),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('Track Live'),
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.bolt_rounded,
                color: Colors.white.withValues(alpha: 0.2),
                size: 86,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid({required this.onPrintTap});

  final VoidCallback onPrintTap;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.95,
      children: [
        _ServiceTile(
          icon: Icons.print_outlined,
          title: 'Black & White\nPrint',
          subtitle: 'Starting at\n\$0.05',
          background: Color(0xFFFFFFFF),
          iconTint: Color(0xFF6334DC),
          titleColor: Color(0xFF252230),
          subtitleColor: Color(0xFF4A4657),
          onTap: onPrintTap,
        ),
        _ServiceTile(
          icon: Icons.palette_outlined,
          title: 'Color Print',
          subtitle: 'High-fidelity',
          background: Color(0xFF5B38D0),
          iconTint: Color(0xFFE6DAFF),
          titleColor: Color(0xFFECE6FF),
          subtitleColor: Color(0xFFD6CCF7),
          onTap: onPrintTap,
        ),
        _ServiceTile(
          icon: Icons.menu_book_outlined,
          title: 'Spiral Binding',
          subtitle: 'Professional\nfinish',
          background: Color(0xFFE4DEEF),
          iconTint: Color(0xFF48515D),
          titleColor: Color(0xFF272430),
          subtitleColor: Color(0xFF4F4A5D),
          onTap: onPrintTap,
        ),
        _ServiceTile(
          icon: Icons.grid_view_rounded,
          title: 'Poster\nPrinting',
          subtitle: 'Large format',
          background: Color(0xFFFFFFFF),
          iconTint: Color(0xFF1E5BE0),
          titleColor: Color(0xFF24222B),
          subtitleColor: Color(0xFF4E495A),
          onTap: onPrintTap,
        ),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.background,
    required this.iconTint,
    required this.titleColor,
    required this.subtitleColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color background;
  final Color iconTint;
  final Color titleColor;
  final Color subtitleColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: background.computeLuminance() < 0.4 ? 0.16 : 0.75,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconTint, size: 28),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 17,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF6436E0);
    final inactiveColor = const Color(0xFF99A0B5);

    return Container(
      width: 92,
      height: 64,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE8E2FA) : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: active ? activeColor : inactiveColor),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? activeColor : inactiveColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
