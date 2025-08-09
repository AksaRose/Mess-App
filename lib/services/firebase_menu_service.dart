import 'package:cloud_firestore/cloud_firestore.dart';
import 'menu_service.dart';

class FirebaseMenuService extends MenuService {
  final FirebaseFirestore _db;
  
  FirebaseMenuService({FirebaseFirestore? firestore}) 
      : _db = firestore ?? FirebaseFirestore.instance;

  @override
  DailyMenu getMenuFor(DateTime date) {
    // For now, return placeholder until we implement async loading
    // This will be replaced with a Future-based approach
    final seed = date.day % 7;
    final items = <MenuItem>[
      MenuItem(timeSlot: 'Breakfast', veg: 'Idli Sambar', nonVeg: 'Egg Bhurji'),
      MenuItem(
        timeSlot: 'Lunch',
        veg: 'Veg Thali $seed',
        nonVeg: 'Chicken Curry $seed',
      ),
      const MenuItem(
        timeSlot: 'Snacks (4 PM)',
        veg: 'Samosa',
        nonVeg: 'Egg Puff',
      ),
      MenuItem(
        timeSlot: 'Dinner',
        veg: 'Paneer Masala $seed',
        nonVeg: 'Fish Fry $seed',
      ),
    ];
    return DailyMenu(
      date: DateTime(date.year, date.month, date.day),
      items: items,
    );
  }

  Future<DailyMenu> getMenuForAsync(DateTime date) async {
    final weekday = date.weekday; // 1=Monday, 7=Sunday
    final docId = 'week_$weekday';
    
    try {
      final doc = await _db.collection('weeklyMenu').doc(docId).get();
      if (!doc.exists) {
        return _getDefaultMenu(date);
      }
      
      final data = doc.data()!;
      final items = <MenuItem>[
        MenuItem(
          timeSlot: 'Breakfast',
          veg: data['breakfastVeg'] ?? 'Idli Sambar',
          nonVeg: data['breakfastNonVeg'] ?? 'Egg Bhurji',
        ),
        MenuItem(
          timeSlot: 'Lunch',
          veg: data['lunchVeg'] ?? 'Veg Thali',
          nonVeg: data['lunchNonVeg'] ?? 'Chicken Curry',
        ),
        MenuItem(
          timeSlot: 'Snacks (4 PM)',
          veg: data['snacksVeg'] ?? 'Samosa',
          nonVeg: data['snacksNonVeg'] ?? 'Egg Puff',
        ),
        MenuItem(
          timeSlot: 'Dinner',
          veg: data['dinnerVeg'] ?? 'Paneer Masala',
          nonVeg: data['dinnerNonVeg'] ?? 'Fish Fry',
        ),
      ];
      
      return DailyMenu(
        date: DateTime(date.year, date.month, date.day),
        items: items,
      );
    } catch (e) {
      return _getDefaultMenu(date);
    }
  }

  DailyMenu _getDefaultMenu(DateTime date) {
    final seed = date.day % 7;
    final items = <MenuItem>[
      MenuItem(timeSlot: 'Breakfast', veg: 'Idli Sambar', nonVeg: 'Egg Bhurji'),
      MenuItem(
        timeSlot: 'Lunch',
        veg: 'Veg Thali $seed',
        nonVeg: 'Chicken Curry $seed',
      ),
      const MenuItem(
        timeSlot: 'Snacks (4 PM)',
        veg: 'Samosa',
        nonVeg: 'Egg Puff',
      ),
      MenuItem(
        timeSlot: 'Dinner',
        veg: 'Paneer Masala $seed',
        nonVeg: 'Fish Fry $seed',
      ),
    ];
    return DailyMenu(
      date: DateTime(date.year, date.month, date.day),
      items: items,
    );
  }
}
