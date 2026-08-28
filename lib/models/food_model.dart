/// A food item / restaurant entry.
class FoodItemModel {
  final String foodId;
  final String name;
  final String category;   // e.g. "Street Food", "Restaurant", "Cafe"
  final String cuisine;    // e.g. "South Indian", "Chinese"
  final double rating;
  final String priceRange; // e.g. "₹", "₹₹", "₹₹₹"
  final String placeId;
  final String? description;
  final bool isVeg;

  const FoodItemModel({
    required this.foodId,
    required this.name,
    required this.category,
    required this.cuisine,
    this.rating = 4.0,
    this.priceRange = '₹₹',
    required this.placeId,
    this.description,
    this.isVeg = false,
  });

  factory FoodItemModel.fromMap(String id, Map<String, dynamic> map) {
    return FoodItemModel(
      foodId: id,
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      cuisine: map['cuisine'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.0,
      priceRange: map['priceRange'] as String? ?? '₹₹',
      placeId: map['placeId'] as String? ?? '',
      description: map['description'] as String?,
      isVeg: map['isVeg'] as bool? ?? false,
    );
  }

  /// Map an OpenStreetMap Nominatim result to a [FoodItemModel].
  factory FoodItemModel.fromNominatim(String id, Map<String, dynamic> map) {
    final displayName = map['display_name'] as String? ?? 'Unknown Place';
    final shortName = displayName.split(',').first.trim();
    return FoodItemModel(
      foodId: id,
      name: shortName,
      category: 'Restaurant',
      cuisine: 'Local',
      rating: 4.0,
      priceRange: '₹₹',
      placeId: map['place_id']?.toString() ?? id,
      description: displayName,
      isVeg: false,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'cuisine': cuisine,
        'rating': rating,
        'priceRange': priceRange,
        'placeId': placeId,
        if (description != null) 'description': description,
        'isVeg': isVeg,
      };

  @override
  String toString() => 'FoodItemModel($foodId, $name, $cuisine)';
}
