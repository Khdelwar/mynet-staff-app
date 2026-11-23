import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/staff_api.dart';
import '../api/tickets.dart';
import '../field/drafts.dart';
import '../field/photos.dart';
import '../l10n/app_localizations.dart';
import '../nav/targets.dart';
import '../state/field.dart';
import '../state/providers.dart';
import 'common.dart';
import 'note_photo.dart';
import 'ticket_labels.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  const TicketDetailScreen({super.key, required this.ticketId});

  final int ticketId;

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  TicketDetail? _ticket;
  Object? _error;
  bool _loading = true;
  bool _busy = false;
  DbmReading? _dbm;
  final _comment = TextEditingController();
  final _photos = <String>[];
  String? _clientRef;

  static const _maxPhotos = 5;
  static const _maxPhotoBytes = 5 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    NavTargets.ticket = (id) => TicketDetailScreen(ticketId: id);
    _load();
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ticket = await ref.read(apiProvider).ticket(widget.ticketId);
      if (!mounted) return;
      setState(() {
        _ticket = ticket;
        _loading = false;
      });
      await _flushDrafts();
    } catch (e) {
      if (e is ApiException && e.status == 403) {
        ref.read(authProvider.notifier).refreshProfile().catchError((_) {});
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  Future<void> _flushDrafts() async {
    final store = ref.read(draftStoreProvider);
    final pending = await store.forTicket(widget.ticketId);
    for (final item in pending) {
      try {
        await ref
            .read(apiProvider)
            .addTicketComment(
              widget.ticketId,
              body: item.body,
              clientRef: item.clientRef,
              photoPaths: item.photoPaths,
            );
        await store.remove(item.clientRef);
      } on ApiException catch (e) {
        if (e.isNetwork) return;
      }
    }
    if (pending.isNotEmpty && mounted) {
      final fresh = await ref.read(apiProvider).ticket(widget.ticketId);
      if (mounted) setState(() => _ticket = fresh);
    }
  }

  Future<void> _changeStatus(String status) async {
    final l = AppLocalizations.of(context);
    final ticket = _ticket;
    if (ticket == null || _busy) return;
    String? note;
    String? outcome;
    if (ticket.needsNote(status)) {
      final asked = await _askFinish(status, ticket);
      if (asked == null || !mounted) return;
      note = asked.note;
      outcome = asked.outcome;
    }
    final finishing = ticket.needsNote(status);
    final fix = finishing
        ? await ref.read(locationReaderProvider).current()
        : null;
    final sendFix = fix != null && !fix.isMock;
    await _postStatus(
      status,
      note: note,
      outcome: outcome,
      latitude: sendFix ? fix.latitude : null,
      longitude: sendFix ? fix.longitude : null,
      awayPrompt: l,
    );
  }

  Future<void> _postStatus(
    String status, {
    String? note,
    String? outcome,
    double? latitude,
    double? longitude,
    String? awayReason,
    required AppLocalizations awayPrompt,
  }) async {
    setState(() => _busy = true);
    try {
      final updated = await ref
          .read(apiProvider)
          .setTicketStatus(
            widget.ticketId,
            status: status,
            note: note,
            outcome: outcome,
            latitude: latitude,
            longitude: longitude,
            awayReason: awayReason,
          );
      if (!mounted) return;
      setState(() {
        _ticket = updated;
        _busy = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      final away = e.field('away_reason');
      if (e.status == 422 && away != null && awayReason == null) {
        final reason = await _askAway(away);
        if (reason == null || !mounted) return;
        await _postStatus(
          status,
          note: note,
          outcome: outcome,
          latitude: latitude,
          longitude: longitude,
          awayReason: reason,
          awayPrompt: awayPrompt,
        );
        return;
      }
      _show(errorText(awayPrompt, e, awayPrompt.errGeneric));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _show(errorText(awayPrompt, e, awayPrompt.errGeneric));
    }
  }

  Future<({String note, String? outcome})?> _askFinish(
    String status,
    TicketDetail ticket,
  ) {
    return showDialog<({String note, String? outcome})>(
      context: context,
      builder: (_) => _FinishDialog(status: status, ticket: ticket),
    );
  }

  Future<String?> _askAway(String serverMessage) {
    return showDialog<String>(
      context: context,
      builder: (_) => _AwayDialog(message: serverMessage),
    );
  }

  Future<void> _addPhoto(PhotoSource source) async {
    final l = AppLocalizations.of(context);
    if (_photos.length >= _maxPhotos) {
      _show(l.ticketPhotoLimit);
      return;
    }
    final path = await ref.read(photoPickerProvider).pick(source);
    if (path == null) return;
    try {
      final size = await File(path).length();
      if (size > _maxPhotoBytes) {
        _show(l.ticketPhotoTooBig);
        return;
      }
    } catch (_) {
      _show(l.errGeneric);
      return;
    }
    setState(() => _photos.add(path));
  }

  Future<void> _sendComment() async {
    final l = AppLocalizations.of(context);
    final ticket = _ticket;
    final body = _comment.text.trim();
    if (ticket == null || !ticket.can.comment || body.isEmpty || _busy) return;
    final clientRef = _clientRef ??= newClientRef();
    final pending = PendingComment(
      ticketId: widget.ticketId,
      body: body,
      clientRef: clientRef,
      photoPaths: List.of(_photos),
    );
    setState(() => _busy = true);
    try {
      await ref
          .read(apiProvider)
          .addTicketComment(
            widget.ticketId,
            body: body,
            clientRef: clientRef,
            photoPaths: pending.photoPaths,
          );
      await ref.read(draftStoreProvider).remove(clientRef);
      _clientRef = null;
      FocusManager.instance.primaryFocus?.unfocus();
      _comment.clear();
      _photos.clear();
      if (mounted) setState(() => _busy = false);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (e.isNetwork) {
        await ref.read(draftStoreProvider).upsert(pending);
        _show(l.ticketCommentKept);
        return;
      }
      _show(errorText(l, e, l.errGeneric));
    }
  }

  Future<void> _saveLocation() async {
    final l = AppLocalizations.of(context);
    final client = _ticket?.client;
    if (client == null || _busy) return;
    final fix = await ref.read(locationReaderProvider).current();
    if (!mounted) return;
    if (fix == null) {
      _show(l.ticketLocationDenied);
      return;
    }
    if (fix.isMock) {
      _show(l.ticketLocationMock);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(l.ticketSaveLocation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const ValueKey('confirm-location'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.ticketSend),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final point = await ref
          .read(apiProvider)
          .setClientLocation(
            client.id,
            latitude: fix.latitude,
            longitude: fix.longitude,
            accuracy: fix.accuracy,
          );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _ticket = _copyClient(_ticket!, point);
      });
      _show(l.ticketLocationSaved);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _show(errorText(l, e, l.errGeneric));
    }
  }

  TicketDetail _copyClient(TicketDetail ticket, GeoPoint point) {
    final client = ticket.client;
    if (client == null) return ticket;
    return TicketDetail(
      id: ticket.id,
      subject: ticket.subject,
      type: ticket.type,
      category: ticket.category,
      priority: ticket.priority,
      status: ticket.status,
      role: ticket.role,
      overdue: ticket.overdue,
      slaDueAt: ticket.slaDueAt,
      visitScheduledAt: ticket.visitScheduledAt,
      assignee: ticket.assignee,
      client: TicketClient(
        id: client.id,
        code: client.code,
        name: client.name,
        phone: client.phone,
        address: client.address,
        pppoeUsername: client.pppoeUsername,
        status: client.status,
        location: point,
        onu: client.onu,
      ),
      description: ticket.description,
      helpers: ticket.helpers,
      comments: ticket.comments,
      can: ticket.can,
      nextStatuses: ticket.nextStatuses,
      noteRequiredFor: ticket.noteRequiredFor,
      outcomes: ticket.outcomes,
      finishRadiusM: ticket.finishRadiusM,
      finishDistanceM: ticket.finishDistanceM,
      finishAwayReason: ticket.finishAwayReason,
    );
  }

  Future<void> _checkDbm() async {
    final l = AppLocalizations.of(context);
    final client = _ticket?.client;
    if (client == null || _busy) return;
    setState(() => _busy = true);
    try {
      final reading = await ref.read(apiProvider).checkDbm(client.id);
      if (!mounted) return;
      setState(() {
        _dbm = reading;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _show(errorText(l, e, l.errGeneric));
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'\s'), ''));
    await launchUrl(uri);
  }

  Future<void> _map(GeoPoint point) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${point.latitude},${point.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _show(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ticket = _ticket;
    return Scaffold(
      appBar: AppBar(title: Text(l.pushTicketTitle(widget.ticketId))),
      body: _loading && ticket == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              key: const ValueKey('ticket-detail'),
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  MessageBanner(
                    errorText(l, _error!, l.errGeneric),
                    tone: BannerTone.error,
                  ),
                if (ticket != null) ...[
                  Text(
                    ticket.subject,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  if (ticket.overdue)
                    MessageBanner(l.overdue, tone: BannerTone.warning),
                  SectionCard(
                    children: [
                      InfoRow(l.ticketStatus, statusLabel(l, ticket.status)),
                      InfoRow(
                        l.pushPriority,
                        priorityLabel(l, ticket.priority),
                      ),
                      if (roleLabel(l, ticket.role).isNotEmpty)
                        InfoRow(l.roles, roleLabel(l, ticket.role)),
                      if (ticket.assignee != null)
                        InfoRow(l.roleMain, ticket.assignee!.name),
                      if (ticket.finishDistanceM != null)
                        InfoRow(
                          l.ticketFinishDistance,
                          l.ticketMeters(ticket.finishDistanceM!),
                        ),
                      if (ticket.finishAwayReason != null)
                        InfoRow(l.ticketAwayTitle, ticket.finishAwayReason),
                    ],
                  ),
                  if (ticket.description != null)
                    SectionCard(
                      title: l.ticketDescription,
                      children: [Text(ticket.description!)],
                    ),
                  if (ticket.client != null) _clientCard(l, ticket),
                  if (ticket.can.updateStatus)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final status in ticket.nextStatuses)
                          FilledButton(
                            key: ValueKey('status-$status'),
                            onPressed: _busy
                                ? null
                                : () => _changeStatus(status),
                            child: Text(statusLabel(l, status)),
                          ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Text(
                    l.ticketComments,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (ticket.comments.isEmpty)
                    MessageBanner(l.ticketNoComments),
                  for (final comment in ticket.comments) _commentTile(comment),
                  if (ticket.can.comment) ...[
                    TextField(
                      key: const ValueKey('comment-body'),
                      controller: _comment,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: l.ticketNote),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _addPhoto(PhotoSource.camera),
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: Text(l.ticketTakePhoto),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _addPhoto(PhotoSource.gallery),
                          icon: const Icon(Icons.photo_outlined),
                          label: Text(l.ticketAddPhoto),
                        ),
                      ],
                    ),
                    if (_photos.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(l.ticketPhotoCount(_photos.length)),
                      ),
                    const SizedBox(height: 8),
                    FilledButton(
                      key: const ValueKey('comment-send'),
                      onPressed: _busy ? null : _sendComment,
                      child: Text(l.ticketSend),
                    ),
                  ],
                ],
              ],
            ),
    );
  }

  Widget _clientCard(AppLocalizations l, TicketDetail ticket) {
    final client = ticket.client!;
    final onu = client.onu;
    return SectionCard(
      title: client.name ?? l.featureClients,
      children: [
        InfoRow(l.clientCode, client.code),
        InfoRow(l.clientAddress, client.address),
        InfoRow(l.clientPppoe, client.pppoeUsername),
        if (onu != null) ...[
          InfoRow(l.onuSn, onu.sn),
          InfoRow(l.onuMac, onu.mac),
          InfoRow(l.onuPort, onu.ponPort),
          if (onu.lastRxDbm != null)
            InfoRow(l.ticketDbmRx, onu.lastRxDbm!.toString()),
        ],
        if (_dbm != null) ...[
          InfoRow(l.ticketDbmRx, _dbm!.rxDbm?.toString()),
          InfoRow(l.ticketDbmTx, _dbm!.txDbm?.toString()),
          InfoRow(l.ticketDbmLevel, _dbm!.level),
          if (_dbm!.message != null) Text(_dbm!.message!),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (client.phone != null)
              OutlinedButton.icon(
                key: const ValueKey('call-client'),
                onPressed: () => _call(client.phone!),
                icon: const Icon(Icons.call),
                label: Text(l.ticketCall),
              ),
            if (client.location != null)
              OutlinedButton.icon(
                key: const ValueKey('open-map'),
                onPressed: () => _map(client.location!),
                icon: const Icon(Icons.map_outlined),
                label: Text(l.ticketMap),
              ),
            if (ticket.can.setLocation)
              OutlinedButton.icon(
                key: const ValueKey('save-location'),
                onPressed: _busy ? null : _saveLocation,
                icon: const Icon(Icons.place_outlined),
                label: Text(l.ticketLocation),
              ),
            if (ticket.can.checkDbm)
              OutlinedButton.icon(
                key: const ValueKey('check-dbm'),
                onPressed: _busy ? null : _checkDbm,
                icon: const Icon(Icons.network_check),
                label: Text(l.ticketDbm),
              ),
          ],
        ),
      ],
    );
  }

  Widget _commentTile(TicketComment comment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(comment.author ?? '—'),
            const SizedBox(height: 4),
            Text(comment.body),
            for (final photo in comment.photos)
              if (photo.isImage && photo.displayUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: NotePhoto(
                    url: photo.displayUrl!,
                    authenticated: photo.authenticated,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _FinishDialog extends StatefulWidget {
  const _FinishDialog({required this.status, required this.ticket});

  final String status;
  final TicketDetail ticket;

  @override
  State<_FinishDialog> createState() => _FinishDialogState();
}

class _FinishDialogState extends State<_FinishDialog> {
  final _note = TextEditingController();
  late String? _outcome = widget.ticket.outcomes.contains('done')
      ? 'done'
      : (widget.ticket.outcomes.isEmpty ? null : widget.ticket.outcomes.first);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final closed = widget.status == 'closed';
    return AlertDialog(
      title: Text(statusLabel(l, widget.status)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.ticket.type == 'new_connection' && closed)
              MessageBanner(l.ticketNewConnectionHint),
            TextField(
              key: const ValueKey('status-note'),
              controller: _note,
              maxLines: 3,
              decoration: InputDecoration(labelText: l.ticketNote),
            ),
            if (closed && widget.ticket.outcomes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final item in widget.ticket.outcomes)
                    FilterChip(
                      key: ValueKey('outcome-$item'),
                      label: Text(outcomeLabel(l, item)),
                      selected: _outcome == item,
                      onSelected: (_) => setState(() => _outcome = item),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const ValueKey('status-save'),
          onPressed: () {
            final note = _note.text.trim();
            if (note.isEmpty) return;
            if (closed && (_outcome == null || _outcome!.isEmpty)) return;
            Navigator.of(context)
                .pop((note: note, outcome: closed ? _outcome : null));
          },
          child: Text(l.ticketSend),
        ),
      ],
    );
  }
}

class _AwayDialog extends StatefulWidget {
  const _AwayDialog({required this.message});

  final String message;

  @override
  State<_AwayDialog> createState() => _AwayDialogState();
}

class _AwayDialogState extends State<_AwayDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.ticketAwayTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MessageBanner(widget.message, tone: BannerTone.warning),
          TextField(
            key: const ValueKey('away-reason'),
            controller: _reason,
            maxLines: 3,
            decoration: InputDecoration(labelText: l.ticketAwayHint),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const ValueKey('away-save'),
          onPressed: () {
            final text = _reason.text.trim();
            if (text.length < 5 || text.length > 255) return;
            Navigator.of(context).pop(text);
          },
          child: Text(l.ticketSend),
        ),
      ],
    );
  }
}
