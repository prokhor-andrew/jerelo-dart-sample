import 'package:jerelo/jerelo.dart';

Cont<E, T> fromFutureComp<E, T>(Future<T> Function(ContRuntime<E> runtime) f, T Function(Object error, StackTrace st) catchError) {
  return Cont.fromRun((runtime, observer) {
    f(runtime).then(observer.onValue).catchError((error, st) {
      try {
        observer.onValue(catchError(error, st));
      } catch (error, st) {
        observer.onTerminate([ContError(error, st)]);
      }
    });
  });
}

extension ContScheduling<E, T> on Cont<E, T> {
  Cont<E, T> subscribeOnMicrotask() {
    return hoist((run, runtime, observer) {
      Future.microtask(() {
        run(runtime, observer);
      });
    });
  }

  Cont<E, T> subscribeOnDelayed([Duration duration = Duration.zero]) {
    return hoist((run, runtime, observer) {
      Future.delayed(duration, () {
        run(runtime, observer);
      });
    });
  }

  Cont<E, T> logOnValue(String tag) {
    return hoist((run, runtime, observer) {
      run(
        runtime,
        observer.copyUpdateOnValue((a) {
          print('$tag $a');
          observer.onValue(a);
        }),
      );
    });
  }
}


List<T> mergeLists<T>(List<T> list1, List<T> list2) {
  return list1 + list2;
}