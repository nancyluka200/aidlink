import 'package:get/get.dart';
import 'auth_controller.dart';

class InitialBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<AuthController>(AuthController(), permanent: true);
  }
}