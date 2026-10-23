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
  /// Preserves the case of each original letter (not just the first one).
  static String toGreeklish(String input) {
    if (input.isEmpty) return input;

    // Make sure to remove tonous before processing the input
    input = removeTonous(input);

    final buffer = StringBuffer();
    final chars = input.split('');            // original case, for output
    final lower = input.toLowerCase().split(''); // lowercase, for lookups only
    final length = chars.length;
    int i = 0;

    bool hasCase(String c) => c.toLowerCase() != c.toUpperCase();
    bool isUpper(String c) => hasCase(c) && c == c.toUpperCase();

    // Applies the case of a single source letter to a single mapped letter.
    String applyCase(String source, String mappedChar) =>
        isUpper(source) ? mappedChar.toUpperCase() : mappedChar;

    // Helper to check if a (lowercase) letter is a voiceless consonant.
    bool isVoiceless(String c) => 'κπτσφχθξψ'.contains(c);

    while (i < length) {
      final cOrig = chars[i];
      final cLower = lower[i];

      // Check for two-letter combinations (digraphs) first.
      if (i + 1 < length) {
        final c0 = chars[i];
        final c1 = chars[i + 1];
        final twoLower = cLower + lower[i + 1];

        // Special handling for αυ and ευ with context.
        if (twoLower == 'αυ' || twoLower == 'ευ') {
          final nextLower = (i + 2 < length) ? lower[i + 2] : null;
          final isVoiced = (nextLower != null && !isVoiceless(nextLower)) ||
              nextLower == null ||
              'αειου'.contains(nextLower);
          final voiceLetter = isVoiced ? 'v' : 'f';
          final prefixLetter = (twoLower == 'αυ') ? 'a' : 'e';
          buffer.write(applyCase(c0, prefixLetter));
          buffer.write(applyCase(c1, voiceLetter));
          i += 2;
          continue;
        }

        // Other digraphs — case of each output letter follows its own source letter,
        // matching real Greek convention (e.g. "Ντίνος" -> "Ntinos", "ΝΤΙΝΟΣ" -> "NTINOS").
        String? mappedTwo;
        switch (twoLower) {
          case 'μπ':
            mappedTwo = 'mp';
            break;
          case 'ντ':
            mappedTwo = 'nt';
            break;
          case 'γκ':
            mappedTwo = 'gk';
            break;
          case 'γγ':
            mappedTwo = 'ng';
            break;
          case 'τζ':
            mappedTwo = 'tz';
            break;
          case 'τσ':
            mappedTwo = 'ts';
            break;
          case 'ου':
            mappedTwo = 'ou';
            break;
        }
        if (mappedTwo != null) {
          buffer.write(applyCase(c0, mappedTwo[0]));
          buffer.write(applyCase(c1, mappedTwo[1]));
          i += 2;
          continue;
        }
      }

      // Single character mapping.
      final mapped = _singleCharMap[cLower];
      if (mapped == null) {
        buffer.write(cOrig); // Keep non-Greek characters, already in original case.
      } else if (mapped.length == 1) {
        buffer.write(applyCase(cOrig, mapped));
      } else {
        // θ/χ/ψ: one Greek letter -> two Latin letters, so there's no second
        // source letter to borrow case from. Decide "Th" vs "TH" by looking at
        // the neighboring letters: if we're clearly inside an ALL-CAPS run,
        // uppercase both letters; otherwise treat it as a lone capital (title
        // case) and only capitalize the first one.
        if (!isUpper(cOrig)) {
          buffer.write(mapped);
        } else {
          final nextOrig = (i + 1 < length) ? chars[i + 1] : null;
          final prevOrig = (i - 1 >= 0) ? chars[i - 1] : null;
          final bool fullyUpper = (nextOrig != null && hasCase(nextOrig))
              ? isUpper(nextOrig)
              : (prevOrig != null && isUpper(prevOrig));
          buffer.write(fullyUpper
              ? mapped.toUpperCase()
              : mapped[0].toUpperCase() + mapped.substring(1));
        }
      }
      i++;
    }

    return buffer.toString();
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