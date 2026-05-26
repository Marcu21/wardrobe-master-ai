import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/screens/ai_stylist/ai_stylist_view_model.dart';

void main() {
  // TextEditingController needs the Flutter binding.
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  group('AiStylistViewModel — initial state', () {
    late AiStylistViewModel vm;

    setUp(() => vm = AiStylistViewModel.forTest());
    tearDown(() => vm.dispose());

    test('starts with an empty message history', () {
      expect(vm.messages, isEmpty);
    });

    test('starts with isTyping = false', () {
      expect(vm.isTyping, isFalse);
    });

    test('text controller starts empty', () {
      expect(vm.controller.text, '');
    });
  });

  group('AiStylistViewModel — sendMessage', () {
    late AiStylistViewModel vm;

    setUp(() => vm = AiStylistViewModel.forTest());
    tearDown(() => vm.dispose());

    test('ignores blank or whitespace-only input', () async {
      await vm.sendMessage('   ');
      expect(vm.messages, isEmpty);
      expect(vm.isTyping, isFalse);
    });

    test('appends user message to history synchronously', () async {
      // Fire without awaiting so we observe pre-await state.
      final future = vm.sendMessage('What should I wear today?');

      // Synchronous assertions — run before the first HTTP await suspends.
      expect(vm.messages.length, 1);
      expect(vm.messages.first.role, 'user');
      expect(vm.messages.first.text, 'What should I wear today?');

      await future; // clean up — network fails, caught internally
    });

    test('sets isTyping = true synchronously after send', () async {
      final future = vm.sendMessage('Suggest a casual outfit');
      expect(vm.isTyping, isTrue);
      await future;
    });

    test('clears text controller synchronously after send', () async {
      vm.controller.text = 'Suggest a casual outfit';
      final future = vm.sendMessage('Suggest a casual outfit');
      expect(vm.controller.text, '');
      await future;
    });

    test('sets isTyping = false after async completion', () async {
      await vm.sendMessage('What to wear?');
      expect(vm.isTyping, isFalse);
    });

    test('appends an AI reply after network failure (graceful fallback)', () async {
      await vm.sendMessage('Outfit for rain?');
      // user message + AI fallback message
      expect(vm.messages.length, 2);
      expect(vm.messages.last.role, 'ai');
      expect(vm.messages.last.text, isNotEmpty);
    });

    test('accumulates multiple messages across sequential sends', () async {
      await vm.sendMessage('First question');
      await vm.sendMessage('Second question');
      // 2 user + 2 AI fallback
      expect(vm.messages.length, 4);
      expect(vm.messages[0].role, 'user');
      expect(vm.messages[2].role, 'user');
    });
  });
}
