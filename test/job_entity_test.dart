import 'package:flutter_test/flutter_test.dart';
import 'package:laboraya_app/features/jobs/domain/entities/job_entity.dart';

void main() {
  group('JobEntity', () {
    test('formattedBudget shows fixed when budgetFixed', () {
      final job = JobEntity(
        id: '1', title: 'Test', description: '', categoryId: '', categoryName: '',
        modality: 'PER_DAY', publisherId: '', publisherName: '', createdAt: DateTime.now(),
        budgetMin: 120, budgetFixed: true,
      );
      expect(job.formattedBudget, 'S/ 120');
    });

    test('formattedBudget shows range', () {
      final job = JobEntity(
        id: '1', title: 'Test', description: '', categoryId: '', categoryName: '',
        modality: 'PER_DAY', publisherId: '', publisherName: '', createdAt: DateTime.now(),
        budgetMin: 100, budgetMax: 200,
      );
      expect(job.formattedBudget, 'S/ 100 - 200');
    });

    test('formattedBudget shows A convenir when no budget', () {
      final job = JobEntity(
        id: '1', title: 'Test', description: '', categoryId: '', categoryName: '',
        modality: 'PER_DAY', publisherId: '', publisherName: '', createdAt: DateTime.now(),
      );
      expect(job.formattedBudget, 'A convenir');
    });

    test('modalityLabel returns correct Spanish label', () {
      final job = JobEntity(
        id: '1', title: 'Test', description: '', categoryId: '', categoryName: '',
        modality: 'PER_DAY', publisherId: '', publisherName: '', createdAt: DateTime.now(),
      );
      expect(job.modalityLabel, 'Por día');
    });

    test('modalityLabel PER_WEEK', () {
      final job = JobEntity(
        id: '1', title: 'Test', description: '', categoryId: '', categoryName: '',
        modality: 'PER_WEEK', publisherId: '', publisherName: '', createdAt: DateTime.now(),
      );
      expect(job.modalityLabel, 'Por semana');
    });

    test('materialsLabel returns correct label', () {
      final job = JobEntity(
        id: '1', title: 'Test', description: '', categoryId: '', categoryName: '',
        modality: 'PER_DAY', publisherId: '', publisherName: '', createdAt: DateTime.now(),
        materials: 'BY_WORKER',
      );
      expect(job.materialsLabel, 'A cargo del trabajador');
    });
  });
}
