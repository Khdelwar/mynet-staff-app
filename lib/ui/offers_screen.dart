import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/offers.dart';
import '../api/staff_api.dart';
import '../l10n/app_localizations.dart';
import '../nav/targets.dart';
import '../state/providers.dart';
import 'common.dart';

class OffersScreen extends ConsumerStatefulWidget {
  const OffersScreen({super.key, this.offerId});

  /// The offer a push named. The list still comes from the ERP.
  final int? offerId;

  @override
  ConsumerState<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends ConsumerState<OffersScreen> {
  List<JobOffer> _offers = const [];
  Object? _error;
  bool _loading = true;
  int? _busy;

  @override
  void initState() {
    super.initState();
    NavTargets.offers = (offerId, _) => OffersScreen(offerId: offerId);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final offers = await ref.read(apiProvider).offers();
      if (!mounted) return;
      setState(() {
        _offers = offers;
        _loading = false;
      });
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

  Future<void> _accept(JobOffer offer) async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = offer.id);
    try {
      final ticket = await ref.read(apiProvider).acceptOffer(offer.id);
      if (!mounted) return;
      _show(l.offerAccepted(ticket.id));
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      _show(e.field('offer') ?? errorText(l, e, l.errGeneric));
      setState(() => _busy = null);
    } catch (e) {
      if (!mounted) return;
      _show(errorText(l, e, l.errGeneric));
      setState(() => _busy = null);
    }
  }

  Future<void> _reject(JobOffer offer) async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = offer.id);
    try {
      await ref.read(apiProvider).rejectOffer(offer.id);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      _show(errorText(l, e, l.errGeneric));
      setState(() => _busy = null);
    }
  }

  void _show(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.featureOffers)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null)
              MessageBanner(
                errorText(l, _error!, l.errGeneric),
                tone: BannerTone.error,
              ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_offers.isEmpty)
              MessageBanner(l.offersEmpty),
            for (final offer in _offers)
              Card(
                key: ValueKey('offer-${offer.id}'),
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.ticket?.subject ??
                            l.offerTicket(offer.ticket?.id ?? 0),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (offer.ticket?.clientName != null)
                        Text(offer.ticket!.clientName!),
                      Text(l.offerSeconds(offer.secondsLeft)),
                      if (offer.distanceM != null)
                        Text(l.offerDistance(offer.distanceM!)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          FilledButton(
                            key: ValueKey('accept-${offer.id}'),
                            onPressed: _busy == null
                                ? () => _accept(offer)
                                : null,
                            child: Text(l.offerAccept),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            key: ValueKey('reject-${offer.id}'),
                            onPressed: _busy == null
                                ? () => _reject(offer)
                                : null,
                            child: Text(l.offerReject),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
