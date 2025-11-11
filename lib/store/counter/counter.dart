import 'package:mobx/mobx.dart';

// This is our generated file (we'll see this soon!)
part 'counter.g.dart';

// We expose this to be used throughout our project
class Counter = _Counter with _$Counter;

// Our store class
abstract class _Counter with Store {
  @observable
  int value = 1;

  @action
  void increment() {
    value++;
  }

  @action
  void decrement() {
    value--;
  }
}
