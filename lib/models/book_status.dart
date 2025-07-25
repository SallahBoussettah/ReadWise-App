enum BookStatus {
  want('want'),
  reading('reading'),
  finished('finished');

  const BookStatus(this.value);
  
  final String value;

  static BookStatus fromString(String value) {
    switch (value) {
      case 'want':
        return BookStatus.want;
      case 'reading':
        return BookStatus.reading;
      case 'finished':
        return BookStatus.finished;
      default:
        throw ArgumentError('Invalid BookStatus value: $value');
    }
  }

  @override
  String toString() => value;
}