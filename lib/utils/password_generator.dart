import 'dart:math';

class PasswordGenerator {
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _numbers = '0123456789';
  static const String _symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  static String generate({
    int length = 20,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSymbols = true,
  }) {
    String chars = '';

    if (includeLowercase) chars += _lowercase;
    if (includeUppercase) chars += _uppercase;
    if (includeNumbers) chars += _numbers;
    if (includeSymbols) chars += _symbols;

    if (chars.isEmpty) {
      throw ArgumentError('至少需要选择一种字符类型');
    }

    final random = Random.secure();
    final password = StringBuffer();

    // 确保至少包含每种选中的字符类型
    if (includeLowercase && length > 0) {
      password.write(_lowercase[random.nextInt(_lowercase.length)]);
      length--;
    }
    if (includeUppercase && length > 0) {
      password.write(_uppercase[random.nextInt(_uppercase.length)]);
      length--;
    }
    if (includeNumbers && length > 0) {
      password.write(_numbers[random.nextInt(_numbers.length)]);
      length--;
    }
    if (includeSymbols && length > 0) {
      password.write(_symbols[random.nextInt(_symbols.length)]);
      length--;
    }

    // 填充剩余长度
    for (int i = 0; i < length; i++) {
      password.write(chars[random.nextInt(chars.length)]);
    }

    // 打乱字符顺序
    final passwordList = password.toString().split('')..shuffle(random);
    return passwordList.join();
  }

  static String generateMemorable({
    int wordCount = 4,
    String separator = '-',
  }) {
    final words = [
      'apple',
      'banana',
      'cherry',
      'dolphin',
      'elephant',
      'forest',
      'garden',
      'harbor',
      'island',
      'jungle',
      'kitten',
      'lighthouse',
      'mountain',
      'nature',
      'ocean',
      'planet',
      'quasar',
      'rainbow',
      'sunset',
      'tiger',
      'universe',
      'valley',
      'waterfall',
      'xylophone',
      'yacht',
      'zebra',
      'adventure',
      'beautiful',
      'crystal',
      'diamond',
      'energy',
      'fantasy',
      'galaxy',
      'harmony',
      'inspire',
      'journey',
      'kingdom',
      'liberty',
      'miracle',
      'natural',
      'oracle',
      'paradise',
      'quantum',
      'radiant',
      'serenity',
      'tranquil',
      'ultimate',
      'vibrant',
      'wonder',
      'xenial',
      'youthful',
      'zenith'
    ];

    final random = Random.secure();
    final selectedWords = <String>[];

    for (int i = 0; i < wordCount; i++) {
      selectedWords.add(words[random.nextInt(words.length)]);
    }

    // 随机添加数字
    if (random.nextBool()) {
      final index = random.nextInt(selectedWords.length);
      selectedWords[index] += random.nextInt(100).toString();
    }

    return selectedWords.join(separator);
  }
}
