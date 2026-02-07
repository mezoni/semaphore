# semaphore

Version: 1.0.1

Lightweight implementation of a semaphore, a condition variable, and a lock that can be used to control (synchronize) access to a shared resources within an isolate.

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
  _sw.start();
  await Future.wait([
    _producer('1'),
    _producer('2'),
    _consumer('1'),
    _consumer('2'),
    _consumer('3'),
  ]);
}

var _bufferSize = 2;
var _itemId = 0;
final _items = Queue<int>();
final _lock = Lock();
final _notEmpty = ConditionVariable(_lock);
final _notFull = ConditionVariable(_lock);
final _sw = Stopwatch();

Future<void> _consumer(String id) async {
  while (true) {
    late int item;
    await lock(_lock, () async {
      while (_items.isEmpty) {
        _print('Consumer ($id) is waiting for the item');
        await _notEmpty.wait();
      }

      item = _items.removeFirst();
      _print('Consumer ($id) receives an item ($item)');
      await _notFull.signal();
    });

    _print('Consumer ($id) start consuming an item ($item)');
    await _doWork(3000);
    _print('Consumer ($id) finished consuming an item ($item)');
  }
}

Future<void> _doWork(int max) async {
  final milliseconds = Random().nextInt(max);
  await Future<void>.delayed(Duration(milliseconds: milliseconds));
}

void _print(String message) {
  final elapsed = _sw.elapsedMilliseconds / 1000;
  print('$message, items ($_items) [$elapsed]');
}

Future<void> _producer(String id) async {
  while (true) {
    _print('Producer ($id) begin producing the item');
    await _doWork(1000);
    _print('Producer ($id) finished producing the item');
    await lock(_lock, () async {
      while (_items.length == _bufferSize) {
        _print('Producer ($id) is waiting for free slot');
        await _notFull.wait();
      }

      final item = _itemId++;
      _items.add(item);
      _print('Producer ($id) sent the item ($item)');
      await _notEmpty.signal();
    });
  }
}

```

**Output:**

```txt
Producer (1) begin producing the item, items ({}) [0.001]
Producer (2) begin producing the item, items ({}) [0.022]
Consumer (1) is waiting for the item, items ({}) [0.038]
Consumer (2) is waiting for the item, items ({}) [0.039]
Consumer (3) is waiting for the item, items ({}) [0.039]
Producer (2) finished producing the item, items ({}) [0.406]
Producer (2) sent the item (0), items ({0}) [0.408]
Producer (2) begin producing the item, items ({0}) [0.41]
Consumer (1) receives an item (0), items ({}) [0.41]
Consumer (1) start consuming an item (0), items ({}) [0.411]
Producer (2) finished producing the item, items ({}) [0.42]
Producer (2) sent the item (1), items ({1}) [0.42]
Producer (2) begin producing the item, items ({1}) [0.42]
Consumer (2) receives an item (1), items ({}) [0.42]
Consumer (2) start consuming an item (1), items ({}) [0.421]
Producer (1) finished producing the item, items ({}) [0.443]
Producer (1) sent the item (2), items ({2}) [0.444]
Producer (1) begin producing the item, items ({2}) [0.444]
Consumer (3) receives an item (2), items ({}) [0.444]
Consumer (3) start consuming an item (2), items ({}) [0.444]
Producer (1) finished producing the item, items ({}) [0.566]
Producer (1) sent the item (3), items ({3}) [0.566]
Producer (1) begin producing the item, items ({3}) [0.566]
Producer (2) finished producing the item, items ({3}) [0.596]
Producer (2) sent the item (4), items ({3, 4}) [0.596]
Producer (2) begin producing the item, items ({3, 4}) [0.596]
Consumer (3) finished consuming an item (2), items ({3, 4}) [0.72]
Consumer (3) receives an item (3), items ({4}) [0.72]
Consumer (3) start consuming an item (3), items ({4}) [0.72]
Producer (2) finished producing the item, items ({4}) [0.733]
Producer (2) sent the item (5), items ({4, 5}) [0.734]
Producer (2) begin producing the item, items ({4, 5}) [0.734]
Producer (2) finished producing the item, items ({4, 5}) [1.346]
Producer (2) is waiting for free slot, items ({4, 5}) [1.347]
Producer (1) finished producing the item, items ({4, 5}) [1.55]
Producer (1) is waiting for free slot, items ({4, 5}) [1.551]
Consumer (2) finished consuming an item (1), items ({4, 5}) [2.561]
Consumer (2) receives an item (4), items ({5}) [2.562]
Consumer (2) start consuming an item (4), items ({5}) [2.562]
Producer (2) sent the item (6), items ({5, 6}) [2.562]
Producer (2) begin producing the item, items ({5, 6}) [2.562]
Producer (2) finished producing the item, items ({5, 6}) [3.3]
Producer (2) is waiting for free slot, items ({5, 6}) [3.3]
Consumer (1) finished consuming an item (0), items ({5, 6}) [3.337]
Consumer (1) receives an item (5), items ({6}) [3.337]
Consumer (1) start consuming an item (5), items ({6}) [3.337]
Producer (1) sent the item (7), items ({6, 7}) [3.338]
Producer (1) begin producing the item, items ({6, 7}) [3.338]
Consumer (3) finished consuming an item (3), items ({6, 7}) [3.575]
Consumer (3) receives an item (6), items ({7}) [3.575]
Consumer (3) start consuming an item (6), items ({7}) [3.575]
Producer (2) sent the item (8), items ({7, 8}) [3.576]
Producer (2) begin producing the item, items ({7, 8}) [3.576]
```
