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
  /// Handles digraphs (μπ, ντ, etc.) and the αυ/ευ voicing rule.
  static String toGreeklish(String input) {
    if (input.isEmpty) return input;

    // Make sure to remove tonous before processing the input
    input = removeTonous(input);

    final buffer = StringBuffer();
    final chars = input.toLowerCase().split('');
    int i = 0;

    // Helper to check if a letter is a voiceless consonant.
    bool isVoiceless(String c) => 'κπτσφχθξψ'.contains(c);

    while (i < chars.length) {
      // Check for two-letter combinations (digraphs) that should be handled first.
      if (i + 1 < chars.length) {
        final two = chars[i] + chars[i + 1];

        // Special handling for αυ and ευ with context.
        if (two == 'αυ' || two == 'ευ') {
          // Look ahead to the next character after the digraph.
          final next = (i + 2 < chars.length) ? chars[i + 2] : null;
          // Determine if the following consonant is voiceless.
          final isVoiced = (next != null && !isVoiceless(next)) || next == null || 'αειου'.contains(next);
          // Choose v or f.
          final v = isVoiced ? 'v' : 'f';
          final prefix = (two == 'αυ') ? 'a' : 'e';
          buffer.write('$prefix$v');
          i += 2;
          continue;
        }

        // Other digraphs (unchanged).
        switch (two) {
          case 'μπ':
          // At the start of a word, it's often just 'b', but we keep 'mp' for simplicity.
          // (You can add a special case for word start if desired.)
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
        }
      }

      // Single character mapping.
      final char = chars[i];
      final mapped = _singleCharMap[char];
      if (mapped != null) {
        buffer.write(mapped);
      } else {
        buffer.write(char); // Keep non-Greek characters.
      }
      i++;
    }

    String result = buffer.toString();
    // Preserve case of the first letter.
    if (input.isNotEmpty && input[0] == input[0].toUpperCase()) {
      result = result[0].toUpperCase() + result.substring(1);
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