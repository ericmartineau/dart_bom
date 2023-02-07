// ALl

import 'package:completion/completion.dart';

Future main(List<String> arguments) async {
  final script = generateCompletionScript([
    'pubinfo',
    'allpub',
    'lastpub',
    'myversion',
    'repospec',
    'syncbom',
    'checkout',
  ]);

  print(script);
}
