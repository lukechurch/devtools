import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../../shared/globals.dart';
import '../idg_controller.dart';
import '../idg_core.dart' as idg_core;

var _s0 = idg_core.Step(
  title: 'Describe the problem',
  text: '',
  hasInputField: true,
  nextStepGuard:
      idg_core.PresenceSensor('description-done', 'description done'),
  buttons: [
    idg_core.Action('Done', () async {
      final IDGController idgController = globals[IDGController];
      idgController.log(
        LogData(
          'description-done',
          '',
          DateTime.now().millisecondsSinceEpoch,
        ),
      );
    })
  ],
);

var _s1 = idg_core.Step(
  title: 'Reproduce the problem',
  text: '''
      Click the Devtools app until you encounter the problem, and then click done below''',
  nextStepGuard: idg_core.MaskUntil(
    () => _s0.isDone,
    idg_core.PresenceSensor('reproduction-done', 'reproduction done'),
  ),
  buttons: [
    idg_core.Action('Done', () async {
      final IDGController idgController = globals[IDGController];
      idgController.log(
        LogData(
          'reproduction-done',
          '',
          DateTime.now().millisecondsSinceEpoch,
        ),
      );
    })
  ],
);

var _s2 = idg_core.Step(
  title: 'File issue',
  text: '''
      Submit your description and your reproduction logs to the devtools GitHub repository.''',
  nextStepGuard: idg_core.MaskUntil(
    () => _s1.isDone,
    idg_core.PresenceSensor('mem-snapshot', 'snapshot taken'),
  ),
  buttons: [
    idg_core.Action('Create GitHub issue', () async {
      var parsedUrl =
          Uri.tryParse(devToolsExtensionPoints.issueTrackerLink().url);

      if (parsedUrl != null && await url_launcher.canLaunchUrl(parsedUrl)) {
        final Map<String, String> query = Map.from(parsedUrl.queryParameters);
        query['title'] = 'Enter a title for your issue';
        query['labels'] = 'idg';
        query['body'] = '''${_s0.inputFieldData ?? ''}

TODO: add here data collected by _s1.''';

        parsedUrl = parsedUrl.replace(queryParameters: query);
        await url_launcher.launchUrl(parsedUrl);
      } else {
        print('Unable to open $parsedUrl');
      }
    })
  ],
);

final openGithubIssueRecipe = idg_core.Recipe(
  <idg_core.Step>[_s0, _s1, _s2],
);
