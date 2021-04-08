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
    late int number;
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
