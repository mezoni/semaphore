# semaphore

Version: 1.0.0

Semaphore is lightweight data type that is used for controlling the cooperative access to a common resource inside the isolate.

## Examples

Semaphore example:

```dart
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

```

**Output:**

```txt
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
Max permits: 3, max of simultaneously running: 3
```

Conditional variables example:

```dart
import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:semaphore/condition_variable.dart';
import 'package:semaphore/lock.dart';

Future<void> main() async {
  await Future.wait([
    _producer('one'),
    _producer('two'),
    _consumer('one'),
    _consumer('two'),
    _consumer('three'),
  ]);
}

var counter = 0;
final _cvEmpty = ConditionVariable(_lock);
final _cvFull = ConditionVariable(_lock);
final _lock = Lock();
final _queue = Queue<int>();

Future<void> _consumer(String id) async {
  while (true) {
    late int result;
    await lock(_lock, () async {
      while (_queue.isEmpty) {
        print('consumer $id: wait, queue $_queue');
        await _cvEmpty.wait();
      }

      print('consumer $id: queue $_queue');
      result = _queue.removeFirst();
      await _cvFull.signal();
    });

    print('consumer $id: doWork');
    await _doWork(1000);
    print('consumer $id: work done, result $result');
  }
}

Future<void> _doWork(int max) async {
  final milliseconds = Random().nextInt(max);
  await Future<void>.delayed(Duration(milliseconds: milliseconds));
}

Future<void> _producer(String id) async {
  while (true) {
    await lock(_lock, () async {
      while (_queue.length >= 2) {
        print('producer $id: wait, queue $_queue');
        await _cvFull.wait();
      }

      print('producer $id: doWork');
      await _doWork(1000);
      _queue.add(counter++);
      print('producer $id: queue $_queue');
      await _cvEmpty.signal();
    });
  }
}
```

**Output:**

```txt
producer one: doWork
producer one: queue {0}
producer two: doWork
producer two: queue {0, 1}
consumer one: queue {0, 1}
consumer one: doWork
consumer two: queue {1}
consumer two: doWork
consumer three: wait, queue {}
producer one: doWork
consumer one: work done, result 0
producer one: queue {2}
producer two: doWork
consumer two: work done, result 1
producer two: queue {2, 3}
consumer one: queue {2, 3}
consumer one: doWork
consumer three: queue {3}
consumer three: doWork
producer one: doWork
consumer one: work done, result 2
producer one: queue {4}
consumer two: queue {4}
consumer two: doWork
producer two: doWork
consumer three: work done, result 3
consumer two: work done, result 4
producer two: queue {5}
consumer one: queue {5}
consumer one: doWork
producer one: doWork
consumer one: work done, result 5
producer one: queue {6}
consumer three: queue {6}
consumer three: doWork
consumer two: wait, queue {}
producer two: doWork
producer two: queue {7}
consumer one: queue {7}
consumer one: doWork
producer one: doWork
consumer three: work done, result 6
producer one: queue {8}
consumer two: queue {8}
consumer two: doWork
producer two: doWork
consumer two: work done, result 8
consumer one: work done, result 7
```
