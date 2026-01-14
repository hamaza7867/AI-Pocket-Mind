class ApiRegistry {
  static const Map<String, ApiConfig> providers = {
    'wikipedia': ApiConfig(
      urlTemplate: 'https://en.wikipedia.org/api/rest_v1/page/summary/{query}',
      description: 'Get summary of a topic. Args: Topic_Name',
    ),
    'countries': ApiConfig(
      urlTemplate: 'https://restcountries.com/v3.1/name/{query}',
      description: 'Get country info (pop, flag, capital). Args: CountryName',
    ),
    'universities': ApiConfig(
      urlTemplate: 'http://universities.hipolabs.com/search?name={query}',
      description: 'Find universities. Args: CityOrName',
    ),
    'nasa_apod': ApiConfig(
      urlTemplate: 'https://api.nasa.gov/planetary/apod?api_key=DEMO_KEY',
      description: 'Get NASA Astronomy Picture of the Day. Args: (Ignored)',
      requiresQuery: false,
    ),
    'robohash': ApiConfig(
      urlTemplate: 'https://robohash.org/{query}.png',
      description: 'Generate Robot Avatar. Args: SeedString',
      isImage: true,
    ),
    'dicebear': ApiConfig(
      urlTemplate: 'https://api.dicebear.com/7.x/pixel-art/svg?seed={query}',
      description: 'Generate Pixel Human Avatar. Args: SeedString',
      isImage: true,
    ),
    // --- Public APIs Collection ---
    'finance_rate': ApiConfig(
      urlTemplate: 'https://api.exchangerate-api.com/v4/latest/{query}',
      description: 'Get exchange rates. Args: BaseCurrency (e.g. USD)',
    ),
    'find_book': ApiConfig(
      urlTemplate: 'https://openlibrary.org/search.json?q={query}',
      description: 'Search for books by title/author. Args: Query',
    ),
    'meal_recipe': ApiConfig(
      urlTemplate:
          'https://www.themealdb.com/api/json/v1/1/search.php?s={query}',
      description: 'Find food recipes. Args: MealName (e.g. Pasta)',
    ),
    'cocktail_recipe': ApiConfig(
      urlTemplate:
          'https://www.thecocktaildb.com/api/json/v1/1/search.php?s={query}',
      description: 'Find drink recipes. Args: DrinkName (e.g. Margarita)',
    ),
    'pokemon': ApiConfig(
      urlTemplate: 'https://pokeapi.co/api/v2/pokemon/{query}',
      description: 'Pokémon Info',
      requiresQuery: true,
    ),

    // === NEW TOOLS (15+) ===

    // Math & Conversion
    'exchange': ApiConfig(
      urlTemplate: 'https://api.exchangerate-api.com/v4/latest/{query}',
      description: 'Currency Exchange Rates (use currency code like USD)',
      requiresQuery: true,
    ),
    'crypto': ApiConfig(
      urlTemplate:
          'https://api.coingecko.com/api/v3/simple/price?ids={query}&vs_currencies=usd',
      description: 'Crypto Prices (bitcoin, ethereum, etc.)',
      requiresQuery: true,
    ),

    // News & Information
    'news': ApiConfig(
      urlTemplate:
          'https://newsapi.org/v2/top-headlines?country=us&apiKey=demo&pageSize=5',
      description: 'Latest News Headlines',
      requiresQuery: false,
    ),
    'quotes': ApiConfig(
      urlTemplate: 'https://api.quotable.io/random?tags={query}',
      description: 'Random Inspirational Quotes (tags: wisdom, success, life)',
      requiresQuery: false,
    ),
    'facts': ApiConfig(
      urlTemplate: 'https://uselessfacts.jsph.pl/random.json?language=en',
      description: 'Random Fun Facts',
      requiresQuery: false,
    ),
    'jokes': ApiConfig(
      urlTemplate: 'https://official-joke-api.appspot.com/random_joke',
      description: 'Random Jokes',
      requiresQuery: false,
    ),

    // Dictionary & Language
    'dictionary': ApiConfig(
      urlTemplate: 'https://api.dictionaryapi.dev/api/v2/entries/en/{query}',
      description: 'Word Definitions',
      requiresQuery: true,
    ),
    'translate': ApiConfig(
      urlTemplate:
          'https://api.mymemory.translated.net/get?q={query}&langpair=en|es',
      description: 'Translation (English to Spanish)',
      requiresQuery: true,
    ),

    // Tech & Utilities
    'github': ApiConfig(
      urlTemplate: 'https://api.github.com/users/{query}',
      description: 'GitHub User Info',
      requiresQuery: true,
    ),
    'ip': ApiConfig(
      urlTemplate: 'https://ipapi.co/{query}/json/',
      description: 'IP Address Lookup (leave empty for your IP)',
      requiresQuery: false,
    ),
    'qr': ApiConfig(
      urlTemplate:
          'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data={query}',
      description: 'Generate QR Code',
      requiresQuery: true,
      isImage: true,
    ),

    // Fun & Creative
    'color': ApiConfig(
      urlTemplate: 'https://www.thecolorapi.com/id?hex={query}',
      description: 'Color Information (hex code without #)',
      requiresQuery: true,
    ),
    'advice': ApiConfig(
      urlTemplate: 'https://api.adviceslip.com/advice',
      description: 'Random Advice',
      requiresQuery: false,
    ),
    'dog': ApiConfig(
      urlTemplate: 'https://dog.ceo/api/breeds/image/random',
      description: 'Random Dog Picture',
      requiresQuery: false,
      isImage: true,
    ),
    'cat': ApiConfig(
      urlTemplate: 'https://api.thecatapi.com/v1/images/search',
      description: 'Random Cat Picture',
      requiresQuery: false,
      isImage: true,
    ),
    'urban_dict': ApiConfig(
      urlTemplate: 'https://api.urbandictionary.com/v0/define?term={query}',
      description: 'Get slang definitions. Args: SlangTerm',
    ),
    'weather': ApiConfig(
      urlTemplate: 'https://wttr.in/{query}?format=3',
      description: 'Get current weather. Args: CityName (e.g. London)',
    ),
  };
}

class ApiConfig {
  final String urlTemplate;
  final String description;
  final bool requiresQuery;
  final bool isImage;

  const ApiConfig({
    required this.urlTemplate,
    required this.description,
    this.requiresQuery = true,
    this.isImage = false,
  });
}
