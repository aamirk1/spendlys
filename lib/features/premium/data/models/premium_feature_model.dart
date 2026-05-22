class PremiumFeature {
  final String icon;
  final String title;
  final String subtitle;

  PremiumFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  factory PremiumFeature.fromJson(Map<String, dynamic> json) {
    return PremiumFeature(
      icon: json['icon'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'icon': icon,
      'title': title,
      'subtitle': subtitle,
    };
  }
}
