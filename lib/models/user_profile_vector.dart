class UserProfileVector {
  double culture;
  double adventure;
  double nature;
  double beaches;
  double nightlife;
  double cuisine;
  double wellness;
  double urban;
  double seclusion;

  UserProfileVector({
    this.culture = 0.0,
    this.adventure = 0.0,
    this.nature = 0.0,
    this.beaches = 0.0,
    this.nightlife = 0.0,
    this.cuisine = 0.0,
    this.wellness = 0.0,
    this.urban = 0.0,
    this.seclusion = 0.0,
  });
  
  // Copie profonde pour éviter les effets de bord
  UserProfileVector clone() {
    return UserProfileVector(
      culture: culture,
      adventure: adventure,
      nature: nature,
      beaches: beaches,
      nightlife: nightlife,
      cuisine: cuisine,
      wellness: wellness,
      urban: urban,
      seclusion: seclusion,
    );
  }
}
