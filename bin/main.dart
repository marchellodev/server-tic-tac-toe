import 'package:socket_io/socket_io.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:async';
import 'package:random_string/random_string.dart';

import 'game.dart';

void main(List<String> arguments) {
  if (arguments[0] == 'server') {
    server();
  } else {
    client(arguments[1]);
  }
}

List<User> connections = [];

void server() {
  print('running server');

  var io = Server();

  io.on('connection', (client) {
    var id;
    do {
      id = randomAlphaNumeric(6);
    } while (
        connections.firstWhere((user) => user.id == id, orElse: () => null) !=
            null);

    var u = User(id, client);
    connections.add(u);

//    print('user was added');
//    print(connections);

//    client.emit('unique_id', u.id);

    client.on('findGame', (data) {
      u.finding = true;
    });

    client.on('setName', (data) {
      u.name = data;
//      print('name was set');
//      print(connections);
    });

    client.on('makeMove', (data) {
      if (!u.playing) {
        client.emit('error', 'not in a game!');
        return;
      } else if (u.game.game.getMove() != u.game_player) {
        client.emit('error', 'not your move!');
        return;
      }
      u.game.makeMove(Position(data[0], data[1]));
    });

    client.on('getPlayers', (data) {
      client.emit('getPlayers', connections.length);
    });

    client.on('getFindingPlayers', (data) {
      client.emit('getFindingPlayers',
          connections.where((user) => user.finding).length);
    });

    client.on('disconnect', (data) {
      connections.remove(connections.firstWhere((user) => user == u));

      print('user was removed');
      print(connections);
//      print('disconnect!!!!');
    });

//    client.on('message', (data) {
//      print('message from $auth');
//      if (auth == 'bob') {
//        connections['alice'].emit('message', 'bob says: $data');
//      } else {
//        connections['bob'].emit('message', 'alice says: $data');
//      }
//    });
  });
  io.listen(3000);
}

void matchMaking() async {
  //todo: matchmaking
  if (connections.isNotEmpty) {
    var looking = connections.where((user) => user.finding);
    if (looking.length >= 2) {
      var pointer = 0;
      while (pointer < connections.length - 1) {
        var u1 = connections[pointer];
        pointer++;
        var u2 = connections[pointer];

        var match = Match(u1, u2);

        u1.finding = false;
        u1.playing = true;
        u1.game = match;
        u1.game_player = Player.u1;
        u1.client.emit('gameFound', [1, u2.name]);

        u2.finding = false;
        u2.playing = true;
        u2.game = match;
        u2.game_player = Player.u2;
        u2.client.emit('gameFound', [2, u2.name]);

        pointer++;
      }
    }
  }

  Future.delayed(Duration(milliseconds: 500), () => matchMaking());
}

void client(String auth) async {
  print('running client');

  var socket = io.io('http://35.246.234.109:3000', <String, dynamic>{
    'transports': ['websocket'],
    'autoConnect': false
  });
  socket.connect();

  await socket.on('connect', (_) {
    print('connect');
    socket.emit('setName', auth);
    Future.delayed(Duration(seconds: 10), () => socket.disconnect());
//    socket.emit('auth', auth);
  });
//  socket.on('message', (data) => print('new message: ' + data));
//  socket.on('auth', (data) {
//    print('new auth message: ' + data);
//    stdout.write('> ');
//  });
//  socket.on('disconnect', (_) => print('disconnect'));
//  socket.on('fromServer', (_) => print(_));
//
//  stdin.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
//    stdout.write('> ');
//    socket.emit('message', line);
//  });
}

class User {
  String id;
  var client;
  String name = 'noone';
  bool finding = false;
  bool playing = false;
  Match game;
  Player game_player;

  User(this.id, this.client);

  @override
  String toString() {
    // TODO: implement toString
    return 'User<$id> $name | finding: $finding';
  }
}

class Match {
  Game game;
  User u1;
  User u2;
  bool active = true;
  int started;
  int last_move;

//todo: random assignment for u1 and u2
  Match(this.u1, this.u2) {
    game = Game();
    started = getTime();

    background();
  }

  void background() async {
    if (getTime() - last_move >= 20) {
      active = false;
      u1.playing = false;
      u1.client.emit(
          'matchExpired', game.getMove() == Player.u1 ? u1.name : u2.name);
      u2.playing = false;
      u2.client.emit(
          'matchExpired', game.getMove() == Player.u1 ? u1.name : u2.name);
      //todo: penalty
    }

    Future.delayed(Duration(seconds: 1), () => background());
  }

  void makeMove(Position position) {
    var u = game.getMove() == Player.u1 ? 1 : 2;
    u1.client.emit('move', [u, position.x, position.y]);
    u2.client.emit('move', [u, position.x, position.y]);
    game.makeMove(position);
    last_move = getTime();

    if (game.win == Cell.none) {
      active = false;
      u1.playing = false;
      u2.playing = false;
      u1.game = null;
      u2.game = null;
      u1.client.emit('gameEnd', 0);
      u2.client.emit('gameEnd', 0);
    } else if (game.win == Cell.u1 || game.win == Cell.u2) {
      active = false;
      var u = game.win == Cell.u1 ? 1 : 2;
      u1.playing = false;
      u2.playing = false;
      u1.game = null;
      u2.game = null;
      u1.client.emit('gameEnd', u);
      u2.client.emit('gameEnd', u);
    }
  }

  int getTime() => DateTime.now().millisecondsSinceEpoch ~/ 1000;
}
