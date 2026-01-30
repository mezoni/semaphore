part of '../../lock.dart';

Future<void> lock(Lock lock, Future<void> Function() func) async {
  try {
    await lock.acquire();
    await func();
  } finally {
    lock.release();
  }
}

class Lock {
  final LocalSemaphore _semaphore = LocalSemaphore(1);

  Future<void> acquire() {
    return _semaphore.acquire();
  }

  void release() {
    _semaphore.release();
  }
}
