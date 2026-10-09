import 'dart:convert';
import 'dart:io';

/// Open Food Facts (open data, ODbL) product lookup by barcode. Only the
/// barcode number is sent.
class FoodFactsApi {
  static const _fields =
      'product_name,product_name_en,brands,quantity,product_quantity,product_quantity_unit,serving_size,'
      'serving_quantity,nutriments,categories_tags';

  /// The product JSON, or null when Open Food Facts doesn't know the barcode.
  /// Throws on network errors.
  Future<Map<String, dynamic>?> product(String barcode) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final uri = Uri.parse('https://world.openfoodfacts.org/api/v2/product/$barcode.json?fields=$_fields');
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.userAgentHeader, 'RUVA/1.0 (personal wellness app)');
      final res = await req.close().timeout(const Duration(seconds: 15));
      if (res.statusCode == 404) return null;
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
      final json = jsonDecode(await res.transform(utf8.decoder).join()) as Map<String, dynamic>;
      return json['status'] == 1 ? (json['product'] as Map).cast<String, dynamic>() : null;
    } finally {
      client.close(force: true);
    }
  }
}
