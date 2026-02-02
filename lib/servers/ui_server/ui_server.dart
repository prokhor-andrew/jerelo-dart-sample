import 'package:flutter/widgets.dart';
import 'package:jerelo/jerelo.dart';
import 'package:jerelo_sample/servers/ui_server/my_app_widget.dart';
import 'package:jerelo_sample/servers/ui_server/ui_input.dart';
import 'package:jerelo_sample/servers/ui_server/ui_output.dart';

final class Bridge<I, O> {
  final Cont<()> Function(I) enqueue;
  final Cont<O> dequeue;

  const Bridge._({
    required this.enqueue,
    required this.dequeue,
    //
  });
}

Cont<(Bridge<I, O>, Bridge<O, I>)> bridges<I, O>() {
  return Cont.fromRun((observer) {
    final RendezvousQueue<I> queue1 = RendezvousQueue();
    final RendezvousQueue<O> queue2 = RendezvousQueue();

    final bridge1 = Bridge._(enqueue: queue1.enqueue, dequeue: queue2.dequeue);
    final bridge2 = Bridge._(enqueue: queue2.enqueue, dequeue: queue1.dequeue);

    observer.onValue((bridge1, bridge2));
  });
}

Cont<Bridge<UiInput, UiOutput>> getUiServer() {
  return bridges<UiOutput, UiInput>().then((bridges) {
    final (bridge1, bridge2) = bridges;
    return Cont.fromRun((observer) {
      runApp(MyAppWidget(bridge1));
      observer.onValue(bridge2);
    });
  });
}

final class RendezvousQueue<T> {
  final List<ContObserver<T>> waiters = [];
  final List<(ContObserver<()>, T)> providers = [];

  Cont<()> enqueue(T value) {
    return Cont.fromRun((observer) {
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

  Cont<T> get dequeue => Cont.fromRun((observer) {
    if (providers.isEmpty) {
      waiters.add(observer);
      return;
    }

    final (iObserver, input) = providers.removeAt(0);
    observer.onValue(input);
    iObserver.onValue(());
  });
}
