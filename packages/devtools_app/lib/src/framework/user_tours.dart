import 'package:flutter/material.dart';

import '../../devtools_app.dart';
import '../shared/common_widgets.dart';
import '../shared/globals.dart';
import '../shared/theme.dart';

class OpenAppToursAction extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _OpenAppToursActionState();
}

class _OpenAppToursActionState extends State<OpenAppToursAction>
    with AutoDisposeMixin {
  late bool isVisible;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    isVisible = userToursController.userToursVisible.value;
    addAutoDisposeListener(userToursController.userToursVisible, () {
      setState(() {
        isVisible = userToursController.userToursVisible.value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DevToolsTooltip(
      message: 'User Tours',
      child: InkWell(
        onTap: () async {
          userToursController.toggleUserToursVisible(!isVisible);
        },
        child: Container(
          width: actionWidgetSize,
          height: actionWidgetSize,
          alignment: Alignment.center,
          child: Icon(
            Icons.assignment,
            size: actionsIconSize,
            color: isVisible ? theme.primaryColorLight : Colors.white,
          ),
        ),
      ),
    );
  }
}
