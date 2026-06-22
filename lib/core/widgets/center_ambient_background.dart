import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CenterAmbientBackground extends StatelessWidget {
  const CenterAmbientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shortestSide = constraints.biggest.shortestSide;
          final baseSize = (shortestSide * 1.2).clamp(280.0, 460.0);
          final orangeSize = baseSize;
          final blueSize = baseSize * 10.08;

          return Stack(
            fit: StackFit.expand,
            children: [
              Transform.translate(
                offset: Offset(-baseSize * 0.09, -baseSize * 0.09),
                child: Opacity(
                  opacity: 0.92,
                  child: SvgPicture.asset(
                    'assets/decorations/background_blur.svg',
                    width: orangeSize,
                    height: orangeSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(baseSize * 0.1, baseSize * 0.06),
                child: Opacity(
                  opacity: 0.92,
                  child: SvgPicture.asset(
                    'assets/decorations/decorative_ambient_background_elements.svg',
                    width: blueSize,
                    height: blueSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
