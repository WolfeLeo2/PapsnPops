import 'package:flutter_test/flutter_test.dart';
import 'package:paps_n_pops/domain/models/branch.dart';

void main() {
  group('Branch Model Tests', () {
    test('fromMap should parse correctly', () {
      final json = {
        'id': 'branch-uuid-123',
        'name': 'Main Branch Nairobi',
        'location': 'Westlands, Nairobi',
        'phone': '0712345678',
        'created_at': '2026-06-01T00:00:00.000Z',
      };

      final branch = Branch.fromMap(json);

      expect(branch.id, equals('branch-uuid-123'));
      expect(branch.name, equals('Main Branch Nairobi'));
      expect(branch.location, equals('Westlands, Nairobi'));
      expect(branch.phone, equals('0712345678'));
      expect(
        branch.createdAt,
        equals(DateTime.parse('2026-06-01T00:00:00.000Z')),
      );
    });

    test('toMap should serialize correctly', () {
      final branch = Branch(
        id: 'branch-uuid-123',
        name: 'Main Branch Nairobi',
        location: 'Westlands, Nairobi',
        phone: '0712345678',
        createdAt: DateTime.parse('2026-06-01T00:00:00.000Z'),
      );

      final json = branch.toMap();

      expect(json['id'], equals('branch-uuid-123'));
      expect(json['name'], equals('Main Branch Nairobi'));
      expect(json['location'], equals('Westlands, Nairobi'));
      expect(json['phone'], equals('0712345678'));
      expect(json['created_at'], equals('2026-06-01T00:00:00.000Z'));
    });
  });
}
