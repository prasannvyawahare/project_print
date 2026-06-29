class OnboardingStep {
  const OnboardingStep({
    required this.title,
    required this.description,
    required this.highlight,
    required this.image,
  });

  final String title;
  final String description;
  final String highlight;

  /// Asset path of the illustration shown in the hero card for this step.
  final String image;
}
