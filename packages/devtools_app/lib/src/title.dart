// Copyright 2021 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'globals.dart';

void generateDevToolsTitle() {
  if (!serviceManager.connectedAppInitialized) {
    _devToolsTitle.value = 'Developer Tools for Flutter & Dart';
    return;
  }
  _devToolsTitle.value = serviceManager.connectedApp.isFlutterAppNow
      ? 'Flutter Developer Tools'
      : 'Dart DevTools';
}

ValueListenable<String> get devToolsTitle => _devToolsTitle;

ValueNotifier<String> _devToolsTitle = ValueNotifier<String>('');
