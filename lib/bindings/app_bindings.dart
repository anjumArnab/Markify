import 'package:get/get.dart';
import '../controllers/academic_records_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AcademicRecordsController>(
      () => AcademicRecordsController(),
    );
  }
}
