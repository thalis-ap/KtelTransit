import 'package:flutter/material.dart';
import 'package:ktel_transit/l10n/app_localizations.dart';
import 'package:ktel_transit/models/announcement.dart';
import 'package:ktel_transit/models/region.dart';
import 'package:ktel_transit/repositories/gtfs_repository.dart';
import 'package:ktel_transit/utilities/region_utils.dart';
import 'package:ktel_transit/widgets/custom_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utilities/time_format.dart';
import '../widgets/custom_loading_indicator.dart';
import '../widgets/region_info_banner.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final GtfsRepository repository = GtfsRepository();

  bool isLoading = false;

  List<Announcement> announcements = [];

  @override
  void initState() {
    _fetchAnnouncements();
    super.initState();
  }

  void _fetchAnnouncements() async {
    setState(() {
      isLoading = true;
    });

    // TODO fetch announcements
    await Future.delayed(Duration(seconds: 1));
    announcements.addAll([
      Announcement(
        title: "Δοκιμαστικός τίτλος 1",
        content:
            "Δοκιμαστικό περιεχόμενο. Εδω θα λεει τις πληροφοριες της ανακοινωσης",
        dateTime: DateTime.now(),
        englishTitle: "English test title 1",
        englishContent:
            "English test content. Switching to english should show this one",
        url: "https://example.com",
        fileUrls: ["https://google.com", "https://example.com"],
      ),
      Announcement(
        title: "Δοκιμαστικός τίτλος 2",
        content:
            "Δοκιμαστικό περιεχόμενο. Εδω θα λεει τις πληροφοριες της ανακοινωσης",
        dateTime: DateTime.now(),
        englishTitle: "English test title 2",
        englishContent:
            "English test content. Switching to english should show this one",
      ),
    ]);

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.announcements), centerTitle: true),
      body: Column(
        children: [
          RegionInfoBanner(
            regionName:
                repository.currentRegion?.getLocalizedName(languageCode) ??
                l10n.notChosen,
            onChangeTap: () => RegionUtils.promptRegionChange(
              context,
              repository,
              availableRegions,
              beforeAction: () {},
              onSelectedAction: () {
                setState(() {
                  isLoading = true;
                });
              },
              afterAction: () {
                setState(() {
                  isLoading = false;
                });
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(
                    child: CustomLoadingIndicator(
                      message: l10n.loadingAnnouncements,
                    ),
                  )
                : announcements.isEmpty
                ? Center(
                    child: Text(
                      l10n.emptyAnnouncements,
                      style: theme.textTheme.titleSmall,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: announcements.length,
                    itemBuilder: (context, index) {
                      final Announcement announcement = announcements[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 6.0,
                          horizontal: 8.0,
                        ),
                        elevation: 2,
                        child: ExpansionTile(
                          shape: const Border(),
                          collapsedShape: const Border(),
                          leading: const Icon(
                            Icons.notifications_none_outlined,
                          ),
                          title: Text(
                            announcement.getLocalizedTitle(languageCode),
                          ),
                          childrenPadding: EdgeInsets.all(20),
                          children: [
                            Row(
                              children: [
                                Icon(Icons.date_range),
                                SizedBox(width: 8),
                                Text(
                                  TimeFormat.dateTimeToFormattedStringFull(
                                    announcement.dateTime,
                                  ),
                                  style: theme.textTheme.titleSmall,
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Text(
                              announcement.getLocalizedContent(languageCode),
                            ),
                            SizedBox(height: 10),
                            if (announcement.url != null)
                              GestureDetector(
                                onTap: () async {
                                  final Uri url = Uri.parse(announcement.url!);
                                  final res = await launchUrl(
                                    url,
                                    mode: LaunchMode.externalApplication,
                                  );
                                  if (!res && context.mounted) {
                                    CustomSnackBar.show(
                                      context,
                                      message: l10n.linkFail,
                                      color: colorScheme.error,
                                    );
                                  }
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.link,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.announcementUrl,
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (announcement.fileUrls.isNotEmpty)
                              Column(
                                children: [
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.insert_drive_file_outlined,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(l10n.attachedFiles),
                                    ],
                                  ),
                                  for (String fileUrl in announcement.fileUrls)
                                    GestureDetector(
                                      onTap: () async {
                                        final Uri url = Uri.parse(fileUrl);
                                        final res = await launchUrl(
                                          url,
                                          mode: LaunchMode.externalApplication,
                                        );
                                        if (!res && context.mounted) {
                                          CustomSnackBar.show(
                                            context,
                                            message: l10n.linkFail,
                                            color: colorScheme.error,
                                          );
                                        }
                                      },
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.link,
                                            size: 16,
                                            color: colorScheme.primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            fileUrl,
                                            style: TextStyle(
                                              color: colorScheme.primary,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
