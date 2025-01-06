enum IndentType {
  spaces2(2),
  spaces4(4),
  tab,
  none;

  final int? spaces;

  const IndentType([this.spaces]);
}
