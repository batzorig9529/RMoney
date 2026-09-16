import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class AppLock extends StatefulWidget {
  const AppLock({super.key, required this.child, this.authenticate, this.now});

  final Widget child;
  final Future<bool> Function()? authenticate;
  final DateTime Function()? now;

  @override
  State<AppLock> createState() => _AppLockState();
}

class _AppLockState extends State<AppLock> with WidgetsBindingObserver {
  final _auth = LocalAuthentication();
  static const _idleLimit = Duration(minutes: 5);
  Timer? _idleTimer;
  DateTime? _lastActivity;
  DateTime get _now => widget.now?.call() ?? DateTime.now();
  bool _unlocked = false;
  bool _busy = false;
  bool _hasOpened = false;
  String? _message;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_onKey);
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HardwareKeyboard.instance.removeHandler(_onKey);
    _idleTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      if (_lifecycle == AppLifecycleState.resumed &&
          state != AppLifecycleState.resumed &&
          _unlocked &&
          !_busy) {
        _lastActivity = _now;
      }
      _lifecycle = state;
      _idleTimer?.cancel();
      if (state == AppLifecycleState.resumed && _unlocked) {
        if (_lastActivity == null ||
            _now.difference(_lastActivity!) >= _idleLimit) {
          _unlocked = false;
        } else {
          _recordActivity();
        }
      }
    });
    if (state == AppLifecycleState.resumed && !_unlocked && !_busy) {
      _unlock();
    }
  }

  bool _onKey(KeyEvent event) {
    _recordActivity();
    return false;
  }

  void _recordActivity() {
    if (!_unlocked || _busy || _lifecycle != AppLifecycleState.resumed) return;
    _lastActivity = _now;
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleLimit, () {
      if (mounted) setState(() => _unlocked = false);
    });
  }

  Future<void> _unlock() async {
    if (!mounted || _busy || _lifecycle != AppLifecycleState.resumed) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    var success = false;
    String? message;
    try {
      success = await (widget.authenticate?.call() ??
          _auth.authenticate(
            localizedReason: 'RMoney нээхийн тулд утасны түгжээгээ тайлна уу.',
            biometricOnly: false,
            persistAcrossBackgrounding: true,
          ));
      if (!success) message = 'Баталгаажуулалт цуцлагдлаа. Дахин оролдоно уу.';
    } catch (_) {
      message =
          'Баталгаажуулж чадсангүй. Утасны тохиргоонд PIN эсвэл дэлгэцийн түгжээ идэвхтэй эсэхийг шалгаад дахин оролдоно уу.';
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _unlocked = success &&
          (_lifecycle == AppLifecycleState.resumed ||
              _lifecycle == AppLifecycleState.inactive);
      _hasOpened = _hasOpened || _unlocked;
      if (_unlocked) _lastActivity = _now;
      _message = message;
    });
    _recordActivity();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _unlocked && _lifecycle == AppLifecycleState.resumed;
    return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _recordActivity(),
        onPointerMove: (_) => _recordActivity(),
        onPointerSignal: (_) => _recordActivity(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_hasOpened)
              Offstage(
                  offstage: !visible,
                  child: TickerMode(enabled: visible, child: widget.child)),
            if (!visible)
              PopScope(
                canPop: false,
                child: Scaffold(
                  body: SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_outline, size: 48),
                              const SizedBox(height: 16),
                              Text('RMoney түгжээтэй',
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 16),
                              if (_message != null) ...[
                                Text(_message!, textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                              ],
                              FilledButton.icon(
                                onPressed: _busy ? null : _unlock,
                                icon: const Icon(Icons.lock_open),
                                label: Text(_busy
                                    ? 'Баталгаажуулж байна...'
                                    : 'Түгжээ тайлах'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ));
  }
}
