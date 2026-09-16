import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rmoney_flutter/app/app_lock.dart';

void main() {
  testWidgets(
      'content stays hidden until authentication succeeds; cancel retries',
      (tester) async {
    addTearDown(() => tester.pumpWidget(const SizedBox()));
    var request = Completer<bool>();
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) =>
          AppLock(authenticate: () => request.future, child: child!),
      home: const Scaffold(body: Text('Private balance')),
    ));
    expect(find.text('Private balance'), findsNothing);
    request.complete(false);
    await tester.pumpAndSettle();
    expect(find.text('Private balance'), findsNothing);
    request = Completer<bool>();
    await tester.tap(find.text('Түгжээ тайлах'));
    request.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('Private balance'), findsOneWidget);
  });

  testWidgets('returning after five minutes locks even a pushed route',
      (tester) async {
    addTearDown(() => tester.pumpWidget(const SizedBox()));
    var now = DateTime(2026, 9, 9, 12);
    var request = Completer<bool>();
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigator,
      builder: (context, child) => AppLock(
          authenticate: () => request.future, now: () => now, child: child!),
      home: const Scaffold(body: Text('Home')),
    ));
    request.complete(true);
    await tester.pumpAndSettle();
    navigator.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Private report'))));
    await tester.pumpAndSettle();
    expect(find.text('Private report'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.text('Private report'), findsNothing);
    request = Completer<bool>();
    now = now.add(const Duration(minutes: 5));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('Private report'), findsNothing);
    request.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('Private report'), findsOneWidget);
  });

  testWidgets('authentication error never reveals records', (tester) async {
    addTearDown(() => tester.pumpWidget(const SizedBox()));
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => AppLock(
          authenticate: () async => throw StateError('unavailable'),
          child: child!),
      home: const Scaffold(body: Text('Private balance')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Private balance'), findsNothing);
    expect(find.textContaining('Баталгаажуулж чадсангүй'), findsOneWidget);
  });

  testWidgets('quick returns keep authentication and reset the idle period',
      (tester) async {
    addTearDown(() => tester.pumpWidget(const SizedBox()));
    var now = DateTime(2026, 9, 9, 12);
    var requests = 0;
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => AppLock(
          now: () => now,
          authenticate: () async {
            requests++;
            return true;
          },
          child: child!),
      home: const Scaffold(body: Text('Private balance')),
    ));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(find.text('Private balance'), findsNothing);
      now = now.add(const Duration(minutes: 4, seconds: 59));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Private balance'), findsOneWidget);
    }
    expect(requests, 1);
  });

  testWidgets('foreground interaction resets idle timer; idle content locks',
      (tester) async {
    addTearDown(() => tester.pumpWidget(const SizedBox()));
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) =>
          AppLock(authenticate: () async => true, child: child!),
      home: const Scaffold(body: Center(child: Text('Private balance'))),
    ));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(minutes: 4));
    await tester.tap(find.text('Private balance'));
    await tester.pump(const Duration(minutes: 4));
    expect(find.text('Private balance'), findsOneWidget);
    await tester.pump(const Duration(minutes: 1));
    expect(find.text('Private balance'), findsNothing);
    expect(find.text('Түгжээ тайлах'), findsOneWidget);
  });
}
