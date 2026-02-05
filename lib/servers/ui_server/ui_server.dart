import 'package:flutter/widgets.dart';
import 'package:jerelo/jerelo.dart';
import 'package:jerelo_sample/servers/ui_server/my_app_widget.dart';
import 'package:jerelo_sample/servers/ui_server/ui_input.dart';
import 'package:jerelo_sample/servers/ui_server/ui_output.dart';

final class Bridge<I, O> {
  final Cont<E, ()> Function<E>(I) enqueue;
  final Cont<E, O> Function<E>() dequeue;

  const Bridge._({
    required this.enqueue,
    required this.dequeue,
    //
  });
}

Cont<E, (Bridge<I, O>, Bridge<O, I>)> bridges<E, I, O>() {
  return Cont.fromRun((runtime, observer) {
    final RendezvousQueue<I> queue1 = RendezvousQueue();
    final RendezvousQueue<O> queue2 = RendezvousQueue();

    final bridge1 = Bridge<I, O>._(
      enqueue: <V>(val) {
        return queue1.enqueue(val);
      },
      dequeue: <V>() {
        return queue2.dequeue();
      },
    );
    final bridge2 = Bridge<O, I>._(
      enqueue: <V>(val) {
        return queue2.enqueue(val);
      },
      dequeue: <V>() {
        return queue1.dequeue();
      },
    );

    observer.onValue((bridge1, bridge2));
  });
}

Cont<E, Bridge<UiInput, UiOutput>> getUiServer<E>() {
  return bridges<E, UiOutput, UiInput>().thenDo((bridges) {
    final (bridge1, bridge2) = bridges;
    return Cont.fromRun((runtime, observer) {
      runApp(MyAppWidget(bridge1));
      observer.onValue(bridge2);
    });
  });
}

final class RendezvousQueue<T> {
  final List<ContObserver<T>> waiters = [];
  final List<(ContObserver<()>, T)> providers = [];

  Cont<E, ()> enqueue<E>(T value) {
    return Cont.fromRun((runtime, observer) {
      if (waiters.isEmpty) {
        providers.add((observer, value));
        return;
      }

      final copyOfWaiters = List<ContObserver<T>>.from(waiters); // VERY IMPORTANT!
      waiters.clear(); // THIS MUST BE DONE BEFORE oObserver.onValue! Otherwise we may get into reentrant loop
      for (final oObserver in copyOfWaiters) {
        oObserver.onValue(value);
      }
      observer.onValue(());
    });
  }

  Cont<E, T> dequeue<E>() => Cont.fromRun((runtime, observer) {
    if (providers.isEmpty) {
      waiters.add(observer);
      return;
    }

    final (iObserver, input) = providers.removeAt(0);
    observer.onValue(input);
    iObserver.onValue(());
  });
}
