import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/shop.dart';
import '../models/payment_method.dart';
import '../models/discount.dart';
import '../models/category_config.dart';

class DataRepository {
  List<Shop> shops = [];
  List<PaymentMethod> paymentMethods = [];
  List<Discount> discounts = [];
  CategoryConfig? categoryConfig;

  Future<void> loadData() async {
    final String shopsJson = await rootBundle.loadString(
      'assets/data/shops.json',
    );
    final String paymentsJson = await rootBundle.loadString(
      'assets/data/payment_methods.json',
    );
    final String discountsJson = await rootBundle.loadString(
      'assets/data/discounts.json',
    );
    final String productDiscountsJson = await rootBundle.loadString(
      'assets/data/discounts_product.json',
    );
    final String categoryConfigJson = await rootBundle.loadString(
      'assets/data/category_config.json',
    );

    final List<dynamic> shopsData = json.decode(shopsJson);
    final List<dynamic> paymentsData = json.decode(paymentsJson);
    final List<dynamic> discountsData = json.decode(discountsJson);
    final List<dynamic> productDiscountsData = json.decode(
      productDiscountsJson,
    );
    final Map<String, dynamic> configData = json.decode(categoryConfigJson);

    shops = shopsData.map((d) => Shop.fromJson(d)).toList();
    paymentMethods = paymentsData
        .map((d) => PaymentMethod.fromJson(d))
        .toList();
    categoryConfig = CategoryConfig.fromJson(configData);

    for (var d in productDiscountsData) {
      d['is_product'] = true;
    }

    final allDiscounts = [...discountsData, ...productDiscountsData];
    discounts = allDiscounts.map((d) => Discount.fromJson(d)).toList();
  }
}
