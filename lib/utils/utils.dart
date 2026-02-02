import 'package:jerelo/jerelo.dart';

Cont<T> fromFutureComp<T>(Future<T> Function() f) {
  return Cont.fromRun((observer) {
    f().then(observer.onValue).catchError((error, st) {
      observer.onTerminate([ContError(error, st)]);
    });
  });
}

extension ContScheduling<T> on Cont<T> {
  Cont<T> subscribeOnMicrotask() {
    return hoist((run, observer) {
      Future.microtask(() {
        run(observer);
      });
    });
  }

  Cont<T> subscribeOnDelayed([Duration duration = Duration.zero]) {
    return hoist((run, observer) {
      Future.delayed(duration, () {
        run(observer);
      });
    });
  }

  Cont<T> logOnValue(String tag) {
    return hoist((run, observer) {
      run(
        observer.copyUpdateOnValue((a) {
          print('$tag $a');
          observer.onValue(a);
        }),
      );
    });
  }
}