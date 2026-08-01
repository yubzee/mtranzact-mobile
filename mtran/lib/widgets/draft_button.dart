import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salepro/providers/common_data_provider.dart';
import 'package:salepro/providers/offline_submission_provider.dart';
import 'package:salepro/screens/drafts_screen.dart';
import 'package:salepro/utils/icon_mapper.dart';

class DraftButton extends StatelessWidget {
  final String? filterUrl;

  const DraftButton({super.key, this.filterUrl});

  @override
  Widget build(BuildContext context) {
    final submissions = context.watch<OfflineSubmissionProvider>().submissions;
    final count = filterUrl != null
        ? submissions.where((s) => s.url == filterUrl).length
        : submissions.length;

    if (count == 0) return const SizedBox.shrink();

    return IconButton(
      icon: Badge(
        label: Text(count.toString()),
        child: IconMapper.icon(
          'refresh',
          iconPack:
              context.watch<CommonDataProvider>().currentThemeSetting?.iconPack,
        ),
      ),
      tooltip: 'Some content aren\'t synced. Tap to sync them.',
      onPressed: () async {
        // Check connectivity and sync if online
        final commonDataProvider = context.read<CommonDataProvider>();
        await commonDataProvider.checkInternet();

        if (!commonDataProvider.noInternet) {
          if (context.mounted) {
            context.read<OfflineSubmissionProvider>().syncSubmissions(context);
          }
        }

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DraftsScreen(filterUrl: filterUrl),
            ),
          );
        }
      },
    );
  }
}
