import 'package:get/get.dart';
import 'package:aidlinkapp/screens/home_page.dart';
import 'package:aidlinkapp/screens/memo_page.dart';

class Routes {
  static String homePage = '/home_page';
  static String memoPage = '/memo_page';
}

final getPages = [
  GetPage(
    name: Routes.homePage,
    page: () => const HomePage(),
  ),
  GetPage(
  name: Routes.memoPage,
  page: () =>  MemoPage(),
),
];