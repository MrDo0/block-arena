import 'package:flutter/material.dart';

class AnimatedScore extends StatefulWidget {
  final int value;
  final TextStyle style;

  const AnimatedScore({super.key, required this.value, required this.style});

  @override
  State<AnimatedScore> createState() => _AnimatedScoreState();
}

class _AnimatedScoreState extends State<AnimatedScore>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _from = 0;
  int _to = 0;

  @override
  void initState() {
    super.initState();
    _to = widget.value;
    _from = widget.value;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant AnimatedScore old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _from = _currentValue;
      _to = widget.value;
      _ctrl.forward(from: 0);
    }
  }

  int get _currentValue {
    final t = Curves.easeOutCubic.transform(_ctrl.value);
    return (_from + (_to - _from) * t).round();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text('$_currentValue', style: widget.style);
  }
}
