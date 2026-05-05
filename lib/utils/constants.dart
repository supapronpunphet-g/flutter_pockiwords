import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFFF8FB1);       // pocki pink
  static const Color primaryDark = Color(0xFFE26A8E);
  static const Color secondary = Color(0xFFFFD6E0);     // soft pink
  static const Color accent = Color(0xFFB5EAD7);        // mint
  static const Color accentAlt = Color(0xFFC7CEEA);     // periwinkle
  static const Color background = Color(0xFFFFF5F7);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF3D2C3F);
  static const Color textSecondary = Color(0xFF7B6B7E);
  static const Color error = Color(0xFFE57373);
  static const Color success = Color(0xFF81C784);
  static const Color warning = Color(0xFFFFB74D);
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double pill = 999;
}

class FirestoreCollections {
  static const String users = 'users';
  static const String decks = 'decks';
  // `cards` is the name of the subcollection under each deck:
  // decks/{deckId}/cards/{cardId}.
  static const String cards = 'cards';
  static const String favorites = 'favorites';
  static const String scores = 'scores';
}

enum CardDifficulty { easy, medium, hard }

extension CardDifficultyX on CardDifficulty {
  String get label => switch (this) {
        CardDifficulty.easy => 'Easy',
        CardDifficulty.medium => 'Medium',
        CardDifficulty.hard => 'Hard',
      };

  Color get color => switch (this) {
        CardDifficulty.easy => AppColors.success,
        CardDifficulty.medium => AppColors.warning,
        CardDifficulty.hard => AppColors.error,
      };

  static CardDifficulty fromString(String? value) {
    return CardDifficulty.values.firstWhere(
      (d) => d.name == value,
      orElse: () => CardDifficulty.medium,
    );
  }
}

enum GameType { matchPairs, multipleChoice, typing, memoryFlip, speedRush }

extension GameTypeX on GameType {
  String get label => switch (this) {
        GameType.matchPairs => 'Match Pairs',
        GameType.multipleChoice => 'Multiple Choice',
        GameType.typing => 'Typing Challenge',
        GameType.memoryFlip => 'Memory Flip',
        GameType.speedRush => 'Speed Rush',
      };

  String get description => switch (this) {
        GameType.matchPairs =>
          'Match each word with its translation as fast as you can.',
        GameType.multipleChoice => 'Pick the right translation from 4 choices.',
        GameType.typing => 'Type the word from its translation.',
        GameType.memoryFlip => 'Flip cards and find the matching pairs.',
        GameType.speedRush => 'How many can you answer in 30 seconds?',
      };

  IconData get icon => switch (this) {
        GameType.matchPairs => Icons.compare_arrows_rounded,
        GameType.multipleChoice => Icons.quiz_rounded,
        GameType.typing => Icons.keyboard_rounded,
        GameType.memoryFlip => Icons.grid_view_rounded,
        GameType.speedRush => Icons.bolt_rounded,
      };

  /// Pretty gradient for the game tile, in the cute pink/pastel style.
  List<Color> get gradient => switch (this) {
        GameType.matchPairs => const [Color(0xFFFFB199), Color(0xFFFF7E5F)],
        GameType.multipleChoice =>
          const [Color(0xFFC7CEEA), Color(0xFFA1ABDC)],
        GameType.typing => const [Color(0xFFB5EAD7), Color(0xFF8FD9C0)],
        GameType.memoryFlip => const [Color(0xFFE2C2FF), Color(0xFFC18CF0)],
        GameType.speedRush => const [Color(0xFFFFD86F), Color(0xFFFFA45C)],
      };
}
