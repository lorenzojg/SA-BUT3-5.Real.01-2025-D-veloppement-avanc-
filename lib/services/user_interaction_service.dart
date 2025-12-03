import '../models/destination_model.dart';
import '../models/user_interaction_model.dart';
import '../models/user_profile_vector.dart';

class UserInteractionService {
  
  /// Met à jour le vecteur utilisateur en fonction d'une nouvelle interaction
  /// C'est ici que se passe l'apprentissage (Feedback Loop)
  static UserProfileVector updateUserProfile(
    UserProfileVector currentProfile,
    Destination destination,
    UserInteraction interaction,
  ) {
    // 1. Déterminer le taux d'apprentissage (Learning Rate)
    // Plus c'est haut, plus le profil change vite
    double learningRate = 0.1; // Valeur par défaut

    // Ajustement selon la vitesse de réaction (Roadmap Phase 3)
    if (interaction.type == InteractionType.dislike) {
      if (interaction.durationMs < 500) {
        // Dislike très rapide (< 0.5s) = Rejet viscéral
        learningRate = 0.2; 
      } else if (interaction.durationMs > 2000) {
        // Dislike lent (> 2s) = Hésitation
        learningRate = 0.05;
      }
    } else if (interaction.type == InteractionType.like) {
      if (interaction.durationMs < 500) {
        // Like très rapide = Coup de coeur
        learningRate = 0.15;
      }
    } else if (interaction.type == InteractionType.viewDetails) {
      // Intérêt latent (faible impact mais positif)
      learningRate = 0.02;
    } else if (interaction.type == InteractionType.addToFavorites) {
      // Signal très fort
      learningRate = 0.25;
    }

    // 2. Déterminer la direction de l'ajustement
    // +1 pour Like/Fav/View, -1 pour Dislike
    double direction = 1.0;
    if (interaction.type == InteractionType.dislike) {
      direction = -1.0;
    }

    // 3. Appliquer la formule de mise à jour pour chaque dimension du vecteur
    // Nouveau = Ancien + (LearningRate * Direction * ScoreDestination)
    // On rapproche ou on éloigne le vecteur utilisateur de celui de la destination
    
    currentProfile.culture = _updateDimension(currentProfile.culture, destination.scoreCulture, learningRate, direction);
    currentProfile.adventure = _updateDimension(currentProfile.adventure, destination.scoreAdventure, learningRate, direction);
    currentProfile.nature = _updateDimension(currentProfile.nature, destination.scoreNature, learningRate, direction);
    currentProfile.beaches = _updateDimension(currentProfile.beaches, destination.scoreBeaches, learningRate, direction);
    currentProfile.nightlife = _updateDimension(currentProfile.nightlife, destination.scoreNightlife, learningRate, direction);
    currentProfile.cuisine = _updateDimension(currentProfile.cuisine, destination.scoreCuisine, learningRate, direction);
    currentProfile.wellness = _updateDimension(currentProfile.wellness, destination.scoreWellness, learningRate, direction);
    currentProfile.urban = _updateDimension(currentProfile.urban, destination.scoreUrban, learningRate, direction);
    currentProfile.seclusion = _updateDimension(currentProfile.seclusion, destination.scoreSeclusion, learningRate, direction);

    return currentProfile;
  }

  static double _updateDimension(double userValue, double destValue, double rate, double direction) {
    // Formule : User_new = User_old + alpha * (Dest - User_old) * direction
    // Si direction est positive (Like), on tire User vers Dest
    // Si direction est négative (Dislike), on pousse User loin de Dest
    
    // Simplification pour l'instant : on ajoute/soustrait juste une fraction du score de la destination
    // pour éviter de dériver trop loin des bornes (0-10 ou 0-5)
    
    double delta = destValue * rate * direction;
    double newValue = userValue + delta;
    
    // Clamp pour rester dans des limites raisonnables (ex: 0 à 10)
    if (newValue < 0) newValue = 0;
    if (newValue > 10) newValue = 10; // Supposant que l'échelle max est 10
    
    return newValue;
  }
}
