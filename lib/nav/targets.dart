import 'package:flutter/widgets.dart';

/// Pages registered by later screens so a notification tap opens the real
/// ticket or offer list. Until a screen registers, the shell uses a short
/// fallback that still shows which ticket or offer was tapped.
class NavTargets {
  static Widget Function(int ticketId)? ticket;

  static Widget Function(int? offerId, int? ticketId)? offers;
}
