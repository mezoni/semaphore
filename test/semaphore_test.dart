import 'dart:async';

import 'package:semaphore/semaphore.dart';
import 'package:test/test.dart';

void main() {
  test('Global semaphore', () async {
    final res1 = <Object?>[];
    Future<void> action(List<Object?> res, int milliseconds) {
      expect(res.length, 0, reason: 'Not exclusive start');
      res.length++;
      final completer = Completer<void>();
      Timer(Duration(milliseconds: milliseconds), () {
        expect(res.length, 1, reason: 'Not exclusive end');
        res.length--;
        completer.complete();
      });

      return completer.future;
    }

    final s1 = GlobalSemaphore('semaphore_test');
    final s2 = GlobalSemaphore('semaphore_test');
    expect(s1, s2, reason: 'Global semaphores are not equal');
    //
    final list = <Future<void>>[];
    for (var i = 0; i < 3; i++) {
      Future<void> f(Semaphore s, List<Object?> l) async {
        try {
          await s.acquire();
          await action(l, 200);
        } finally {
          s.release();
        }
      }

      list.add(Future(() => f(s1, res1)));
      list.add(Future(() => f(s2, res1)));
    }

    // Run concurrently
    await Future.wait(list);
  });

  test('Local semaphore synchronization', () async {
    final res1 = <Object?>[];
    final res2 = <Object?>[];
    Future<void> action(List<Object?> res, int milliseconds) {
      expect(res.length, 0, reason: 'Not exclusive start');
      res.length++;
      final completer = Completer<void>();
      Timer(Duration(milliseconds: milliseconds), () {
        expect(res.length, 1, reason: 'Not exclusive end');
        res.length--;
        completer.complete();
      });

      return completer.future;
    }

    final s1 = LocalSemaphore(1);
    final s2 = LocalSemaphore(1);
    final list = <Future<void>>[];
    for (var i = 0; i < 3; i++) {
      Future<void> f(Semaphore s, List<Object?> l) async {
        try {
          await s.acquire();
          await action(l, 100);
        } finally {
          s.release();
        }
      }

      list.add(Future(() => f(s1, res1)));
      list.add(Future(() => f(s2, res2)));
    }

    // Run concurrently
    await Future.wait(list);
  });

  test('Local semaphore max count', () async {
    final list1 = <Future<void>?>[];
    const maxCount = 3;
    Future<void> action(List<Object?> list, int milliseconds) {
      expect(list.length <= maxCount, true, reason: 'Not exclusive start');
      list.length++;
      final completer = Completer<void>();
      Timer(Duration(milliseconds: milliseconds), () {
        expect(list.length <= maxCount, true, reason: 'Not exclusive end');
        list.length--;
        completer.complete();
      });

      return completer.future;
    }

    final s1 = LocalSemaphore(3);
    final list = <Future<void>>[];
    for (var i = 0; i < maxCount * 2; i++) {
      Future<void> f(Semaphore s, List<Object?> l) async {
        try {
          await s.acquire();
          await action(l, 100);
        } finally {
          s.release();
        }
      }

      list.add(Future(() => f(s1, list1)));
    }

    // Run concurrently
    await Future.wait(list);
  });
}
