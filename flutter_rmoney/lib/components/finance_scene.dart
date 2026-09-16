import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/finance_summary.dart';
import '../utils/money_formatter.dart';

class FinanceScene extends StatefulWidget {
  const FinanceScene({super.key, required this.summary});
  final FinanceSummary summary;

  @override
  State<FinanceScene> createState() => _FinanceSceneState();
}

class _FinanceSceneState extends State<FinanceScene>
    with WidgetsBindingObserver {
  WebViewController? _controller;
  Timer? _timeout;
  bool _ready = false;
  bool _failed = false;
  bool _paused = false;
  bool _active = true;
  int _selected = -1;
  static const _names = ['Зардал', 'Хадгаламж', 'Нөөц', 'Боломжит үлдэгдэл'];
  static const _colors = [
    Color(0xFFF17F71),
    Color(0xFF3987B8),
    Color(0xFFB8A2DA),
    Color(0xFF28AD83)
  ];

  List<int> get _values => [
        widget.summary.expense,
        widget.summary.savings,
        widget.summary.reservedTenPercent,
        widget.summary.remainingMoney
      ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (WebViewPlatform.instance == null) {
      _failed = true;
      return;
    }
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..enableZoom(false)
      ..addJavaScriptChannel('Scene', onMessageReceived: (message) {
        if (!mounted) return;
        if (message.message == 'ready') {
          _timeout?.cancel();
          setState(() => _ready = true);
          _sync();
        } else if (message.message == 'error') {
          setState(() => _failed = true);
        } else if (message.message.startsWith('selected:')) {
          final index = int.tryParse(message.message.substring(9)) ?? -1;
          setState(() => _selected = index >= 0 && index < 4 ? index : -1);
        }
      })
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) =>
            request.url.startsWith('file:') || request.url == 'about:blank'
                ? NavigationDecision.navigate
                : NavigationDecision.prevent,
        onWebResourceError: (error) {
          if (mounted && error.isForMainFrame == true) {
            setState(() => _failed = true);
          }
        },
      ))
      ..loadFlutterAsset('assets/scene/index.html');
    _timeout = Timer(const Duration(seconds: 20), () {
      if (mounted && !_ready) setState(() => _failed = true);
    });
  }

  Future<void> _run(String script) async {
    if (!_ready || _failed) return;
    try {
      await _controller?.runJavaScript(script);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _sync() {
    _run('window.setFinance(${jsonEncode({
          'values': _values,
          'reducedMotion': _paused || MediaQuery.disableAnimationsOf(context),
          'running': _active
        })});');
  }

  @override
  void didUpdateWidget(covariant FinanceScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.summary != widget.summary) _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _active = TickerMode.valuesOf(context).enabled;
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed &&
        TickerMode.valuesOf(context).enabled;
    _run('window.setSceneActive($_active);');
  }

  @override
  void dispose() {
    _timeout?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _run('window.setSceneActive(false);');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        SizedBox(
          height: 230,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (!_failed && _controller != null)
                Semantics(
                  label: 'Санхүүгийн хуваарилалт',
                  child: WebViewWidget(
                      controller: _controller!,
                      gestureRecognizers: {
                        Factory<HorizontalDragGestureRecognizer>(
                            () => HorizontalDragGestureRecognizer()),
                      }),
                ),
              if (!_ready && !_failed)
                const Center(
                    child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2))),
              if (_failed)
                Center(
                    child: Icon(Icons.donut_large,
                        size: 150, color: scheme.secondary)),
              if (_ready && !_failed)
                Positioned(
                    right: 0,
                    bottom: 0,
                    child: Row(children: [
                      IconButton(
                        tooltip: 'Эргэлтийг эхлэлд буцаах',
                        onPressed: () {
                          setState(() => _selected = -1);
                          _run('window.resetScene();');
                        },
                        icon: const Icon(Icons.restart_alt, size: 20),
                      ),
                      IconButton(
                        tooltip: _paused
                            ? 'Хөдөлгөөн үргэлжлүүлэх'
                            : 'Хөдөлгөөн зогсоох',
                        onPressed: () {
                          setState(() => _paused = !_paused);
                          _run('window.setScenePaused($_paused);');
                        },
                        icon: Icon(_paused ? Icons.play_arrow : Icons.pause,
                            size: 20),
                      ),
                    ])),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
            builder: (context, constraints) => Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: List.generate(
                      4,
                      (index) => SizedBox(
                            width: (constraints.maxWidth - 12) / 2,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                setState(() => _selected =
                                    _selected == index ? -1 : index);
                                _run('window.selectSegment($_selected);');
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 4),
                                child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(top: 5),
                                          child: Icon(
                                            _selected == index
                                                ? Icons.check_circle
                                                : Icons.circle,
                                            size: 10,
                                            color: _colors[index],
                                          )),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text(_names[index],
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: scheme
                                                        .onSurfaceVariant)),
                                            const SizedBox(height: 3),
                                            FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                    formatMnt(_values[index]),
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w700))),
                                          ])),
                                    ]),
                              ),
                            ),
                          )),
                )),
      ],
    );
  }
}
