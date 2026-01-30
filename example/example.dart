import 'dart:async';

import 'package:semaphore/semaphore.dart';

Future<void> main(List<String> args) async {
  const maxCount = 3;
  final running = <int>[];
  var simultaneous = 0;
  final sm = LocalSemaphore(maxCount);
  final tasks = <Future<void>>[];
  for (var i = 0; i < 9; i++) {
    tasks.add(Future(() async {
      try {
        await sm.acquire();
        running.add(i);
        if (simultaneous < running.length) {
          simultaneous = running.length;
        }

        print('Start $i, running $running');
        await _doWork(100);
        running.remove(i);
        print('End   $i, running $running');
      } finally {
        sm.release();
      }
    }));
  }

  await Future.wait(tasks);
  print('Max permits: $maxCount, max of simultaneously running: $simultaneous');
}

Future<void> _doWork(int ms) {
  // Simulate work
  return Future.delayed(Duration(milliseconds: ms));
}
