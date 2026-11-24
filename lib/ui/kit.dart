import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/json.dart';
import '../api/staff_api.dart';
import '../l10n/app_localizations.dart';
import '../state/providers.dart';
import 'common.dart';

/// Shared pieces for the work screens. Every number shown here (money, due,
/// balance) is the ERP's; the app only formats it.

final _moneyFormat = NumberFormat('#,##0.##', 'en');

/// `৳ 1,250` (minus kept as given by the ERP).
String money(Object? value) {
  final n = toNum(value);
  return n == null ? '—' : '৳ ${_moneyFormat.format(n)}';
}

String plainNumber(Object? value) {
  final n = toNum(value);
  return n == null ? '—' : _moneyFormat.format(n);
}

/// `2026-11-23T10:01:00+06:00` → `23 Nov 2026, 10:01` (phone's time zone).
String when(Object? iso, {bool time = true}) {
  if (iso is! String || iso.isEmpty) return '—';
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  final local = parsed.toLocal();
  return DateFormat(time ? 'd MMM yyyy, HH:mm' : 'd MMM yyyy').format(local);
}

String today() => DateFormat('yyyy-MM-dd').format(DateTime.now());

String thisMonth() => DateFormat('yyyy-MM').format(DateTime.now());

/// Loads with [load], shows a spinner, an error with retry, or [builder].
/// Pull down to reload. Call `reload` after an action to show the ERP's new state.
class Loader extends ConsumerStatefulWidget {
  const Loader({super.key, required this.load, required this.builder});

  final Future<Json> Function(StaffApi api) load;
  final Widget Function(
    BuildContext context,
    Json data,
    Future<void> Function() reload,
  )
  builder;

  @override
  ConsumerState<Loader> createState() => _LoaderState();
}

class _LoaderState extends ConsumerState<Loader> {
  Json? _data;
  Object? _error;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await widget.load(ref.read(apiProvider));
      if (!mounted) return;
      setState(() {
        _data = data;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      _refreshOn403(ref, e);
      setState(() {
        _error = e;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (_busy && _data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _data == null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MessageBanner(
            errorText(l, _error!, l.errGeneric),
            tone: BannerTone.error,
          ),
          FilledButton(onPressed: _reload, child: Text(l.retry)),
        ],
      );
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: widget.builder(context, _data!, _reload),
    );
  }
}

/// A 403 means the ERP took a permission away: re-read `/me` so the home
/// screen drops buttons the user no longer has.
void _refreshOn403(WidgetRef ref, Object error) {
  if (error is ApiException && error.status == 403) {
    ref.read(authProvider.notifier).refreshProfile().catchError((_) {});
  }
}

/// Runs an ERP call from a button: shows the ERP's refusal as a snackbar and
/// returns null, or the reply. [done] is shown on success.
Future<Json?> act(
  BuildContext context,
  WidgetRef ref,
  Future<Json> Function(StaffApi api) call, {
  String? done,
}) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    final res = await call(ref.read(apiProvider));
    if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
    return res;
  } catch (e) {
    _refreshOn403(ref, e);
    messenger.showSnackBar(
      SnackBar(content: Text(errorText(l, e, l.errGeneric))),
    );
    return null;
  }
}

/// A screen with a title bar, used for every pushed page.
class WorkPage extends StatelessWidget {
  const WorkPage({
    super.key,
    required this.title,
    required this.body,
    this.fab,
    this.actions,
  });
  final String title;
  final Widget body;
  final Widget? fab;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), actions: actions),
    body: SafeArea(child: body),
    floatingActionButton: fab,
  );
}

Future<T?> open<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

/// A small coloured label for a status / priority word from the ERP.
class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.tone});
  final String text;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = tone ?? scheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

Color priorityColor(BuildContext context, String? priority) =>
    switch (priority) {
      'urgent' => Colors.red.shade700,
      'high' => Colors.orange.shade800,
      'medium' => Theme.of(context).colorScheme.primary,
      _ => Theme.of(context).colorScheme.outline,
    };

/// One line of text asked in a dialog. Returns null when cancelled.
Future<String?> askText(
  BuildContext context, {
  required String title,
  String? label,
  String initial = '',
  bool required = false,
  bool number = false,
  int maxLines = 1,
}) {
  final l = AppLocalizations.of(context);
  final controller = TextEditingController(text: initial);
  final key = GlobalKey<FormState>();
  return showDialog<String>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(title),
      content: Form(
        key: key,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          maxLines: maxLines,
          keyboardType: number
              ? const TextInputType.numberWithOptions(decimal: true)
              : null,
          decoration: InputDecoration(labelText: label),
          validator: (v) => required && (v == null || v.trim().isEmpty)
              ? l.fieldRequired
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (key.currentState!.validate()) {
              Navigator.pop(dialog, controller.text.trim());
            }
          },
          child: Text(l.ok),
        ),
      ],
    ),
  );
}

Future<bool> confirm(BuildContext context, String text) async {
  final l = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      content: Text(text),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialog, true),
          child: Text(l.ok),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Photos from the camera or gallery (paths on the phone), or [] when cancelled.
Future<List<String>> pickPhotos(BuildContext context, {int max = 5}) async {
  final l = AppLocalizations.of(context);
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l.photoCamera),
            onTap: () => Navigator.pop(sheet, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l.photoGallery),
            onTap: () => Navigator.pop(sheet, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return const [];
  final picker = ImagePicker();
  try {
    if (source == ImageSource.camera || max == 1) {
      final one = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1600,
      );
      return one == null ? const [] : [one.path];
    }
    final many = await picker.pickMultiImage(
      imageQuality: 70,
      maxWidth: 1600,
      limit: max,
    );
    return many.take(max).map((f) => f.path).toList();
  } catch (_) {
    return const [];
  }
}

/// A phone location: what the ERP's duty / finish / house-GPS calls take.
typedef Spot = ({double latitude, double longitude, double accuracy});

/// The phone's location now, asked only when the user taps something that
/// needs it. Null when location is off or refused (the ERP then decides).
/// A provider so tests can stand in for the GPS.
final locatorProvider = Provider<Future<Spot?> Function()>(
  (ref) => _deviceSpot,
);

Future<Spot?> _deviceSpot() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
    return (latitude: p.latitude, longitude: p.longitude, accuracy: p.accuracy);
  } catch (_) {
    return null;
  }
}

Future<void> callPhone(String? phone) async {
  if (phone == null || phone.isEmpty) return;
  await launchUrl(Uri(scheme: 'tel', path: phone));
}

/// Opens the phone's map app at the client's house.
Future<void> openMap(Object? location) async {
  final m = asMap(location);
  final lat = toNum(m['latitude']);
  final lng = toNum(m['longitude']);
  if (lat == null || lng == null) return;
  await launchUrl(
    Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
    mode: LaunchMode.externalApplication,
  );
}

/// An empty list's message, inside a scrollable so pull-to-refresh works.
class EmptyList extends StatelessWidget {
  const EmptyList(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [MessageBanner(text)],
  );
}

/// Picks a client by search (name, ID, phone, PPPoE). Returns the client JSON.
/// Uses `/clients` for users with `clients.view`, else the collector search
/// (`/collection/clients`, which shows only name, ID and phone and due when allowed).
Future<Json?> pickClient(BuildContext context, {String? path}) =>
    open<Json>(context, _ClientPicker(path));

class _ClientPicker extends ConsumerStatefulWidget {
  const _ClientPicker(this.path);
  final String? path;

  @override
  ConsumerState<_ClientPicker> createState() => _ClientPickerState();
}

class _ClientPickerState extends ConsumerState<_ClientPicker> {
  final _q = TextEditingController();
  List<dynamic> _found = const [];
  bool _busy = false;
  Object? _error;

  Future<void> _search() async {
    final q = _q.text.trim();
    if (q.length < 2) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = ref.read(authProvider).user;
      final path =
          widget.path ??
          (user?.can('clients.view') ?? false
              ? '/clients'
              : '/collection/clients');
      final res = await ref.read(apiProvider).get(path, query: {'q': q});
      if (!mounted) return;
      setState(() => _found = asList(res['clients']));
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return WorkPage(
      title: l.pickClient,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _q,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              labelText: l.clientSearchHint,
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _search,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null)
            MessageBanner(
              errorText(l, _error!, l.errGeneric),
              tone: BannerTone.error,
            ),
          for (final c in _found.map(asMap))
            Card(
              child: ListTile(
                title: Text(
                  '${pickString(c, const ['name']) ?? ''} · ${pickString(c, const ['code']) ?? ''}',
                ),
                subtitle: Text(
                  [
                    pickString(c, const ['phone']),
                    if (c['due'] != null) '${l.due}: ${money(c['due'])}',
                  ].whereType<String>().join(' · '),
                ),
                onTap: () => Navigator.pop(context, c),
              ),
            ),
        ],
      ),
    );
  }
}
