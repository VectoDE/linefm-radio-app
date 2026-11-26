part of 'player_view.dart';

/// Waagerechter Abstand von [gap] links und rechts, aber nur, wenn das Kind
/// sichtbar ist (Breite > 0). Ein leerer Slot belegt so keinen Platz.
class SlotGap extends SingleChildRenderObjectWidget {
  const SlotGap({super.key, this.gap = 5, required Widget super.child});

  final double gap;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderSlotGap(gap);

  @override
  void updateRenderObject(BuildContext context, RenderSlotGap renderObject) {
    renderObject.gap = gap;
  }
}

class RenderSlotGap extends RenderShiftedBox {
  RenderSlotGap(this._gap) : super(null);

  double _gap;

  double get gap => _gap;

  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  BoxConstraints _inner(BoxConstraints c) =>
      c.loosen().deflate(EdgeInsets.symmetric(horizontal: _gap));

  Size _outer(BoxConstraints c, Size child) => child.width <= 0
      ? c.constrain(Size.zero)
      : c.constrain(Size(child.width + 2 * _gap, child.height));

  double _pad(double width) => width <= 0 ? 0 : width + 2 * _gap;

  @override
  double computeMinIntrinsicWidth(double height) =>
      _pad(child?.getMinIntrinsicWidth(height) ?? 0);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _pad(child?.getMaxIntrinsicWidth(height) ?? 0);

  @override
  double computeMinIntrinsicHeight(double width) =>
      child?.getMinIntrinsicHeight(math.max(0, width - 2 * _gap)) ?? 0;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      child?.getMaxIntrinsicHeight(math.max(0, width - 2 * _gap)) ?? 0;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.constrain(Size.zero);
    return _outer(constraints, child.getDryLayout(_inner(constraints)));
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.constrain(Size.zero);
      return;
    }
    child.layout(_inner(constraints), parentUsesSize: true);
    size = _outer(constraints, child.size);
    (child.parentData! as BoxParentData).offset = Offset(
      child.size.width <= 0 ? 0 : _gap,
      0,
    );
  }
}
