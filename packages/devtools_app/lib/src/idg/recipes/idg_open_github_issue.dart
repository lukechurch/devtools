import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../../../devtools_app.dart';
import '../idg_core.dart' as idg_core;

var _s0 = idg_core.Step(
  title: 'Describe the problem',
  text: '',
  hasInputField: true,
  nextStepGuard:
      idg_core.PresenceSensor('description-done', 'description done'),
  buttons: [
    idg_core.Action(
      'Done',
      () async =>
          eventsManager.addEvent(StructuredLogEvent('description-done')),
    ),
  ],
);

DateTime? _timestampS1;
var _s1 = idg_core.Step(
  title: 'Start reproducing the problem',
  text: '''
      Click the start button below when you're ready to reproduce the issue.
      
      Use your app for a few seconds, during which we will record the number
      of time the garbage collector runs.''',
  nextStepGuard: idg_core.MaskUntil(
    () => _s0.isDone,
    idg_core.PresenceSensor('start-reproduction', 'start reproduction'),
  ),
  buttons: [
    idg_core.Action('Start', () async {
      _timestampS1 = DateTime.now();
      _countingSensorStart = _gcCountingSensor!.counter;
      eventsManager.addEvent(StructuredLogEvent('start-reproduction'));
    }),
  ],
);

//idg_core.CountingSensor('gc', 'garbage collection seen'),

idg_core.CountingSensor? _gcCountingSensor;
var _s2 = idg_core.Step(
  title: 'Record GC events',
  text: '',
  nextStepGuard: idg_core.MaskUntil(
    () => _s1.isDone,
    _gcCountingSensor =
        idg_core.CountingSensor('gc', 'garbage collection seen'),
  ),
  buttons: [],
);

DateTime? _timestampS2;
int _countingSensorStart = 0;
int _countingSensorEnd = 0;
var _s3 = idg_core.Step(
  title: 'Finish reproducing the problem',
  text: '''
      At least 1 GC event was recorded. Use the app for a while longer, then
      click the stop button.''',
  nextStepGuard: idg_core.MaskUntil(
    () => _s1.isDone,
    idg_core.PresenceSensor('stop-reproduction', 'stop reproduction'),
    // idg_core.CountingSensor('gc', 'garbage collection seen'),
  ),
  buttons: [
    idg_core.Action('Done', () async {
      _timestampS2 = DateTime.now();
      _countingSensorEnd = _gcCountingSensor!.counter;
      eventsManager.addEvent(StructuredLogEvent('stop-reproduction'));
    }),
  ],
);

var _s4 = idg_core.Step(
  title: 'File issue',
  text: '''
      Submit your description and performance info to the devtools GitHub repository.''',
  nextStepGuard: idg_core.MaskUntil(
    () => _s3.isDone,
    idg_core.PresenceSensor(
        'issue-opened-successfully', 'issue opened successfully'),
  ),
  buttons: [
    idg_core.Action('Create GitHub issue', () async {
      var parsedUrl =
          Uri.tryParse(devToolsExtensionPoints.issueTrackerLink().url);

      if (parsedUrl != null && await url_launcher.canLaunchUrl(parsedUrl)) {
        final Map<String, String> query = Map.from(parsedUrl.queryParameters);
        query['title'] = '';
        query['labels'] = 'from-idg';
        query['body'] = '''${_s0.inputFieldData ?? ''}

===== Perf data
${_countingSensorEnd - _countingSensorStart} GC events in ${_timestampS2!.difference(_timestampS1!).inMilliseconds} ms''';

        parsedUrl = parsedUrl.replace(queryParameters: query);
        final success = await url_launcher.launchUrl(parsedUrl);
        if (success) {
          eventsManager
              .addEvent(StructuredLogEvent('issue-opened-successfully'));
        }
      } else {
        print('Unable to open $parsedUrl');
      }
    })
  ],
);

final openGithubIssueRecipe = idg_core.Recipe(
  <idg_core.Step>[_s0, _s1, _s2, _s3, _s4],
);
