import 'package:get_it/get_it.dart';
import 'services/live_bus_service.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton<LiveBusService>(() => LiveBusService());
}
