// ─── Exercise types ───────────────────────────────────────────────
enum ExerciseType {
  stereogram,      // Stéréogrammes SIRDS / anaglyphes
  convergence,     // Exercices de convergence (dot tracking)
  saccade,         // Saccades oculaires (cibles qui apparaissent)
  smoothPursuit,   // Poursuite lisse (objet en mouvement)
  anisometropia,   // Patch virtuel - occlusion œil fort
  fusion,          // Fusion binoculaire (cercles de Landolt)
}

enum Difficulty { easy, medium, hard }
enum Eye { left, right, both }

// ─── Exercise definition ──────────────────────────────────────────
class Exercise {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final ExerciseType type;
  final Difficulty difficulty;
  final int durationSeconds;
  final String instructions;
  final Map<String, dynamic> config;

  const Exercise({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.type,
    required this.difficulty,
    required this.durationSeconds,
    required this.instructions,
    this.config = const {},
  });
}

// ─── Exercise catalogue ───────────────────────────────────────────
class ExerciseCatalogue {
  static const List<Exercise> all = [
    Exercise(
      id: 'stereo_1',
      title: 'Orbes Laser',
      description: 'Fais converger les orbes rouges et verts pour les fusionner !',
      emoji: '🔴🟢',
      type: ExerciseType.stereogram,
      difficulty: Difficulty.easy,
      durationSeconds: 60,
      instructions: 'Regarde entre les deux orbes. Détends tes yeux jusqu\'à en voir trois. Celui du milieu est la magie de tes deux yeux ensemble !',
      config: {'separation': 60, 'depth': 3},
    ),
    Exercise(
      id: 'convergence_1',
      title: 'Attrape l\'Étoile',
      description: 'Suis l\'étoile qui se rapproche de ton nez !',
      emoji: '⭐',
      type: ExerciseType.convergence,
      difficulty: Difficulty.easy,
      durationSeconds: 45,
      instructions: 'Fixe l\'étoile et suis-la avec tes yeux jusqu\'à ce qu\'elle touche ton nez. Maintiens la netteté !',
    ),
    Exercise(
      id: 'saccade_1',
      title: 'Chasseur d\'Astéroïdes',
      description: 'Trouve et touche les astéroïdes qui apparaissent !',
      emoji: '☄️',
      type: ExerciseType.saccade,
      difficulty: Difficulty.easy,
      durationSeconds: 60,
      instructions: 'Des astéroïdes vont apparaître à l\'écran. Déplace ton regard rapidement pour les trouver et touche-les !',
      config: {'targets': 10, 'speed': 1.0},
    ),
    Exercise(
      id: 'pursuit_1',
      title: 'Pilote Stellaire',
      description: 'Suis le vaisseau dans sa trajectoire orbitale',
      emoji: '🚀',
      type: ExerciseType.smoothPursuit,
      difficulty: Difficulty.easy,
      durationSeconds: 60,
      instructions: 'Garde tes yeux sur le vaisseau sans bouger la tête. Suis sa trajectoire fluide !',
      config: {'speed': 0.8, 'pattern': 'circle'},
    ),
    Exercise(
      id: 'patch_1',
      title: 'Mission Œil Gauche',
      description: 'Entraîne ton œil gauche en mode solo !',
      emoji: '👁️',
      type: ExerciseType.anisometropia,
      difficulty: Difficulty.medium,
      durationSeconds: 120,
      instructions: 'Ton œil droit est masqué. Utilise ton œil gauche pour résoudre les puzzles !',
      config: {'patchedEye': 'right', 'gameMode': 'puzzle'},
    ),
    Exercise(
      id: 'fusion_1',
      title: 'Fusion Galactique',
      description: 'Fusionne les deux images pour révéler la planète cachée',
      emoji: '🌍',
      type: ExerciseType.fusion,
      difficulty: Difficulty.medium,
      durationSeconds: 90,
      instructions: 'Regarde les deux images et essaie de les superposer mentalement. La planète apparaîtra quand tes yeux travailleront ensemble !',
    ),
    Exercise(
      id: 'stereo_2',
      title: 'Portail Dimensionnel',
      description: 'Stéréogramme avancé - découvre la forme cachée en 3D',
      emoji: '🌀',
      type: ExerciseType.stereogram,
      difficulty: Difficulty.hard,
      durationSeconds: 90,
      instructions: 'Détends ton regard comme si tu regardais au loin. Un objet 3D va émerger du motif !',
      config: {'separation': 80, 'depth': 5},
    ),
    Exercise(
      id: 'saccade_2',
      title: 'Défense Planétaire',
      description: 'Saccades rapides entre 3 cibles simultanées',
      emoji: '🛸',
      type: ExerciseType.saccade,
      difficulty: Difficulty.hard,
      durationSeconds: 60,
      instructions: 'Des envahisseurs vont apparaître. Déplace ton regard rapidement de l\'un à l\'autre pour les neutraliser !',
      config: {'targets': 20, 'speed': 2.0, 'simultaneous': 3},
    ),
  ];

  static List<Exercise> byType(ExerciseType type) =>
      all.where((e) => e.type == type).toList();

  static List<Exercise> byDifficulty(Difficulty d) =>
      all.where((e) => e.difficulty == d).toList();
}

// ─── Session result ───────────────────────────────────────────────
class ExerciseResult {
  final String exerciseId;
  final DateTime completedAt;
  final int score;
  final int stars; // 1-3
  final int durationSeconds;
  final Map<String, dynamic> metrics;

  const ExerciseResult({
    required this.exerciseId,
    required this.completedAt,
    required this.score,
    required this.stars,
    required this.durationSeconds,
    this.metrics = const {},
  });

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'completedAt': completedAt.toIso8601String(),
    'score': score,
    'stars': stars,
    'durationSeconds': durationSeconds,
    'metrics': metrics,
  };

  factory ExerciseResult.fromJson(Map<String, dynamic> j) => ExerciseResult(
    exerciseId: j['exerciseId'],
    completedAt: DateTime.parse(j['completedAt']),
    score: j['score'],
    stars: j['stars'],
    durationSeconds: j['durationSeconds'],
    metrics: j['metrics'] ?? {},
  );
}

// ─── User profile ─────────────────────────────────────────────────
class UserProfile {
  final String name;
  final int age;
  final Eye dominantEye;
  final List<String> conditions; // amblyopie, strabisme, etc.
  final int totalScore;
  final int level;
  final int energy;
  final int maxEnergy;
  final List<ExerciseResult> history;

  const UserProfile({
    required this.name,
    required this.age,
    required this.dominantEye,
    required this.conditions,
    this.totalScore = 0,
    this.level = 1,
    this.energy = 12,
    this.maxEnergy = 12,
    this.history = const [],
  });

  int get xpForNextLevel => level * 1000;
  int get currentXp => totalScore % xpForNextLevel;
  double get xpProgress => currentXp / xpForNextLevel;

  UserProfile copyWith({
    String? name, int? age, Eye? dominantEye,
    List<String>? conditions, int? totalScore,
    int? level, int? energy, int? maxEnergy,
    List<ExerciseResult>? history,
  }) => UserProfile(
    name: name ?? this.name,
    age: age ?? this.age,
    dominantEye: dominantEye ?? this.dominantEye,
    conditions: conditions ?? this.conditions,
    totalScore: totalScore ?? this.totalScore,
    level: level ?? this.level,
    energy: energy ?? this.energy,
    maxEnergy: maxEnergy ?? this.maxEnergy,
    history: history ?? this.history,
  );

  Map<String, dynamic> toJson() => {
    'name': name, 'age': age,
    'dominantEye': dominantEye.index,
    'conditions': conditions,
    'totalScore': totalScore, 'level': level,
    'energy': energy, 'maxEnergy': maxEnergy,
    'history': history.map((r) => r.toJson()).toList(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    name: j['name'], age: j['age'],
    dominantEye: Eye.values[j['dominantEye']],
    conditions: List<String>.from(j['conditions']),
    totalScore: j['totalScore'], level: j['level'],
    energy: j['energy'], maxEnergy: j['maxEnergy'],
    history: (j['history'] as List)
        .map((r) => ExerciseResult.fromJson(r))
        .toList(),
  );
}
