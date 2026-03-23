import 'dart:convert';
import 'dart:js_interop';

@JS('amplitudeTrack')
external void _amplitudeTrack(JSString eventName, JSString propsJson);

@JS('amplitudeIdentify')
external void _amplitudeIdentify(JSString userId);

@JS('amplitudeReset')
external void _amplitudeReset();

class AnalyticsService {
  AnalyticsService._();
  static final instance = AnalyticsService._();

  void track(String event, [Map<String, Object>? properties]) {
    final json = properties != null ? jsonEncode(properties) : '{}';
    _amplitudeTrack(event.toJS, json.toJS);
  }

  void identify(String userId) => _amplitudeIdentify(userId.toJS);

  void reset() => _amplitudeReset();

  // ── Convenience methods ──

  void modeSelected(String mode) =>
      track('mode_selected', {'mode': mode});

  void tickerEntered(String ticker) =>
      track('ticker_entered', {'ticker': ticker});

  void analysisStarted(String ticker, String mode) =>
      track('analysis_started', {'ticker': ticker, 'mode': mode});

  void analysisCompleted(String ticker, String mode, int score) =>
      track('analysis_completed', {
        'ticker': ticker,
        'mode': mode,
        'score': score,
      });

  void analysisError(String ticker, String mode, String error) =>
      track('analysis_error', {
        'ticker': ticker,
        'mode': mode,
        'error': error,
      });

  void login(String email) => track('login', {'email': email});

  void register(String email) => track('register', {'email': email});

  void logout() => track('logout');

  void pricingViewed() => track('pricing_viewed');

  void themeToggled(bool isDark) =>
      track('theme_toggled', {'is_dark': isDark});

  void localeToggled(String locale) =>
      track('locale_toggled', {'locale': locale});
}
