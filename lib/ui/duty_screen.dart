import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/duty.dart';
import '../api/staff_api.dart';
import '../l10n/app_localizations.dart';
import '../state/duty.dart';
import '../state/providers.dart';
import 'common.dart';

class DutyScreen extends ConsumerStatefulWidget {
  const DutyScreen({super.key});

  @override
  ConsumerState<DutyScreen> createState() => _DutyScreenState();
}

class _DutyScreenState extends ConsumerState<DutyScreen> {
  DutySnapshot? _duty;
  Object? _error;
  bool _loading = true;
  bool _busy = false;
  final _queue = <LocationPoint>[];
  StreamSubscription<LocationPoint>? _points;
  int _interval = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _points?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final duty = await ref.read(apiProvider).duty();
      if (!mounted) return;
      setState(() {
        _duty = duty;
        _loading = false;
      });
      if (duty.onDuty) {
        await _follow(duty);
      } else {
        await _stopFollow();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  Future<void> _start() async {
    final l = AppLocalizations.of(context);
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final here = await ref.read(hereProvider)();
    try {
      final duty = await ref
          .read(apiProvider)
          .startDuty(latitude: here?.latitude, longitude: here?.longitude);
      if (!mounted) return;
      setState(() {
        _duty = duty;
        _busy = false;
      });
      if (duty.onDuty) await _follow(duty);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _show(e.field('duty') ?? errorText(l, e, l.errGeneric));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _show(errorText(l, e, l.errGeneric));
    }
  }

  Future<void> _end() async {
    if (_busy) return;
    setState(() => _busy = true);
    await _stopFollow();
    try {
      final duty = await ref.read(apiProvider).endDuty();
      if (!mounted) return;
      setState(() {
        _duty = duty;
        _busy = false;
        _queue.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _show(
        errorText(
          AppLocalizations.of(context),
          e,
          AppLocalizations.of(context).errGeneric,
        ),
      );
    }
  }

  Future<void> _follow(DutySnapshot duty) async {
    final l = AppLocalizations.of(context);
    final title = l.dutyNotificationTitle;
    final body = l.dutyNotificationBody;
    final onTheWay = await _onTheWay();
    if (!mounted) return;
    final seconds = onTheWay
        ? duty.tracking.intervalOnTheWayS
        : duty.tracking.intervalMovingS;
    if (_interval == seconds && _points != null) return;
    await _stopFollow();
    if (!mounted) return;
    final tracker = ref.read(dutyTrackerProvider);
    _interval = seconds;
    _points = tracker.points.listen(_onPoint);
    await tracker.start(intervalSeconds: seconds, title: title, body: body);
  }

  Future<bool> _onTheWay() async {
    try {
      return await ref.read(apiProvider).anyTicketOnTheWay();
    } catch (_) {
      return false;
    }
  }

  Future<void> _onPoint(LocationPoint point) async {
    _queue.add(point);
    await _flush();
  }

  Future<void> _flush() async {
    final duty = _duty;
    if (duty == null || !duty.onDuty || _queue.isEmpty) return;
    final batch = _queue.take(duty.tracking.maxBatch).toList();
    try {
      final result = await ref.read(apiProvider).sendLocations(batch);
      _queue.removeRange(0, batch.length.clamp(0, _queue.length));
      if (!result.onDuty) {
        await _stopFollow();
        if (!mounted) return;
        setState(
          () => _duty = DutySnapshot(onDuty: false, tracking: duty.tracking),
        );
        _show(AppLocalizations.of(context).dutyStopped);
      }
    } on ApiException catch (e) {
      if (e.status == 409 || e.code == 'not_on_duty') {
        _queue.clear();
        await _stopFollow();
        if (mounted) {
          setState(
            () => _duty = DutySnapshot(onDuty: false, tracking: duty.tracking),
          );
          _show(
            errorText(
              AppLocalizations.of(context),
              e,
              AppLocalizations.of(context).dutyStopped,
            ),
          );
        }
      }
    } catch (_) {
      // Kept in the queue and sent with the next point.
    }
  }

  Future<void> _stopFollow() {
    final sub = _points;
    _points = null;
    _interval = 0;
    // Don't wait on the stream subscription: its cancel future can outlive
    // the frame, and duty must stop on the server either way.
    if (sub != null) unawaited(sub.cancel());
    return ref.read(dutyTrackerProvider).stop();
  }

  void _show(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final duty = _duty;
    return Scaffold(
      appBar: AppBar(title: Text(l.featureDuty)),
      body: _loading && duty == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  MessageBanner(
                    errorText(l, _error!, l.errGeneric),
                    tone: BannerTone.error,
                  ),
                if (duty != null && duty.onDuty)
                  MessageBanner(l.dutyNotificationTitle),
                if (duty != null && !duty.withinDutyHours && !duty.onDuty)
                  MessageBanner(l.dutyOutsideHours, tone: BannerTone.warning),
                if (duty != null)
                  SectionCard(
                    children: [
                      InfoRow(l.dutyStatus, duty.onDuty ? l.dutyOn : l.dutyOff),
                      InfoRow(
                        l.dutyHours,
                        '${duty.tracking.dutyStart}–${duty.tracking.dutyEnd}',
                      ),
                      InfoRow(l.dutyTimezone, duty.tracking.timezone),
                      if (duty.session != null)
                        InfoRow(
                          l.dutyDistance,
                          l.dutyMeters(duty.session!.distanceM),
                        ),
                    ],
                  ),
                if (duty != null && duty.onDuty)
                  FilledButton(
                    key: const ValueKey('duty-end'),
                    onPressed: _busy ? null : _end,
                    child: Text(l.dutyEnd),
                  )
                else
                  FilledButton(
                    key: const ValueKey('duty-start'),
                    onPressed: _busy ? null : _start,
                    child: Text(l.dutyStart),
                  ),
              ],
            ),
    );
  }
}
