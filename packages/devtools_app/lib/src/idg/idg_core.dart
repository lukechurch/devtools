class Recipe {
  Recipe(this.steps);

  List<Step> steps;

  Set<Sensor> get allSensors {
    final Set<Sensor> sensors = Set<Sensor>();
    for (var step in steps) {
      sensors.add(step.nextStepGuard);
    }
    return sensors;
  }
}

class Action {
  String name;

  Action(this.name);
}

class Step {
  Step(this.title, this.text, this.nextStepGuard, this.action);

  String title;
  String text;
  Sensor nextStepGuard;
  Action action;
}

abstract class Sensor {
  Sensor(this.presentationName, this.sensorName);

  String presentationName;
  String sensorName;

  void trigger(IDGEvent e);
}

class PresenceSensor extends Sensor {
  PresenceSensor(String presentationName, String sensorName)
      : super(presentationName, sensorName);

  bool triggered;

  @override
  void trigger(IDGEvent e) {
    triggered = true;
  }
}

class CountingSensor extends Sensor {
  CountingSensor(String presentationName, String sensorName, {this.counter = 0})
      : super(presentationName, sensorName);

  int counter;
  @override
  void trigger(IDGEvent e) {
    counter++;
  }
}

class IDGEvent {
  const IDGEvent(this.eventName, this.eventData);
  final String eventName;
  final String eventData;
}

class IDGEngine {
  Set<Sensor> _senorsEventsToWatch;
  Set<Recipe> _recipesToWatch;
  // List<IDGEvent> events = [];

  void addRecipes(Recipe r) {
    _recipesToWatch.add(r);
    _senorsEventsToWatch.addAll(r.allSensors);
  }

  void notifyOfEvent(IDGEvent event) {
    for (Sensor sensor in _senorsEventsToWatch) {
      if (sensor.sensorName == event.eventName) {
        sensor.trigger(event);
      }
    }
  }
}