enum NewsCategory {
  WorldNews,
  LocalNews,
  Politics,
  Business,
  Technology,
  Science,
  Health,
  Sports,
  Entertainment,
  Lifestyle,
  Education,
  Environment,
  Travel,
  Culture,
  Opinion,
  Weather,
  Crime,
  Finance,
  RealEstate,
  Automotive,
  Fashion,
  FoodAndDrink,
  Religion,
  ArtAndDesign,
  History,
}


extension NewsCategoryExtension on NewsCategory {
  String get name {
    switch (this) {
      case NewsCategory.WorldNews:
        return 'World News';
      case NewsCategory.LocalNews:
        return 'Local News';
      case NewsCategory.Politics:
        return 'Politics';
      case NewsCategory.Business:
        return 'Business';
      case NewsCategory.Technology:
        return 'Technology';
      case NewsCategory.Science:
        return 'Science';
      case NewsCategory.Health:
        return 'Health';
      case NewsCategory.Sports:
        return 'Sports';
      case NewsCategory.Entertainment:
        return 'Entertainment';
      case NewsCategory.Lifestyle:
        return 'Lifestyle';
      case NewsCategory.Education:
        return 'Education';
      case NewsCategory.Environment:
        return 'Environment';
      case NewsCategory.Travel:
        return 'Travel';
      case NewsCategory.Culture:
        return 'Culture';
      case NewsCategory.Opinion:
        return 'Opinion';
      case NewsCategory.Weather:
        return 'Weather';
      case NewsCategory.Crime:
        return 'Crime';
      case NewsCategory.Finance:
        return 'Finance';
      case NewsCategory.RealEstate:
        return 'Real Estate';
      case NewsCategory.Automotive:
        return 'Automotive';
      case NewsCategory.Fashion:
        return 'Fashion';
      case NewsCategory.FoodAndDrink:
        return 'Food & Drink';
      case NewsCategory.Religion:
        return 'Religion';
      case NewsCategory.ArtAndDesign:
        return 'Art & Design';
      case NewsCategory.History:
        return 'History';
      default:
        return '';
    }
  }
}
