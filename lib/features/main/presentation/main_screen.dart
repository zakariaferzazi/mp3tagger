import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'package:mp3tageditor/core/services/audio_editor_service.dart';
import 'package:mp3tageditor/core/services/file_picker_service.dart';
import 'package:mp3tageditor/core/services/purchase_service.dart';
import 'package:mp3tageditor/core/widgets/gradient_bottom_bar.dart';
import 'package:mp3tageditor/features/home/presentation/albums_screen.dart';
import 'package:mp3tageditor/features/home/presentation/artists_screen.dart';
import 'package:mp3tageditor/features/home/presentation/audios_screen.dart';
import 'package:mp3tageditor/features/home/presentation/library_refresh_provider.dart';
import 'package:mp3tageditor/features/home/presentation/library_provider.dart';
import 'package:mp3tageditor/features/settings/presentation/settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  bool _isImporting = false;

  final List<Widget> _screens = const [
    AudiosScreen(),
    AlbumsScreen(),
    ArtistsScreen(),
    SettingsScreen(),
  ];

  Future<void> _importFromCenterButton() async {
    if (_isImporting) {
      print('Import already in progress, skipping');
      return;
    }

    setState(() => _isImporting = true);

    try {
      final audioService = ref.read(audioEditorServiceProvider);
      final remaining = await audioService.getRemainingFreeEdits();
      if (remaining == 0) {
        if (mounted) {
          try {
            await RevenueCatUI.presentPaywallIfNeeded("premium");
            final newInfo =
                await audioService.purchaseService.getCustomerInfo();
            ref.read(customerInfoProvider.notifier).updateInfo(newInfo);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Could not load subscriptions at this time.'),
                ),
              );
            }
          }

          final updatedRemaining = await audioService.getRemainingFreeEdits();
          if (updatedRemaining == 0) return;
        } else {
          return;
        }
      }

      final filePickerService = ref.read(filePickerServiceProvider);
      final sourceFiles = await filePickerService.pickAudioFiles();

      if (sourceFiles == null || sourceFiles.isEmpty) return;

      final imported = await ref
          .read(selectedFilesProvider.notifier)
          .addFiles(sourceFiles);

      if (imported.isNotEmpty) {
        await audioService.consumeFreeUse();
      }

      if (!mounted || imported.isEmpty) return;

      setState(() {
        _currentIndex = 0;
      });

      await context.push('/editor', extra: imported.first.path);
      if (!mounted) return;

      ref.read(libraryRefreshProvider.notifier).markUpdated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error importing audio: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: FloatingActionButton(
          onPressed: _isImporting ? null : _importFromCenterButton,
          backgroundColor: const Color(0xFF17FF45),
          foregroundColor: const Color(0xFF0D0F14),
          elevation: 14,
          shape: const CircleBorder(),
          child:
              _isImporting
                  ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF0D0F14),
                      ),
                    ),
                  )
                  : const Icon(Icons.add, size: 30),
        ),
      ),
      bottomNavigationBar: GradientBottomBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        hasCenterGap: true,
        centerGapWidth: 78,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.music_note),
            activeIcon: Icon(CupertinoIcons.music_note_list),
            label: 'Audios',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.music_albums),
            activeIcon: Icon(CupertinoIcons.music_albums_fill),
            label: 'Albums',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_3),
            activeIcon: Icon(CupertinoIcons.person_3_fill),
            label: 'Artists',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            activeIcon: Icon(CupertinoIcons.settings_solid),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
