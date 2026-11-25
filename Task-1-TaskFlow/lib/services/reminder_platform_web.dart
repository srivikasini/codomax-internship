import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('Notification')
extension type _JSNotification._(JSObject _) implements JSObject {
  external factory _JSNotification(
    String title, [
    _JSNotificationOptions options,
  ]);
  external static String get permission;
  external static JSPromise<JSString> requestPermission();
}

extension type _JSNotificationOptions._(JSObject _) implements JSObject {
  external factory _JSNotificationOptions({String? body, String? tag});
}

@JS('AudioContext')
extension type _JSAudioContext._(JSObject _) implements JSObject {
  external factory _JSAudioContext();
  external _JSOscillatorNode createOscillator();
  external _JSGainNode createGain();
  external _JSAudioNode get destination;
  external double get currentTime;
  external JSPromise<JSAny?> resume();
}

extension type _JSAudioNode._(JSObject _) implements JSObject {
  external void connect(_JSAudioNode destination);
}

extension type _JSOscillatorNode._(JSObject _) implements _JSAudioNode {
  external set type(String value);
  external _JSAudioParam get frequency;
  external void start([double when]);
  external void stop([double when]);
}

extension type _JSGainNode._(JSObject _) implements _JSAudioNode {
  external _JSAudioParam get gain;
}

extension type _JSAudioParam._(JSObject _) implements JSObject {
  external set value(double value);
  external void setValueAtTime(double value, double startTime);
  external void exponentialRampToValueAtTime(double value, double endTime);
}

@JS('window')
external _JSWindow get _window;

extension type _JSWindow._(JSObject _) implements JSObject {
  external JSObject? open(String url, String target);
}

bool get isBrowserAlertSupported => globalContext.has('Notification');

String get browserNotificationPermission {
  if (!isBrowserAlertSupported) return 'unsupported';
  try {
    return _JSNotification.permission;
  } catch (_) {
    return 'default';
  }
}

Future<String> requestBrowserNotificationPermission() async {
  if (!isBrowserAlertSupported) return 'unsupported';
  try {
    final result = await _JSNotification.requestPermission().toDart;
    return result.toDart;
  } catch (_) {
    return browserNotificationPermission;
  }
}

Future<void> triggerBrowserAlert({
  required String title,
  required String body,
  bool playSound = true,
}) async {
  if (playSound) {
    _playWebAlarmChime();
  }

  if (isBrowserAlertSupported && browserNotificationPermission == 'granted') {
    try {
      _JSNotification(
        title,
        _JSNotificationOptions(
          body: body,
          tag: 'taskflow-alarm',
        ),
      );
    } catch (_) {
      // Ignore browser notification exceptions if blocked by OS/browser focus rules.
    }
  }
}

void _playWebAlarmChime() {
  if (!globalContext.has('AudioContext')) return;
  try {
    final ctx = _JSAudioContext();
    ctx.resume();
    final baseTime = ctx.currentTime;
    const notes = [587.33, 783.99, 987.77]; // D5, G5, B5 pleasant alert chime

    for (var i = 0; i < notes.length; i++) {
      final start = baseTime + (i * 0.16);
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();

      osc.type = 'sine';
      osc.frequency.setValueAtTime(notes[i], start);

      gain.gain.setValueAtTime(0.001, start);
      gain.gain.exponentialRampToValueAtTime(0.18, start + 0.02);
      gain.gain.exponentialRampToValueAtTime(0.001, start + 0.24);

      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(start);
      osc.stop(start + 0.25);
    }
  } catch (_) {
    // Ignore autoplay restriction errors before user gesture.
  }
}

Future<bool> openEmailDraft({
  required String toEmail,
  required String subject,
  required String body,
}) async {
  try {
    final encodedSubject = Uri.encodeComponent(subject);
    final encodedBody = Uri.encodeComponent(body);
    final recipient = Uri.encodeComponent(toEmail.trim());
    final uri = 'mailto:$recipient?subject=$encodedSubject&body=$encodedBody';
    _window.open(uri, '_self');
    return true;
  } catch (_) {
    return false;
  }
}
