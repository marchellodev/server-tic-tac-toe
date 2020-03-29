class Game {
  Player _turn = Player.u1;
  Cell win;

  final List<List<Cell>> _map = [
    [Cell.none, Cell.none, Cell.none],
    [Cell.none, Cell.none, Cell.none],
    [Cell.none, Cell.none, Cell.none],
  ];

  Game();

  bool canMove(Player player) => player == _turn;

  Player getMove() => _turn;

  Cell getCell(Position position) => _map[position.y][position.x];

  List<List<Cell>> getMap() => _map;

  bool makeMove(Position position) {
    if (getCell(position) != Cell.none) return false;

    _map[position.y][position.x] = _turn == Player.u1 ? Cell.u1 : Cell.u2;
    _turn = _turn == Player.u1 ? Player.u2 : Player.u1;
    _update();

    return true;
  }

  // if true then can continue playing
  void _update() {
    if (_win() != Cell.none) {
      win = _win();
    } else if (_noChance()) {
      win = Cell.none;
    }
  }

  Cell _win() {
    for (var i = 0; i < 3; i++) {
      if (_map[i][0] == _map[i][1] &&
          _map[i][0] == _map[i][2] &&
          _map[i][0] != Cell.none) return _map[i][0];

      if (_map[0][i] == _map[1][i] &&
          _map[0][i] == _map[2][i] &&
          _map[0][i] != Cell.none) return _map[0][i];
    }

    if (_map[0][0] == _map[1][1] &&
        _map[0][0] == _map[2][2] &&
        _map[0][0] != Cell.none) return _map[0][0];

    if (_map[0][2] == _map[1][1] &&
        _map[0][2] == _map[2][0] &&
        _map[0][2] != Cell.none) return _map[0][2];

    return Cell.none;
  }

  bool _noChance() {
    for (var i = 0; i < 3; i++) {
      //todo: idea: noChanceForThree method
      var case1 = _noChanceForTwo(_map[0][0], _map[0][1]) ||
          _noChanceForTwo(_map[0][1], _map[0][2]) ||
          _noChanceForTwo(_map[0][0], _map[0][2]);

      var case2 = _noChanceForTwo(_map[0][0], _map[1][0]) ||
          _noChanceForTwo(_map[1][0], _map[2][0]) ||
          _noChanceForTwo(_map[0][0], _map[2][0]);

      if (!case1 || !case2) return false;
    }

    var case1 = _noChanceForTwo(_map[0][0], _map[1][1]) ||
        _noChanceForTwo(_map[1][1], _map[2][2]) ||
        _noChanceForTwo(_map[0][0], _map[2][2]);

    var case2 = _noChanceForTwo(_map[0][2], _map[1][1]) ||
        _noChanceForTwo(_map[1][1], _map[2][0]) ||
        _noChanceForTwo(_map[0][2], _map[2][2]);

    if (!case1 || !case2) return false;

    return true;
  }

  bool _noChanceForTwo(Cell cell1, Cell cell2) =>
      (cell1 != Cell.none && cell2 != Cell.none && cell1 != cell2);
}

enum Cell {
  none,
  u1,
  u2,
}

enum Player {
  u1,
  u2,
}

class Position {
  final int x;
  final int y;

  Position(this.x, this.y);
}
