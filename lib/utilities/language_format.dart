class LanguageFormat {
  // Pre-computed map for single Greek letters (lowercase).
  static const _singleCharMap = {
    'α': 'a',
    'β': 'v',
    'γ': 'g',
    'δ': 'd',
    'ε': 'e',
    'ζ': 'z',
    'η': 'i',
    'θ': 'th',
    'ι': 'i',
    'κ': 'k',
    'λ': 'l',
    'μ': 'm',
    'ν': 'n',
    'ξ': 'x',
    'ο': 'o',
    'π': 'p',
    'ρ': 'r',
    'σ': 's',
    'ς': 's',  // final sigma maps to 's'
    'τ': 't',
    'υ': 'y',  // 'y' is common Greeklish, though ELOT uses 'i' sometimes.
    'φ': 'f',
    'χ': 'ch', // 'ch' for chi (ELOT uses 'ch')
    'ψ': 'ps',
    'ω': 'o',
  };

  /// Converts a Greek string to Greeklish (Latin script).
  /// This is a fast, local, best-effort transliteration.
  static String toGreeklish(String input) {
    if (input.isEmpty) return input;

    // Make sure to remove tonous before processing the input
    input = removeTonous(input);

    // We use a list to build the result efficiently.
    final buffer = StringBuffer();
    final chars = input.toLowerCase().split(''); // Work with lowercase for matching.

    // We'll iterate manually to handle digraphs (two-letter combos) first.
    int i = 0;
    while (i < chars.length) {
      // Check if we have at least two characters left to form a digraph.
      if (i + 1 < chars.length) {
        final two = chars[i] + chars[i + 1];

        // Handle Greek digraphs (common ones).
        // The order here matters: we map the most specific ones first.
        switch (two) {
          case 'μπ':
            buffer.write('mp');
            i += 2;
            continue;
          case 'ντ':
            buffer.write('nt');
            i += 2;
            continue;
          case 'γκ':
            buffer.write('gk');
            i += 2;
            continue;
          case 'γγ':
            buffer.write('ng');
            i += 2;
            continue;
          case 'τζ':
            buffer.write('tz');
            i += 2;
            continue;
          case 'τσ':
            buffer.write('ts');
            i += 2;
            continue;
          case 'ου':
            buffer.write('ou');
            i += 2;
            continue;
          case 'αυ':
          // Simple approximation: "av" is fine (ELOT says av/af).
            buffer.write('av');
            i += 2;
            continue;
          case 'ευ':
            buffer.write('ev');
            i += 2;
            continue;
        }
      }

      // If it wasn't a digraph, map the single character.
      final char = chars[i];
      final mapped = _singleCharMap[char];
      if (mapped != null) {
        buffer.write(mapped);
      } else {
        // If it's already a Latin character, punctuation, or space, keep it.
        buffer.write(char);
      }
      i++;
    }

    final result = buffer.toString();

    // Capitalize the first letter if the original was capitalized.
    // (We need to check the original first character to preserve case.)
    if (input.isNotEmpty && input[0] == input[0].toUpperCase()) {
      return result[0].toUpperCase() + result.substring(1);
    }
    return result;
  }

  /// Removes tonous from greek text
  static String removeTonous(String input) {
    const withAccents = 'άέήίϊΐόύϋΰώ';
    const withoutAccents = 'αεηιιιουυυω';

    for (int i = 0; i < withAccents.length; i++) {
      input = input.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return input;
  }

  /// Use this function for searching (removes tonous, makes lowercase)
  static String clearText(String input) {
    return removeTonous(input.toLowerCase());
  }
}