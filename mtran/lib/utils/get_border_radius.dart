import 'package:salepro/constants/spacing.dart';

String _normalizeIntensity(String intensity) {
  switch (intensity) {
    case 'small':
      return 'low';
    case 'large':
      return 'high';
    default:
      return intensity;
  }
}

Map<String, double> getBorderRadius(String borderRadius) {
  switch (borderRadius) {
    case 'rounded-none':
      return {
        'low': AppSpacing.kDefaultSpacing(null) * 0,
        'medium': AppSpacing.kDefaultSpacing(null) * 0,
        'high': AppSpacing.kDefaultSpacing(null) * 0.25,
      };
    case 'rounded':
      return {
        'low': AppSpacing.kDefaultSpacing(null) * 0.25,
        'medium': AppSpacing.kDefaultSpacing(null) * 0.5,
        'high': AppSpacing.kDefaultSpacing(null),
      };
    case 'rounded-lg':
      return {
        'low': AppSpacing.kDefaultSpacing(null) * 0.5,
        'medium': AppSpacing.kDefaultSpacing(null) * 1.5,
        'high': AppSpacing.kDefaultSpacing(null) * 2.5,
      };
    case 'rounded-full':
      return {
        'low': AppSpacing.kDefaultSpacing(null) * 2.5,
        'medium': AppSpacing.kDefaultSpacing(null) * 12.5,
        'high': AppSpacing.kDefaultSpacing(null) * 25.0,
      };
    default:
      return {
        'low': AppSpacing.kDefaultSpacing(null) * 0.25,
        'medium': AppSpacing.kDefaultSpacing(null) * 0.5,
        'high': AppSpacing.kDefaultSpacing(null),
      };
  }
}

double getBorderRadiusByIntensity(String borderRadius, String intensity) {
  final normalized = _normalizeIntensity(intensity);
  return getBorderRadius(borderRadius)[normalized] ?? 0.0;
}
