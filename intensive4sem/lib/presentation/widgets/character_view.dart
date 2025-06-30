import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class CharacterView extends StatefulWidget {
  final String baseSprite;
  final List<String> blinkAnimationFrames;
  final double width;
  final double height;

  const CharacterView({
    super.key,
    required this.baseSprite,
    required this.blinkAnimationFrames,
    this.width = 100,
    this.height = 100,
  });

  @override
  State<CharacterView> createState() => _CharacterViewState();
}

class _CharacterViewState extends State<CharacterView> {
  // Хранит путь к текущему отображаемому спрайту
  late String _currentSprite;
  Timer? _blinkTimer;
  bool _isBlinking = false;

  @override
  void initState() {
    super.initState();
    _currentSprite = widget.baseSprite;
    _scheduleBlink();
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    super.dispose();
  }

  // Вызывается, когда виджет перестраивается с новыми параметрами
  @override
  void didUpdateWidget(covariant CharacterView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Если поза сменилась и мы не в процессе моргания, обновляем спрайт
    if (widget.baseSprite != oldWidget.baseSprite && !_isBlinking) {
      setState(() {
        _currentSprite = widget.baseSprite;
      });
      // Перезапускаем таймер, чтобы избежать моргания сразу после смены позы
      _blinkTimer?.cancel();
      _scheduleBlink();
    }
  }

  // Планирует следующее моргание через случайный промежуток времени
  void _scheduleBlink() {
    _blinkTimer =
        Timer(Duration(milliseconds: 2000 + Random().nextInt(3000)), () {
      if (mounted) {
        _animateBlink();
      }
    });
  }

  // Запускает покадровую анимацию моргания
  Future<void> _animateBlink() async {
    if (_isBlinking) return; // Предотвращаем двойной запуск

    setState(() {
      _isBlinking = true;
    });

    // Анимация "вперед": от открытых глаз к закрытым
    for (final frame in widget.blinkAnimationFrames) {
      if (!mounted) return;
      setState(() {
        _currentSprite = frame;
      });
      await Future.delayed(const Duration(milliseconds: 60));
    }

    // Анимация "назад": от закрытых к открытым
    for (final frame in widget.blinkAnimationFrames.reversed) {
      if (!mounted) return;
      setState(() {
        _currentSprite = frame;
      });
      await Future.delayed(const Duration(milliseconds: 60));
    }

    // Возвращаемся к базовому спрайту
    if (mounted) {
      setState(() {
        _currentSprite = widget.baseSprite;
        _isBlinking = false;
      });
    }

    // Планируем следующее моргание
    _scheduleBlink();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Image.asset(
        _currentSprite,
        // Важный параметр! Предотвращает "моргание" самого Image виджета
        // при быстрой смене пути к картинке, делая анимацию плавной.
        gaplessPlayback: true,
      ),
    );
  }
}