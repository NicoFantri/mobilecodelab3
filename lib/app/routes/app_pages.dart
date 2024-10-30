import 'package:get/get.dart';
import 'package:codelab3/app/modules/home/views/home_view.dart';
import 'package:codelab3/app/modules/home/views/register_page.dart';
import 'package:codelab3/app/modules/home/views/login_page.dart';
import '../modules/screens/home_screen.dart';
import '../modules/screens/create_task_screen.dart';

part 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.HOME_VIEW;

  static final routes = [
    GetPage(
      name: Routes.HOME_VIEW,
      page: () => HomeView(),
    ),
    GetPage(
      name: Routes.REGISTER,
      page: () => RegisterPage(),
    ),
    GetPage(
      name: Routes.LOGIN,
      page: () => LoginPage(),
    ),
    GetPage(
        name: Routes.HOME_SCREEN, 
        page: () => HomeScreen(),
      
    ),
    GetPage(
      name: Routes.CREATE_TASK,
      page: () => CreateTaskScreen(isEdit: true,),

    ),
  ];
}