import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// =============================================================================
// CENTRALIZED FINTECH MOTION CONSTANTS
// =============================================================================

/// Standardized motion parameters for CoSpend.
/// Strictly tuned for a responsive, subtle fintech feel (200–320ms general range).
abstract final class CoSpendMotion {
  // Durations
  static const Duration micro = Duration(milliseconds: 90);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration standard = Duration(milliseconds: 260);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 450);

  // Curves
  static const Curve standardCurve = Curves.easeInOutCubic;
  static const Curve entranceCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;
  static const Curve snappyCurve = Curves.easeOutQuad;
  static const Curve subtleSpring = Curves.easeOutBack;
}

// =============================================================================
// 1. SCREEN TRANSITIONS (GoRouter CustomTransitionPage)
// =============================================================================

/// Shared axis screen transition with subtle fade + slight vertical slide.
CustomTransitionPage<T> coSpendPageTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: CoSpendMotion.standard,
    reverseTransitionDuration: CoSpendMotion.fast,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: CoSpendMotion.entranceCurve,
        reverseCurve: CoSpendMotion.exitCurve,
      );

      final slide = Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(curvedAnimation);

      final fade = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(curvedAnimation);

      return FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: slide,
          child: child,
        ),
      );
    },
  );
}

// =============================================================================
// 2. CARD ENTRANCE & FADE-SLIDE ANIMATION
// =============================================================================

/// Subtle one-time entrance animation: fades and slides up 14px on mount.
/// Does NOT re-trigger when ancestor widgets or Riverpod providers rebuild.
class CoSpendFadeSlide extends StatefulWidget {
  const CoSpendFadeSlide({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = CoSpendMotion.standard,
    this.offset = const Offset(0, 14),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  @override
  State<CoSpendFadeSlide> createState() => _CoSpendFadeSlideState();
}

class _CoSpendFadeSlideState extends State<CoSpendFadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final curved = CurvedAnimation(
      parent: _controller,
      curve: CoSpendMotion.entranceCurve,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _slideAnimation = Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(curved);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: _slideAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Helper that wraps children in subtle staggered sequential entrance delays.
class CoSpendStaggeredList extends StatelessWidget {
  const CoSpendStaggeredList({
    super.key,
    required this.children,
    this.staggerInterval = const Duration(milliseconds: 35),
    this.maxDelay = const Duration(milliseconds: 180),
  });

  final List<Widget> children;
  final Duration staggerInterval;
  final Duration maxDelay;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(children.length, (index) {
        final rawDelayMs = index * staggerInterval.inMilliseconds;
        final delayMs = math.min(rawDelayMs, maxDelay.inMilliseconds);

        return CoSpendFadeSlide(
          delay: Duration(milliseconds: delayMs),
          child: children[index],
        );
      }),
    );
  }
}

// =============================================================================
// 3. NUMBER & FINANCIAL VALUE ANIMATIONS
// =============================================================================

/// Smoothly transitions numerical values (e.g. monetary figures or percentages).
/// Only animates when the target value actually changes.
class CoSpendAnimatedNumber extends ImplicitlyAnimatedWidget {
  const CoSpendAnimatedNumber({
    super.key,
    required this.value,
    required this.builder,
    super.duration = CoSpendMotion.standard,
    super.curve = CoSpendMotion.entranceCurve,
  });

  final num value;
  final Widget Function(BuildContext context, num animatedValue) builder;

  @override
  ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget> createState() =>
      _CoSpendAnimatedNumberState();
}

class _CoSpendAnimatedNumberState
    extends AnimatedWidgetBaseState<CoSpendAnimatedNumber> {
  Tween<num>? _numTween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _numTween = visitor(
      _numTween,
      widget.value,
      (dynamic value) => Tween<num>(begin: value as num),
    ) as Tween<num>?;
  }

  @override
  Widget build(BuildContext context) {
    final animatedValue = _numTween?.evaluate(animation) ?? widget.value;
    return widget.builder(context, animatedValue);
  }
}

// =============================================================================
// 4. ANIMATED SWITCHER (States: Loading, Error, Empty, Content)
// =============================================================================

/// Standardized AnimatedSwitcher for seamless state transitions without flashing.
class CoSpendFadeSwitcher extends StatelessWidget {
  const CoSpendFadeSwitcher({
    super.key,
    required this.child,
    this.duration = CoSpendMotion.fast,
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: CoSpendMotion.entranceCurve,
      switchOutCurve: CoSpendMotion.exitCurve,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: child,
    );
  }
}

// =============================================================================
// 5. SUCCESS CONFIRMATION ANIMATION
// =============================================================================

/// Subtle self-drawing checkmark scale animation for success dialogs and toasts.
class CoSpendSuccessCheckmark extends StatefulWidget {
  const CoSpendSuccessCheckmark({
    super.key,
    this.size = 48.0,
    this.color = const Color(0xFF00BC57),
  });

  final double size;
  final Color color;

  @override
  State<CoSpendSuccessCheckmark> createState() => _CoSpendSuccessCheckmarkState();
}

class _CoSpendSuccessCheckmarkState extends State<CoSpendSuccessCheckmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: CoSpendMotion.standard,
    )..forward();

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: CoSpendMotion.subtleSpring,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.check_rounded,
          color: widget.color,
          size: widget.size * 0.58,
        ),
      ),
    );
  }
}

// =============================================================================
// 6. ERROR FEEDBACK SHAKE ANIMATION
// =============================================================================

/// Subtle horizontal shake effect for input validation errors or rejected actions.
class CoSpendShake extends StatefulWidget {
  const CoSpendShake({
    super.key,
    required this.child,
    this.controller,
  });

  final Widget child;
  final CoSpendShakeController? controller;

  @override
  State<CoSpendShake> createState() => _CoSpendShakeState();
}

class CoSpendShakeController {
  _CoSpendShakeState? _state;

  void shake() {
    _state?.shake();
  }

  void _attach(_CoSpendShakeState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }
}

class _CoSpendShakeState extends State<CoSpendShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _controller = AnimationController(
      vsync: this,
      duration: CoSpendMotion.standard,
    );
  }

  @override
  void didUpdateWidget(covariant CoSpendShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _controller.dispose();
    super.dispose();
  }

  void shake() {
    if (mounted) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // 3 gentle horizontal oscillations with exponential decay
        final progress = _controller.value;
        final sine = math.sin(progress * math.pi * 6);
        final decay = 1.0 - progress;
        final offset = sine * decay * 6.0;

        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// =============================================================================
// 7. LIST ITEM INSERTION / REMOVAL TRANSITION
// =============================================================================

/// Standard AnimatedList item transition (fade + slight vertical slide).
Widget coSpendListItemTransition(
  BuildContext context,
  Widget child,
  Animation<double> animation,
) {
  final curved = CurvedAnimation(
    parent: animation,
    curve: CoSpendMotion.entranceCurve,
    reverseCurve: CoSpendMotion.exitCurve,
  );

  return FadeTransition(
    opacity: curved,
    child: SizeTransition(
      sizeFactor: curved,
      child: child,
    ),
  );
}
