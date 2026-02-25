

import 'dart:convert';
import 'dart:io';

// ── ANSI codes ───────
const _reset     = '\x1B[0m';
const _green     = '\x1B[32m';
const _red       = '\x1B[31m';
const _cyan      = '\x1B[36m';
const _gray      = '\x1B[90m';
const _bold      = '\x1B[1m';
const _bgGreen   = '\x1B[42m';
const _bgRed     = '\x1B[41m';
const _hideCursor = '\x1B[?25l';
const _showCursor = '\x1B[?25h';

// ── Test files ─────────
const _testFiles = [
  'test/utils/time_utils_test.dart',
  'test/services/preferences_service_test.dart',
  'test/services/raw_time_store_test.dart',
  'test/services/cross_check_service_test.dart',
  'test/controllers/live_entry_controller_test.dart',
  'test/pages/login_page_test.dart',
  'test/pages/utilities_page_test.dart',
  'test/pages/cross_check_page_test.dart',
  'test/pages/review_sync_page_test.dart',
  'test/pages/live_entry_page_test.dart',
];

// ── Per-suite tracking ──────
class _Suite {
  final String label;
  int passed = 0;
  int failed = 0;
  _Suite(this.label);
  bool get ok => failed == 0;
  int get total => passed + failed;
}

// ── Pre-scan: count testWidgets()/test() calls in every file before running ──
// Gives the correct denominator instantly, with no cross-run state needed.
int _prescanTestCount() {
  final re = RegExp(r'^\s*(testWidgets|test)\s*\(', multiLine: true);
  var total = 0;
  for (final path in _testFiles) {
    try {
      total += re.allMatches(File(path).readAsStringSync()).length;
    } catch (_) {}
  }
  return total;
}

// ── Live state ───────────
var _totalTests     = 0;   // denominator — set from pre-scan, grows if needed
var _discoveredTests = 0;  // actual count from group events (safety fallback)
var _passed         = 0;
var _failed         = 0;
var _currentTest    = 'Compiling…';
var _linesDrawn     = 0;

final _suites       = <int, _Suite>{};   // suiteID  → Suite
final _testToSuite  = <int, int>{};      // testID   → suiteID
final _knownIds     = <int>{};           // real (non-hidden) test IDs

// ── Progress bar rendering ──────
void _redraw() {
  if (_linesDrawn > 0) {
    stdout.write('\x1B[${_linesDrawn}A');
    for (var i = 0; i < _linesDrawn; i++) {
      stdout.write('\x1B[2K\n');
    }
    stdout.write('\x1B[${_linesDrawn}A');
  }

  const barWidth = 50;
  final completed = _passed + _failed;
  final pct = _totalTests > 0 ? (completed * 100 / _totalTests).round() : 0;

  final bar = StringBuffer('[');
  if (_totalTests > 0) {
    final g = (_passed  * barWidth / _totalTests).round().clamp(0, barWidth);
    final r = (_failed  * barWidth / _totalTests).round().clamp(0, barWidth - g);
    final e = barWidth - g - r;
    for (var i = 0; i < g; i++) { bar.write('$_bgGreen $_reset'); }
    for (var i = 0; i < r; i++) { bar.write('$_bgRed $_reset'); }
    for (var i = 0; i < e; i++) { bar.write(' '); }
  } else {
    for (var i = 0; i < barWidth; i++) { bar.write(' '); }
  }
  bar.write(']');

  final pctStr  = _totalTests > 0 ? '  $pct%  ($completed/$_totalTests)' : '';
  final failStr = _failed > 0 ? '  $_red$_bold✗ $_failed failed$_reset' : '';

  const maxLen = 72;
  final label = _currentTest.length > maxLen
      ? '…${_currentTest.substring(_currentTest.length - maxLen + 1)}'
      : _currentTest;

  stdout.write('  ${bar.toString()}$pctStr\n');
  stdout.write('  $_green$_bold✓ $_passed passed$_reset$failStr\n');
  stdout.write('  $_cyan▶ $label$_reset\n');
  _linesDrawn = 3;
}

// ── Suite summary table ───────────
void _printSuiteSummary() {
  stdout.writeln('\n$_bold  Suite Results$_reset');

  for (final suite in _suites.values) {
    final icon   = suite.ok ? '$_green✓$_reset' : '$_red✗$_reset';
    final counts = '$_gray(${suite.passed}/${suite.total} tests)$_reset';
    final name   = suite.ok
        ? '$_bold${suite.label}$_reset'
        : '$_bold$_red${suite.label}$_reset';
    stdout.writeln('  $icon  ${name.padRight(45)}  $counts');
  }

}

// ── Entry point ──────────
Future<void> main() async {
  stdout.write(_hideCursor);

  // Restore cursor on Ctrl-C then exit — subscription cancelled via exit()
  ProcessSignal.sigint.watch().listen((_) {
    stdout.write('\n$_showCursor');
    exit(130);
  });

  stdout.writeln('\n$_bold${_cyan}OST Remote Pro — Test Runner$_reset');
  stdout.writeln('$_cyan${'─ ' * 10}$_reset\n');
  _totalTests = _prescanTestCount();  // count tests before running — stable from frame one
  _redraw();

  final process = await Process.start(
    'flutter',
    ['test', '--reporter', 'json', ..._testFiles],
    runInShell: true,
  );

  // Close stdin — prevents flutter test from hanging waiting for keypresses
  await process.stdin.close();

  // Discard stderr so it never blocks the process
  process.stderr.listen((_) {});

  await for (final line in process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())) {
    Map<String, dynamic> event;
    try {
      event = jsonDecode(line) as Map<String, dynamic>;
    } catch (_) {
      continue;
    }

    switch (event['type'] as String?) {
      case 'suite':
        final s      = event['suite'] as Map<String, dynamic>;
        final id     = s['id'] as int;
        final path   = s['path'] as String? ?? '';
        final label  = path.split('/').last.replaceAll('_test.dart', '');
        _suites[id]  = _Suite(label);
        _currentTest = 'Compiling $label…';
        _redraw();

      case 'group':
        final group = event['group'] as Map<String, dynamic>;
        if (group['parentID'] == null) {
          _discoveredTests += (group['testCount'] as int? ?? 0);
          // Expand denominator if more tests exist than the cached value
          if (_discoveredTests > _totalTests) {
            _totalTests = _discoveredTests;
          }
          _redraw();
        }

      case 'testStart':
        final test    = event['test'] as Map<String, dynamic>;
        final id      = test['id'] as int;
        final name    = test['name'] as String? ?? '';
        final suiteId = test['suiteID'] as int;
        // Skip synthetic "loading /absolute/path.dart" events
        if (name.isEmpty || name.startsWith('loading ')) { break; }
        _knownIds.add(id);
        _testToSuite[id] = suiteId;
        final suiteName  = _suites[suiteId]?.label ?? '';
        _currentTest = suiteName.isNotEmpty ? '$suiteName › $name' : name;
        _redraw();

      case 'testDone':
        final id     = event['testID'] as int;
        final hidden = event['hidden'] as bool? ?? false;
        if (!hidden && _knownIds.contains(id)) {
          final result  = event['result'] as String?;
          final suiteId = _testToSuite[id];
          final suite   = suiteId != null ? _suites[suiteId] : null;
          if (result == 'success') {
            _passed++;
            suite?.passed++;
          } else if (result == 'failure' || result == 'error') {
            _failed++;
            suite?.failed++;
          }
          _redraw();
        }
    }
  }

  final code = await process.exitCode;

  _currentTest = code == 0 ? 'All tests complete!' : 'Done — some tests failed.';
  _redraw();
  stdout.write(_showCursor);

  _printSuiteSummary();

  stdout.writeln('\n$_cyan${'─ ' * 10}$_reset');
  if (_failed == 0) {
    stdout.writeln('$_bold$_green  ✓ All $_passed tests passed!$_reset\n');
  } else {
    stdout.writeln('$_bold$_green  ✓ Passed: $_passed$_reset');
    stdout.writeln('$_bold$_red  ✗ Failed: $_failed$_reset\n');
  }

  // Explicit exit so dangling stream subscriptions don't keep the VM alive
  exit(code == 0 ? 0 : 1);
}
