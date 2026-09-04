class Announcement {
  final String title, content;
  final String? englishTitle, englishContent;
  final DateTime dateTime;

  // The url of the announcement
  final String? url;

  // The url of any possible files attached to the announcement (can me many)
  final List<String> fileUrls;

  const Announcement({
    required this.title,
    required this.content,
    required this.dateTime,
    this.url,
    this.fileUrls = const [],
    this.englishTitle,
    this.englishContent,
  });

  String getLocalizedTitle(String languageCode) {
    if (languageCode == "en") {
      return englishTitle ?? title;
    }
    return title;
  }

  String getLocalizedContent(String languageCode) {
    if (languageCode == "en") {
      return englishContent ?? content;
    }
    return content;
  }

}
