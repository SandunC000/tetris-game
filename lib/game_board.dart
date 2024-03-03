import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tetris/piece.dart';
import 'package:tetris/pixel.dart';
import 'package:tetris/values.dart';

List<List<Tetromino?>> gameBoard = List.generate(
  colLength,
  (i) => List.generate(
    rowLength,
    (j) => null,
  ),
);

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  Piece currentPiece = Piece(type: Tetromino.L);
  int currentScore = 0;
  late bool gameOver;

  @override
  void initState() {
    super.initState();
    gameOver = false;
    startGame();
  }

  void startGame() {
    currentPiece.initializePiece();
    Duration frameRate = const Duration(milliseconds: 400);
    gameLoop(frameRate);
  }

  void gameLoop(Duration frameRate) {
    Timer.periodic(frameRate, (timer) {
      setState(() {
        clearLines();
        checkLanding();

        if (gameOver == true) {
          timer.cancel();
          showGameOverDialog();
        }
        currentPiece.movePiece((Direction.down));
      });
    });
  }

  bool checkCollision(Direction direction) {
    for (int i = 0; i < currentPiece.position.length; i++) {
      int row = (currentPiece.position[i] / rowLength).floor();
      int col = (currentPiece.position[i] % rowLength);

      if (direction == Direction.down) {
        row++;
      } else if (direction == Direction.right) {
        col++;
      } else if (direction == Direction.left) {
        col--;
      }

      if (col < 0 || col >= rowLength || row >= colLength) {
        return true;
      }

      if (row >= 0 && gameBoard[row][col] != null) {
        return true;
      }
    }
    return false;
  }

  void checkLanding() {
    if (checkCollision(Direction.down)) {
      for (int i = 0; i < currentPiece.position.length; i++) {
        int row = (currentPiece.position[i] / rowLength).floor();
        int col = currentPiece.position[i] % rowLength;

        if (row >= 0 && col >= 0) {
          gameBoard[row][col] = currentPiece.type;
        }
      }

      createNewPiece();
    }
  }

  void createNewPiece() {
    Random rand = Random();
    Tetromino randomType =
        Tetromino.values[rand.nextInt(Tetromino.values.length)];
    currentPiece = Piece(type: randomType);
    currentPiece.initializePiece();

    if (isGameOver()) {
      gameOver = true;
    }
  }

  void moveLeft() {
    if (!checkCollision(Direction.left)) {
      setState(() {
        currentPiece.movePiece(Direction.left);
      });
    }
  }

  void moveRight() {
    if (!checkCollision(Direction.right)) {
      setState(() {
        currentPiece.movePiece(Direction.right);
      });
    }
  }

  void rotatePiece() {
    setState(() {
      currentPiece.rotatePiece();
    });
  }

  void clearLines() {
    for (int row = colLength - 1; row >= 0; row--) {
      bool rowIsFull = true;
      for (int col = 0; col < rowLength; col++) {
        if (gameBoard[row][col] == null) {
          rowIsFull = false;
          break;
        }
      }
      if (rowIsFull) {
        currentScore +=100;
        for (int r = row; r > 0; r--) {
          gameBoard[r] = List.from(gameBoard[r - 1]);
        }

        gameBoard[0] = List.generate(row, (index) => null);
      }
    }
  }

  bool isGameOver() {
    for (int col = 0; col < rowLength; col++) {
      if (gameBoard[0][col] != null) {
        return true;
      }
    }
    return false;
  }

  void showGameOverDialog() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Game Over'),
              content: Text("Your score is: $currentScore"),
              actions: [
                TextButton(
                  onPressed: () {
                    resetGame();
                    Navigator.pop(context);
                  },
                  child: const Text('Play Again'),
                )
              ],
            ));
  }

  void resetGame() {
    gameBoard = List.generate(
        colLength,
        (i) => List.generate(
              rowLength,
              (j) => null,
            ));

    gameOver = false;
    currentScore = 0;
    createNewPiece();
    startGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
                itemCount: rowLength * colLength,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: rowLength),
                itemBuilder: (context, index) {
                  int row = (index / rowLength).floor();
                  int col = index % rowLength;

                  //current piece
                  if (currentPiece.position.contains(index)) {
                    return Pixel(
                      color: currentPiece.color,
                    );
                  }

                  //landed piece
                  else if (gameBoard[row][col] != null) {
                    final Tetromino? tetrominoType = gameBoard[row][col];
                    return Pixel(color: tetrominoColors[tetrominoType]);
                  }

                  //blank pixel
                  else {
                    return Pixel(
                      color: Colors.grey[900],
                    );
                  }
                }),
          ),
          Text(
            'Score : $currentScore',
            style: const TextStyle(color: Colors.white, fontSize: 28),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 50.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: moveLeft,
                  icon: const Icon(Icons.arrow_back_ios),
                  color: Colors.white,
                ),
                IconButton(
                  onPressed: rotatePiece,
                  icon: const Icon(Icons.rotate_right),
                  color: Colors.white,
                ),
                IconButton(
                  onPressed: moveRight,
                  icon: const Icon(Icons.arrow_forward_ios),
                  color: Colors.white,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
