import 'dart:async';

import 'package:semaphore/semaphore.dart';
import 'package:test/test.dart';

void main() {
  test('Global semaphore', () async {
    final res1 = [];
    Future action(List res, int milliseconds) {
      expect(res.length, 0, reason: 'Not exlusive start');
      res.length++;
      final completer = Completer();
      Timer(Duration(milliseconds: milliseconds), () {
        expect(res.length, 1, reason: 'Not exlusive end');
        res.length--;
        completer.complete();
      });

      return completer.future;
    }

    final s1 = GlobalSemaphore('semaphore_test');
    final s2 = GlobalSemaphore('semaphore_test');
    expect(s1, s2, reason: 'Global semaphores are not equal');
    //
    final list = <Future>[];
    for (var i = 0; i < 3; i++) {
      Future f(Semaphore s, List l) async {
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

  test('Local semaphore synchronisation', () async {
    final res1 = [];
    final res2 = [];
    Future action(List res, int milliseconds) {
      expect(res.length, 0, reason: 'Not exlusive start');
      res.length++;
      final completer = Completer();
      Timer(Duration(milliseconds: milliseconds), () {
        expect(res.length, 1, reason: 'Not exlusive end');
        res.length--;
        completer.complete();
      });

      return completer.future;
    }

    final s1 = LocalSemaphore(1);
    final s2 = LocalSemaphore(1);
    final list = <Future>[];
    for (var i = 0; i < 3; i++) {
      Future f(Semaphore s, List l) async {
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
    final list1 = <Future?>[];
    final maxCount = 3;
    Future action(List list, int milliseconds) {
      expect(list.length <= maxCount, true, reason: 'Not exlusive start');
      list.length++;
      final completer = Completer();
      Timer(Duration(milliseconds: milliseconds), () {
        expect(list.length <= maxCount, true, reason: 'Not exlusive end');
        list.length--;
        completer.complete();
      });

      return completer.future;
    }

    final s1 = LocalSemaphore(3);
    final list = <Future>[];
    for (var i = 0; i < maxCount * 2; i++) {
      Future f(Semaphore s, List l) async {
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
