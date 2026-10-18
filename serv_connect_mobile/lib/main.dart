import 'package:serv_connect_mobile/bootstrap.dart';
import 'package:serv_connect_mobile/core/config/flavor_config.dart';

Future<void> main() async {
  await bootstrap(flavor: Flavor.dev);
}
