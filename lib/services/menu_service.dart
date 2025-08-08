class MenuItem {
  final String timeSlot; // 'Breakfast', 'Lunch', 'Snacks', 'Dinner'
  final String veg;
  final String nonVeg;
  const MenuItem({
    required this.timeSlot,
    required this.veg,
    required this.nonVeg,
  });
}

class DailyMenu {
  final DateTime date;
  final List<MenuItem> items;
  const DailyMenu({required this.date, required this.items});
}

class MenuService {
  // In production, read from Firestore weekly menu; fallback to generated.
  DailyMenu getMenuFor(DateTime date) {
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

// Firebase schema idea (weekly repeating):
// collection: weeklyMenu
// doc: week_{1..7} (1=Mon .. 7=Sun)
// fields: breakfastVeg, breakfastNonVeg, lunchVeg, lunchNonVeg, snacksVeg, snacksNonVeg, dinnerVeg, dinnerNonVeg
