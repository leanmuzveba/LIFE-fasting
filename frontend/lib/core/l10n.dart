import 'package:flutter/widgets.dart';

import '../domain/fasting_session.dart';
import '../l10n/app_localizations.dart';

export '../l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension SessionTimeErrorText on SessionTimeError {
  String message(AppLocalizations l) => switch (this) {
    SessionTimeError.startInFuture => l.errorStartInFuture,
    SessionTimeError.endInFuture => l.errorEndInFuture,
    SessionTimeError.endBeforeStart => l.errorEndBeforeStart,
  };
}
