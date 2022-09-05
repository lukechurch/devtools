// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../screens/inspector/inspector_service.dart';
import '../screens/logging/logging_controller.dart';
import '../shared/globals.dart' as globals;
import 'idg_core.dart';
import 'idg_screen.dart';
import 'idg_server.dart';
import 'idg_apis.dart' as api;

export '../screens/logging/logging_controller.dart';

// For performance reasons, we drop old logs in batches, so the log will grow
// to kMaxLogItemsUpperBound then truncate to kMaxLogItemsLowerBound.
const int kMaxLogItemsLowerBound = 5000;
const int kMaxLogItemsUpperBound = 5500;
final DateFormat timeFormat = DateFormat('HH:mm:ss.SSS');

class IDGController {
  late CommPortListener listener;

  IDGController() {
    api.EventsAPI events =
        api.EventsAPI(this, globals.messageBus, globals.serviceManager);
    idgEngine = IDGEngine();
    for (var recipe in idgRecipes.keys) {
      idgEngine.addRecipes(recipe, idgRecipes[recipe]!);
    }
    // Log comms port events
    listener = CommPortListener(this, 'vscode');
  }

  late IDGEngine idgEngine;

  void log(LogData log) =>
      idgEngine.notifyOfEvent(IDGEvent(log.kind, log.details!));

  Stream get onEngineUpdated => idgEngine.updatesController.stream;

  ValueListenable<bool> get idgVisible => _idgVisible;

  final _idgVisible = ValueNotifier<bool>(false);

  void toggleIDGVisible(bool visible) => _idgVisible.value = visible;
}

class CommPortListener {
  CommPortListener(this.idgController, this.name, {this.isError = false}) {
    print('CommPort init');

    final IDGServer server = IDGServer(idgController);
    server.start();
  }

  final IDGController idgController;
  final String name;
  final bool isError;
}
