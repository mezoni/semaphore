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
