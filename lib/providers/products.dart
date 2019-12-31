import 'package:flutter/material.dart';
import 'dart:convert';

import './product.dart';
import '../models/http_exceptions.dart';
import 'package:http/http.dart' as http;

class Products with ChangeNotifier {
  List<Product> _items = [
    Product(
      id: 'p1',
      title: 'Red Shirt',
      description: 'A red shirt - it is pretty red!',
      price: 29.99,
      imageUrl:
          'https://cdn.pixabay.com/photo/2016/10/02/22/17/red-t-shirt-1710578_1280.jpg',
    ),
    Product(
      id: 'p2',
      title: 'Trousers',
      description: 'A nice pair of trousers.',
      price: 59.99,
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Trousers%2C_dress_%28AM_1960.022-8%29.jpg/512px-Trousers%2C_dress_%28AM_1960.022-8%29.jpg',
    ),
    Product(
      id: 'p3',
      title: 'Yellow Scarf',
      description: 'Warm and cozy - exactly what you need for the winter.',
      price: 19.99,
      imageUrl:
          'https://live.staticflickr.com/4043/4438260868_cc79b3369d_z.jpg',
    ),
    Product(
      id: 'p4',
      title: 'A Pan',
      description: 'Prepare any meal you want.',
      price: 49.99,
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Cast-Iron-Pan.jpg/1024px-Cast-Iron-Pan.jpg',
    ),
  ];

  // var _showFavoritesOnly = false;
  final String authToken;
  final String userId;

  Products(this.authToken, this.userId, this._items);

  List<Product> get items {
    // print("=========");
    // print(_showFavoritesOnly);
    // if(_showFavoritesOnly) {
    //   return _items.where((prodItem) => prodItem.isFavorite).toList();
    // }
    return [..._items];
  }

  List<Product> get favoriteItems {
    return _items.where((prodItem) => prodItem.isFavorite).toList();
  }

  // void showFavoritesOnly() {
  //   _showFavoritesOnly = true;
  //   notifyListeners();
  // }

  // void showAll() {
  //   _showFavoritesOnly = false;
  //   notifyListeners();
  // }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }

  Future<void> fetchAndSetProducts([bool filterByUser = false]) async {
    final filterString = filterByUser ? 'orderBy="creatorId"&equalTo="$userId"' : '';
    final url = 'https://flutter-update-ff151.firebaseio.com/products.json?auth=$authToken&$filterString';
    try{
      final response = await http.get(url);
      print('http get response found out');
      final extractedData = json.decode(response.body) as Map<String,dynamic>;
      print('http response converted');
      if(extractedData == null) {
        print('returning because of error');
        return;
      }
      final favUrl = 'https://flutter-update-ff151.firebaseio.com/userFavorite/$userId.json?auth=$authToken';
      final favoriteResponse =  await http.get(favUrl);
      final favoriteData = json.decode(favoriteResponse.body);
      final List<Product> loaderProducts = [];
      print('starting the foreach loop');
      extractedData.forEach((prodId,prodData) {
        loaderProducts.add(Product(
          id: prodId,
          title: prodData['title'],
          description: prodData['description'],
          price: prodData['price'],
          isFavorite: favoriteData == null ? false : favoriteData[prodId] ?? false,
          imageUrl: prodData['imageUrl']
        ));
      });
      print('foreach completed, notifying the listeners');
      _items = loaderProducts;
      notifyListeners();
    } catch(error) {
      throw error;
    }
    
  }

  Future<void> addProduct(Product product) async {
    final url = 'https://flutter-update-ff151.firebaseio.com/products.json?auth=$authToken';
    try {
      final response = await http.post(
        url,
        body: json.encode({
          'title': product.title,
          'price': product.price,
          'imageUrl': product.imageUrl,
          'description': product.description,
          'isFavorite': product.isFavorite,
          'creatorId': userId,
        }),
      );
      final newProduct = Product(
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
        id: json.decode(response.body)['name'],
      );
      _items.add(newProduct);
      notifyListeners();
    } catch (error) {
      print(error);
      throw error;
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final prodIndex = _items.indexWhere((prod) => prod.id == id);
    if (prodIndex >= 0) {
      final url = 'https://flutter-update-ff151.firebaseio.com/products/$id.json?auth=$authToken';
      await http.patch(url, body: json.encode({
        'title':newProduct.title,
        'description':newProduct.description,
        'imageUrl':newProduct.imageUrl,
        'price':newProduct.price
      }));
      _items[prodIndex] = newProduct;
      notifyListeners();
    } else {
      print('...');
    }
  }

  Future<void> deleteProduct(String id) async {
    final url = 'https://flutter-update-ff151.firebaseio.com/products/$id.json?auth=$authToken';
    await http.delete(url).then((response){
      if(response.statusCode >= 400) {
        throw HttpException('Could not delete product');
      }
      else {
        _items.removeWhere((prod) => prod.id == id);
      }
    });
    
    notifyListeners();
  }
}
