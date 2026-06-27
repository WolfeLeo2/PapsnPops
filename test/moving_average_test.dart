import 'package:flutter_test/flutter_test.dart';
import 'package:paps_n_pops/features/stock/stock_provider.dart';

void main() {
  test('blends new price weighted by quantity', () {
    // 20 on hand @100 + 60 received @130 = (2000 + 7800) / 80 = 122.5
    expect(
      movingAverageBaseCost(
        onHandBase: 20,
        oldBaseCost: 100,
        receivedBase: 60,
        newBaseCost: 130,
      ),
      122.5,
    );
  });

  test('no prior stock -> uses new price', () {
    expect(
      movingAverageBaseCost(
        onHandBase: 0,
        oldBaseCost: 100,
        receivedBase: 60,
        newBaseCost: 130,
      ),
      130,
    );
  });

  test('unknown prior cost (0) -> uses new price, not dragged toward zero', () {
    expect(
      movingAverageBaseCost(
        onHandBase: 20,
        oldBaseCost: 0,
        receivedBase: 60,
        newBaseCost: 130,
      ),
      130,
    );
  });
}
