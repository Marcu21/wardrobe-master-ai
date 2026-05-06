class OutfitSortingUtils {
  static List<Map<String, dynamic>> sortOutfitItems(List<Map<String, dynamic>> items) {
    int getScore(Map<String, dynamic> item) {
      final info = item['metadata']?['basic_info'] ?? item['basic_info'] ?? {};
      String cat = '';
      String sub = '';

      if (item.containsKey('category')) {
        cat = item['category'].toString().toLowerCase();
      } else if (info is Map && info.containsKey('category')) {
        cat = info['category'].toString().toLowerCase();
      }

      if (item.containsKey('sub_category')) {
        sub = item['sub_category'].toString().toLowerCase();
      } else if (info is Map && info.containsKey('sub_category')) {
        sub = info['sub_category'].toString().toLowerCase();
      }

      // 0: Head / Hats / Caps
      if (cat.contains('head') || sub.contains('hat') || sub.contains('cap') || sub.contains('beanie')) return 0;
      
      // 1: Outerwear / Jackets / Coats
      if (cat.contains('outerwear') || sub.contains('jacket') || sub.contains('coat') || sub.contains('blazer')) return 1;
      
      // 2: Midwear / Sweaters / Hoodies / Cardigans
      if (cat.contains('midwear') || sub.contains('sweater') || sub.contains('hoodie') || sub.contains('cardigan') || sub.contains('sweatshirt')) return 2;
      
      // 4: Bottoms / Pants / Jeans / Skirts / Shorts
      if (cat.contains('bottom') || cat.contains('pant') || sub.contains('jean') || sub.contains('skirt') || sub.contains('short') || sub.contains('legging')) return 4;
      
      // 5: Shoes / Footwear / Sneakers / Boots
      if (cat.contains('shoe') || cat.contains('footwear') || sub.contains('sneaker') || sub.contains('boot') || sub.contains('sandal')) return 5;
      
      // 3: Tops / Shirts / Blouses / T-shirts (Default fallback)
      return 3;
    }

    items.sort((a, b) => getScore(a).compareTo(getScore(b)));
    return items;
  }
}
