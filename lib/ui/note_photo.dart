import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';

/// First paint of a note photo. [failed] runs when that paint cannot show it.
typedef NotePhotoAttempt = Widget Function(String url, void Function() failed);

/// Public URL first. Private storage answers 401/403, so the error path
/// retries the same URL with the session Bearer token.
Widget publicNotePhoto(String url, void Function() failed) {
  return Image.network(
    url,
    height: 160,
    width: double.infinity,
    fit: BoxFit.cover,
    errorBuilder: (_, _, _) {
      failed();
      return const SizedBox(
        key: ValueKey('note-photo-loading'),
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      );
    },
  );
}

final notePhotoAttemptProvider = Provider<NotePhotoAttempt>(
  (ref) => publicNotePhoto,
);

class NotePhoto extends ConsumerStatefulWidget {
  const NotePhoto({super.key, required this.url});

  final String url;

  @override
  ConsumerState<NotePhoto> createState() => _NotePhotoState();
}

class _NotePhotoState extends ConsumerState<NotePhoto> {
  Uint8List? _bytes;
  var _authStarted = false;
  var _broken = false;

  void _failPublic() {
    if (_authStarted) return;
    _authStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _download();
    });
  }

  Future<void> _download() async {
    try {
      final bytes = await ref.read(apiProvider).authorizedBytes(widget.url);
      if (!mounted) return;
      setState(() => _bytes = bytes);
    } catch (_) {
      if (!mounted) return;
      setState(() => _broken = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_broken) {
      return const Icon(Icons.broken_image, key: ValueKey('note-photo-broken'));
    }
    final bytes = _bytes;
    if (bytes != null) {
      return Image.memory(
        bytes,
        key: const ValueKey('note-photo-bytes'),
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.broken_image, key: ValueKey('note-photo-broken')),
      );
    }
    return ref.read(notePhotoAttemptProvider)(widget.url, _failPublic);
  }
}
