import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:notepad/main.dart';
import 'package:notepad/screens/editor_screen.dart';
import 'package:notepad/services/app_settings.dart';
import 'package:notepad/services/note_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<NoteStore> pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await NoteStore.open();
    final settings = await AppSettings.open();
    await tester.pumpWidget(NotepadApp(store: store, settings: settings));
    await tester.pumpAndSettle();
    return store;
  }

  Future<void> openEditor(WidgetTester tester) async {
    await tester.tap(find.text('New note'));
    await tester.pumpAndSettle();
    expect(find.byType(EditorScreen), findsOneWidget);
  }

  testWidgets('home screen renders and opens the editor', (tester) async {
    await pumpApp(tester);

    // SliverAppBar.large keeps a medium and a large title in the tree.
    expect(find.text('Notepad'), findsWidgets);
    expect(find.text('Your pad is blank'), findsOneWidget);

    await openEditor(tester);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('0 words · 0 chars'), findsOneWidget);
  });

  testWidgets('typing in the title autosaves and back returns home',
      (tester) async {
    final store = await pumpApp(tester);
    await openEditor(tester);

    await tester.enterText(find.byType(TextField).first, 'Groceries');
    await tester.pump();

    // Autosave debounce (600ms) then persist.
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsOneWidget);
    expect(store.notes.single.title, 'Groceries');

    // Back arrow must leave the editor exactly once (regression: an
    // infinite maybePop/PopScope loop used to freeze the app here).
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(EditorScreen), findsNothing);
    expect(find.text('Groceries'), findsOneWidget);
    expect(store.notes.single.title, 'Groceries');
  });

  testWidgets('system back saves pending edits and closes the editor',
      (tester) async {
    final store = await pumpApp(tester);
    await openEditor(tester);

    await tester.enterText(find.byType(TextField).first, 'Draft note');
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(EditorScreen), findsNothing);
    expect(store.notes.single.title, 'Draft note');
  });

  testWidgets('rich text edits update word count and persist', (tester) async {
    final store = await pumpApp(tester);
    await openEditor(tester);

    final quill = tester.widget<QuillEditor>(find.byType(QuillEditor));
    quill.controller.replaceText(0, 0, 'Hello beautiful world', null);
    await tester.pump();

    expect(find.text('3 words · 21 chars'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(store.notes.single.preview, 'Hello beautiful world');
  });

  testWidgets('empty notes are not saved when leaving the editor',
      (tester) async {
    final store = await pumpApp(tester);
    await openEditor(tester);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(EditorScreen), findsNothing);
    expect(store.notes, isEmpty);
    expect(find.text('Your pad is blank'), findsOneWidget);
  });
}
