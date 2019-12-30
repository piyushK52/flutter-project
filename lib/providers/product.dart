import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Product with ChangeNotifier {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  bool isFavorite;

  Product({
    @required this.id,
    @required this.title,
    @required this.description,
    @required this.imageUrl,
    this.isFavorite = false,
    @required this.price,
  });

  Future<void> toggleFavoriteStatus(String token) async {
    final url = 'https://flutter-update-ff151.firebaseio.com/products/$id.json?auth=$token';
    try {
      await http.patch(
        url,
        body: json.encode({
          'isFavorite': !isFavorite,
        }),
      );
      isFavorite = !isFavorite;
      notifyListeners();
    } catch (error) {}
  }
}
