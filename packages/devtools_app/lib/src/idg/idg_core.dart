import 'dart:async';
import 'dart:convert';

import 'package:vm_service/vm_service.dart';

class Recipe {
  Recipe(this.steps);

  List<Step> steps;

  Set<Sensor> get allSensors {
    final Set<Sensor> sensors = Set<Sensor>();
    for (var step in steps) {
      sensors.add(step.nextStepGuard!);
    }
    return sensors;
  }

  void reset() => steps.forEach((element) {
        element.reset();
      });
}

class Action {
  String name;
  Future Function() onClick;

  Action(this.name, this.onClick);
}

class Step {
  Step({
    this.title,
    this.text,
    this.imageUrl,
    this.imageMaxHeight,
    this.nextStepGuard,
    this.isTitleButton = false,
    this.buttons = const <Action>[],
  });

  String? title;
  late bool isTitleButton;
  String? text;
  String? imageUrl;
  double? imageMaxHeight;
  Sensor? nextStepGuard;
  // Action action;
  bool get isDone => nextStepGuard!.isDone;
  bool isActive = false;
  List<Action> buttons;

  void reset() => nextStepGuard!.reset();
}

abstract class Sensor {
  Sensor(this.sensorName, this.presentationName);

  String presentationName;
  String sensorName;

  void trigger(IDGEvent e);
  String valueString();
  bool get isDone;

  void reset();
}

class PerfSensor extends Sensor {
  int elapsedMsThreshold;
  PerfSensor(sensorName, presentationName, this.elapsedMsThreshold)
      : super(sensorName, presentationName) {
    reset();
  }

  late bool triggered;
  late int elapsedMilliseconds;

  @override
  void trigger(IDGEvent e) {
    print(e.eventData);
    int elapsedMs =
        json.decode(e.eventData)["extensionData"]["elapsedMilliseconds"];

    triggered = elapsedMs < elapsedMsThreshold;
    if (triggered) this.elapsedMilliseconds = elapsedMs;
  }

  @override
  String valueString() =>
      triggered ? '($triggered: $elapsedMilliseconds ms)' : '(false)';

  @override
  bool get isDone => triggered;

  @override
  void reset() {
    triggered = false;
  }
}

class PresenceSensor extends Sensor {
  PresenceSensor(sensorName, presentationName)
      : super(sensorName, presentationName) {
    reset();
  }

  late bool triggered;

  @override
  void trigger(IDGEvent e) {
    triggered = true;
  }

  @override
  String valueString() => '($triggered)';

  @override
  bool get isDone => triggered;

  @override
  void reset() {
    triggered = false;
  }
}

class FileChangeSensor extends Sensor {
  String filePath;

  FileChangeSensor(sensorName, presentationName, this.filePath)
      : super(sensorName, presentationName) {
    reset();
  }

  late bool triggered;

  @override
  void trigger(IDGEvent e) {
    // idg?arg=IDG report: [4:44:28 AM] onDidChangeTextDocument /Users/lukechurch/GitRepos/LCC/idg_sample_apps/image_list/lib/main.dart
    if (e.eventData.contains("onDidChangeTextDocument") &&
        e.eventData.contains(filePath)) triggered = true;
  }

  @override
  String valueString() => '($triggered)';

  @override
  bool get isDone => triggered;

  @override
  void reset() {
    triggered = false;
  }
}

class CondAnd extends Sensor {
  Sensor sensor;
  bool Function() cond;

  CondAnd(bool Function() this.cond, this.sensor)
      : super(sensor.sensorName, sensor.presentationName);

  @override
  String valueString() => sensor.valueString();

  @override
  bool get isDone => cond() && sensor.isDone;

  @override
  void trigger(IDGEvent e) => sensor.trigger(e);

  @override
  void reset() {
    sensor.reset();
  }
}

class MaskUntil extends Sensor {
  Sensor sensor;
  bool Function() cond;

  MaskUntil(bool Function() this.cond, this.sensor)
      : super(sensor.sensorName, sensor.presentationName);

  @override
  String valueString() => sensor.valueString();

  @override
  bool get isDone => cond() && sensor.isDone;

  @override
  void trigger(IDGEvent e) {
    if (cond()) sensor.trigger(e);
  }

  @override
  void reset() {
    sensor.reset();
  }
}

class CountingSensor extends Sensor {
  CountingSensor(String presentationName, String sensorName, {this.counter = 0})
      : super(presentationName, sensorName) {
    reset();
  }

  int counter;
  @override
  void trigger(IDGEvent e) {
    counter++;
  }

  @override
  String valueString() => '($counter)';

  @override
  bool get isDone => counter > 0;

  @override
  void reset() {
    counter = 0;
  }
}

class IDGEvent {
  const IDGEvent(this.eventName, this.eventData);
  final String eventName;
  final String eventData;
}

class IDGEngine {
  final Set<Sensor> _senorsEventsToWatch = <Sensor>{};
  final Map<String, Recipe> _recipesToWatch = <String, Recipe>{};
  String? selectedRecipe;

  final StreamController<bool> updatesController = StreamController.broadcast();

  Recipe getRecipe() {
    return _recipesToWatch[selectedRecipe]!;
  }
  // List<IDGEvent> events = [];

  void addRecipes(String name, Recipe r) {
    print("IDG addRecipes $r");
    _recipesToWatch[name] = r;
    selectedRecipe ??= name;
    print("IDG addRecipes - adding sensors ${r.allSensors}");
    _senorsEventsToWatch.addAll(r.allSensors);
  }

  void selectRecipe(String name) {
    assert(_recipesToWatch.keys.contains(name));
    selectedRecipe = name;
    reset();
    updatesController.add(true);
  }

  void notifyOfEvent(IDGEvent event) {
    bool sensorSeen = false;

    for (Sensor sensor in _senorsEventsToWatch) {
      // DEBUG for matching diagnostics
      // print(
      //     "Sensor Name for test: ${event.eventName} == ${sensor.sensorName}, match: ${sensor.sensorName == event.eventName}");
      if (sensor.sensorName == event.eventName) {
        print("IDG: Triggering sensor: ${sensor.sensorName}");
        sensor.trigger(event);
        _updateActiveSteps();
        sensorSeen = true;
      }
    }
    // DEBUG
    // if (!sensorSeen)
    //   print(
    //       "IDG: No sensor found for : ${event.eventName} : ${event.eventData}");
  }

  void _updateActiveSteps() {
    for (var r in _recipesToWatch.values) {
      bool seenInactiveStep = false;
      for (var step in r.steps) {
        if (!step.isDone && !seenInactiveStep) {
          seenInactiveStep = true;
          step.isActive = true;
        } else {
          step.isActive = false;
        }
      }
    }
    updatesController.add(true);
  }

  void reset() {
    for (var recipe in _recipesToWatch.values) {
      recipe.reset();
    }
  }
}
