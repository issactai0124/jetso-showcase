import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/data_repository.dart';
import '../models/shop.dart';
import '../models/payment_method.dart';
import '../models/discount.dart';

final dataRepositoryProvider = Provider<DataRepository>((ref) {
  return DataRepository();
});

final dataInitializationProvider = FutureProvider<void>((ref) async {
  final repository = ref.watch(dataRepositoryProvider);
  await repository.loadData();
});

final shopsProvider = Provider<List<Shop>>((ref) {
  return ref.watch(dataRepositoryProvider).shops;
});

final paymentMethodsProvider = Provider<List<PaymentMethod>>((ref) {
  return ref.watch(dataRepositoryProvider).paymentMethods;
});

final discountsProvider = Provider<List<Discount>>((ref) {
  return ref.watch(dataRepositoryProvider).discounts;
});
