import 'package:flutter/material.dart';

/// Swipeable carousel with a dot indicator whose height adapts to the
/// current page: each page is measured after layout and the viewport height
/// animates (grow/shrink) when the user lands on a page with a different
/// content height, instead of jumping or clipping.
class InAppV2Carousel extends StatefulWidget {
  final List<Widget> children;
  final Color activeDotColor;

  const InAppV2Carousel({
    super.key,
    required this.children,
    required this.activeDotColor,
  });

  @override
  State<InAppV2Carousel> createState() => _InAppV2CarouselState();
}

class _InAppV2CarouselState extends State<InAppV2Carousel> {
  /// Viewport height while the current page has not reported its size yet
  /// (first frame only).
  static const double _fallbackHeight = 300;

  final _controller = PageController();
  late final List<double> _heights;
  int _currentPage = 0;

  double get _currentHeight =>
      _heights[_currentPage] > 0 ? _heights[_currentPage] : _fallbackHeight;

  @override
  void initState() {
    super.initState();
    _heights = List.filled(widget.children.length, 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Flexible caps the animated height at the space the dialog offers;
        // a page taller than that scrolls inside its own viewport.
        Flexible(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            tween: Tween<double>(end: _currentHeight),
            builder: (context, height, child) =>
                SizedBox(height: height, child: child),
            child: PageView(
              controller: _controller,
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: [
                for (var i = 0; i < widget.children.length; i++)
                  SingleChildScrollView(
                    child: _SizeReportingWidget(
                      onSizeChange: (size) {
                        if (_heights[i] != size.height) {
                          setState(() => _heights[i] = size.height);
                        }
                      },
                      child: widget.children[i],
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.children.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _currentPage ? 16 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _currentPage
                        ? widget.activeDotColor
                        : Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Reports the laid-out size of [child] after each frame in which it changed.
class _SizeReportingWidget extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size> onSizeChange;

  const _SizeReportingWidget({
    required this.child,
    required this.onSizeChange,
  });

  @override
  State<_SizeReportingWidget> createState() => _SizeReportingWidgetState();
}

class _SizeReportingWidgetState extends State<_SizeReportingWidget> {
  Size? _oldSize;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifySize());
    return widget.child;
  }

  void _notifySize() {
    if (!mounted) return;
    final size = context.size;
    if (size != null && size != _oldSize) {
      _oldSize = size;
      widget.onSizeChange(size);
    }
  }
}
