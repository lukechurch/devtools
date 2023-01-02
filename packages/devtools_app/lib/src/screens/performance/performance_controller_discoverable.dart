import '../../../devtools_app.dart';
import '../../extensibility/discoverable.dart';

class DiscoverablePerformancePage extends DiscoverablePage {
  DiscoverablePerformancePage(this.controller) : super() {
    discoverableApp.pages[id] = this;
  }

  final PerformanceController controller;

  static String get id => PerformanceScreen.id;

  // Events

  // Actions
  void selectFrame(int index) {
    controller.flutterFramesController.handleSelectedFrame(
      controller.flutterFramesController.flutterFrames.value[index],
    );
  }

  @override
  void highlightElement(String key) {
    // TODO: implement highlightElement
  }

  @override
  void selectElement(String key) {
    // TODO: implement selectElement
  }
}
