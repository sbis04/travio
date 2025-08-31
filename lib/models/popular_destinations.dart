/// Simple model for a travel destination.
class PopularDestination {
  const PopularDestination({
    required this.name,
    required this.description,
    required this.assetImage,
  });

  final String name;
  final String description;
  final String assetImage;

  Map<String, String> toMapEntry() => {name: description};
}

/// Strongly-typed list built from the map (order preserved below if needed).
const List<PopularDestination> kDestinations = [
  PopularDestination(
    name: 'Paris, France',
    description: 'City of Light—Eiffel Tower, Louvre, cafés along the Seine.',
    assetImage: 'assets/images/paris.jpg',
  ),
  PopularDestination(
    name: 'Rome, Italy',
    description:
        'Ancient wonders—Colosseum, Vatican, piazzas, and pasta culture.',
    assetImage: 'assets/images/rome.jpg',
  ),
  PopularDestination(
    name: 'Bali, Indonesia',
    description: 'Tropical temples, rice terraces, surf beaches, and wellness.',
    assetImage: 'assets/images/bali.jpg',
  ),
  PopularDestination(
    name: 'New York City, USA',
    description:
        'Skyscrapers, Central Park, Broadway, and nonstop neighborhoods.',
    assetImage: 'assets/images/new_york.jpg',
  ),
  PopularDestination(
    name: 'Tokyo, Japan',
    description:
        'Tradition meets neon—shrines, sushi, tech, and cherry blossoms.',
    assetImage: 'assets/images/tokyo.jpg',
  ),
  PopularDestination(
    name: 'Dubai, UAE',
    description: 'Futuristic skyline, luxury malls, desert safaris, and souks.',
    assetImage: 'assets/images/dubai.jpg',
  ),
  PopularDestination(
    name: 'Bangkok, Thailand',
    description: 'Street-food capital with ornate temples and lively markets.',
    assetImage: 'assets/images/bangkok.jpg',
  ),
  PopularDestination(
    name: 'London, UK',
    description: 'Royal landmarks, world-class museums, theaters, and pubs.',
    assetImage: 'assets/images/london.jpg',
  ),
  PopularDestination(
    name: 'Barcelona, Spain',
    description:
        'Gaudí architecture, Mediterranean beaches, and tapas culture.',
    assetImage: 'assets/images/barcelona.jpg',
  ),
  PopularDestination(
    name: 'Istanbul, Türkiye',
    description:
        'Where Europe meets Asia—Hagia Sophia, bazaars, Bosphorus views.',
    assetImage: 'assets/images/istanbul.jpg',
  ),
  PopularDestination(
    name: 'Singapore',
    description:
        'Ultra-modern city-garden with hawker food and waterfront skyline.',
    assetImage: 'assets/images/singapore.jpg',
  ),
  PopularDestination(
    name: 'Sydney, Australia',
    description:
        'Harbour city—Opera House, Harbour Bridge, and famous beaches.',
    assetImage: 'assets/images/sydney.jpg',
  ),
  PopularDestination(
    name: 'Maldives',
    description: 'Overwater villas, turquoise lagoons, and world-class diving.',
    assetImage: 'assets/images/maldives.jpg',
  ),
  PopularDestination(
    name: 'Santorini, Greece',
    description:
        'Whitewashed cliffs, blue domes, caldera sunsets, volcanic sand.',
    assetImage: 'assets/images/santorini.jpg',
  ),
];
