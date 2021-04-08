# semaphore

Semaphore is lightweight data type that is used for controlling the cooperative access to a common resource inside the isolate.

Version: 0.2.0

### Examples:

Semaphore example:

```dart
import 'dart:async';

import 'package:semaphore/semaphore.dart';

Future<void> main(List<String> args) async {
  final maxCount = 3;
  final running = <int>[];
  var simultaneous = 0;
  final sm = LocalSemaphore(maxCount);
  final tasks = <Future>[];
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
  print('Max permits: $maxCount, max simultaneous runned: $simultaneous');
}

Future _doWork(int ms) {
  // Simulate work
  return Future.delayed(Duration(milliseconds: ms));
}

```

**Output:**

```
Start 0, running [0]
Start 1, running [0, 1]
Start 2, running [0, 1, 2]
End   0, running [1, 2]
Start 3, running [1, 2, 3]
End   1, running [2, 3]
Start 4, running [2, 3, 4]
End   2, running [3, 4]
Start 5, running [3, 4, 5]
End   3, running [4, 5]
Start 6, running [4, 5, 6]
End   4, running [5, 6]
Start 7, running [5, 6, 7]
End   5, running [6, 7]
Start 8, running [6, 7, 8]
End   6, running [7, 8]
End   7, running [8]
End   8, running []
Max permits: 3, max simultaneous runned: 3
```

Conditional variables example:

```dart
import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:semaphore/lock.dart';
import 'package:semaphore/condition_variable.dart';

Future<void> main() async {
  await Future.wait([
    _producer('one'),
    _producer('two'),    
    _consumer('one'),
    _consumer('two'),
    _consumer('three'),
  ]);
}

final _cvEmpty = ConditionVariable(_lock);
final _cvFull = ConditionVariable(_lock);
final _lock = Lock();
final _queue = Queue<int>();
var counter = 0;

Future<void> _doWork(int max) async {
  final milliseconds = Random().nextInt(max);
  await Future.delayed(Duration(milliseconds: milliseconds));
}

Future<void> _producer(String id) async {
  while (true) {
    await lock(_lock, () async {
      while (_queue.length >= 2) {
        print('producer $id: wait $_queue');
        await _cvFull.wait();
      }

      print('producer $id: $counter');
      await _doWork(1000);
      _queue.add(counter++);
      await _cvEmpty.signal();
    });
  }
}

Future<void> _consumer(String id) async {
  while (true) {
    int number;
    await lock(_lock, () async {
      while (_queue.isEmpty) {
        print('consumer $id: wait $_queue');
        await _cvEmpty.wait();
      }

      number = _queue.removeFirst();
      await _cvFull.signal();
    });

    print('consumer $id: $number');
    await _doWork(1000);
    print(number);
  }
}

```