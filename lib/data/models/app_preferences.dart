class AppPreferences {
  final bool isDarkMode;

  AppPreferences({this.isDarkMode = false});

  AppPreferences copyWith({bool? isDarkMode}) {
    return AppPreferences(isDarkMode: isDarkMode ?? this.isDarkMode);
  }

  Map<String, dynamic> toJson() {
    return {'isDarkMode': isDarkMode};
  }

  factory AppPreferences.fromJson(Map<String, dynamic> json) {
    return AppPreferences(isDarkMode: json['isDarkMode'] as bool? ?? false);
  }
}
