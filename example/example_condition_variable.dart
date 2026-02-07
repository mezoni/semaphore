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
