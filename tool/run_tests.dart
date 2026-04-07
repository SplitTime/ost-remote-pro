
import 'dart:convert';
import 'dart:io';

// ── ANSI codes ───────
const _reset = '\x1B[0m';
const _green = '\x1B[32m';
const _red   = '\x1B[31m';
const _cyan  = '\x1B[36m';
const _gray  = '\x1B[90m';
const _bold  = '\x1B[1m';

// ── Test files ─────────
const _testFiles = [
  'test/utils/time_utils_test.dart',
  'test/services/preferences_service_test.dart',
  'test/services/raw_time_store_test.dart',
  'test/services/cross_check_service_test.dart',
  'test/controllers/live_entry_controller_test.dart',
  'test/pages/login_page_test.dart',
  'test/pages/signup_page_test.dart',
  'test/widgets/numpad_test.dart',
  'test/widgets/two_state_toggle_test.dart',
  'test/widgets/clock_widget_test.dart',
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

// ── Live state ───────────
var _passed = 0;
var _failed = 0;

final _suites      = <int, _Suite>{};
final _testToSuite = <int, int>{};
final _knownIds    = <int>{};

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
  ProcessSignal.sigint.watch().listen((_) {
    stdout.writeln('');
    exit(130);
  });

  stdout.writeln('\n$_bold${_cyan}OST Remote Pro — Test Runner$_reset');
  stdout.writeln('$_cyan${'─ ' * 10}$_reset');
  stdout.writeln('  Running tests…\n');

  final process = await Process.start(
    'flutter',
    ['test', '--reporter', 'json', ..._testFiles],
    runInShell: true,
  );

  await process.stdin.close();
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
        final s     = event['suite'] as Map<String, dynamic>;
        final id    = s['id'] as int;
        final path  = s['path'] as String? ?? '';
        final label = path.split('/').last.replaceAll('_test.dart', '');
        _suites[id] = _Suite(label);

      case 'testStart':
        final test    = event['test'] as Map<String, dynamic>;
        final id      = test['id'] as int;
        final name    = test['name'] as String? ?? '';
        final suiteId = test['suiteID'] as int;
        if (name.isEmpty || name.startsWith('loading ')) break;
        _knownIds.add(id);
        _testToSuite[id] = suiteId;

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
        }
    }
  }

  final code = await process.exitCode;

  _printSuiteSummary();

  stdout.writeln('\n$_cyan${'─ ' * 10}$_reset');
  if (_failed == 0) {
    stdout.writeln('$_bold$_green  ✓ All $_passed tests passed!$_reset\n');
  } else {
    stdout.writeln('$_bold$_green  ✓ Passed: $_passed$_reset');
    stdout.writeln('$_bold$_red  ✗ Failed: $_failed$_reset\n');
  }

  exit(code == 0 ? 0 : 1);
}
