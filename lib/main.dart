import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'database_help.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Aquarium',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AquariumHomePage(title: 'Virtual Aquarium Home Page'),
    );
  }
}

class AquariumHomePage extends StatefulWidget {
  const AquariumHomePage({super.key, required this.title});

  final String title;

  @override
  State<AquariumHomePage> createState() => _AquariumHomePageState();
}

class _AquariumHomePageState extends State<AquariumHomePage>
    with SingleTickerProviderStateMixin {
  List<Fish> fishList = [];
  Timer? _timer;
  DatabaseHelper dbHelper = DatabaseHelper();
  int maxFish = 10;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _loadFishFromDatabase();

    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {
        for (var fish in fishList) {
          fish.updatePosition();
        }
      });
    });

    _controller.repeat();
  }

  Future<void> _loadFishFromDatabase() async {
    List<Fish> loadedFish = await dbHelper.getFishList();
    setState(() {
      fishList = loadedFish;
    });
  }

  void _addNewFish(Color color, double speed) async {
    if (fishList.length >= maxFish) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum of 10 fish reached')),
      );
      return;
    }
    Fish newFish = Fish(color: color, speed: speed);
    await dbHelper.insertFish(newFish);
    setState(() {
      fishList.add(newFish);
    });
  }

  void _deleteFish(int id) async {
    await dbHelper.deleteFish(id);
    setState(() {
      fishList.removeWhere((fish) => fish.id == id);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _openAddFishDialog() {
    Color? selectedColor;
    double selectedSpeed = 1.0; 

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Fish'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<Color>(
                    hint: const Text('Select Color'),
                    value: selectedColor,
                    items: [
                      DropdownMenuItem(
                        value: Colors.red,
                        child: const Text('Red'),
                      ),
                      DropdownMenuItem(
                        value: Colors.green,
                        child: const Text('Green'),
                      ),
                      DropdownMenuItem(
                        value: Colors.blue,
                        child: const Text('Blue'),
                      ),
                      DropdownMenuItem(
                        value: Colors.yellow,
                        child: const Text('Yellow'),
                      ),
                      DropdownMenuItem(
                        value: Colors.black,
                        child: const Text('Black'),
                      ),
                    ],
                    onChanged: (color) {
                      setState(() {
                        selectedColor = color;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  Slider(
                    value: selectedSpeed,
                    min: 0.5,
                    max: 5.0,
                    divisions: 9,
                    label: 'Speed: ${selectedSpeed.toStringAsFixed(1)}',
                    onChanged: (value) {
                      setState(() {
                        selectedSpeed = value; 
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (selectedColor != null) {
                      _addNewFish(selectedColor!, selectedSpeed);
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a color')),
                      );
                    }
                  },
                  child: const Text('Add'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openDeleteFishDialog() {
    int? selectedId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Delete Fish'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<int>(
                    hint: const Text('Select Fish ID'),
                    value: selectedId,
                    items: fishList.map((fish) {
                      return DropdownMenuItem(
                        value: fish.id,
                        child: Text('Fish ID: ${fish.id}'),
                      );
                    }).toList(),
                    onChanged: (id) {
                      setState(() {
                        selectedId = id;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (selectedId != null) {
                      _deleteFish(selectedId!);
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a fish ID')),
                      );
                    }
                  },
                  child: const Text('Delete'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.blue[200],
                border: Border.all(color: Colors.blue, width: 5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: fishList
                    .map((fish) => AnimatedPositioned(
                          duration: Duration(
                              milliseconds: (1000 / fish.speed).round()),
                          left: fish.x,
                          top: fish.y,
                          child: FishWidget(fish: fish),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _openAddFishDialog,
              child: const Text('Add Fish'),
            ),
            ElevatedButton(
              onPressed: _openDeleteFishDialog,
              child: const Text('Delete Fish'),
            ),
          ],
        ),
      ),
    );
  }
}

class Fish {
  int? id;
  double x;
  double y;
  double speed;
  Color color;
  double dx;
  double dy;
  final Random _random = Random();

  Fish({
    this.id,
    required this.color,
    required this.speed,
  })  : x = Random().nextDouble() * 270,
        y = Random().nextDouble() * 270,
        dx = Random().nextDouble() * 2 - 1,
        dy = Random().nextDouble() * 2 - 1;

  Map<String, dynamic> toMap() {
    return {
      'fish_id': id,
      'speed': speed,
      'color': color.value.toRadixString(16), 
    };
  }

  void updatePosition() {
    x += dx * speed;
    y += dy * speed;

    if (x <= 0 || x >= 270) {
      dx = -dx; 
    }
    if (y <= 0 || y >= 270) {
      dy = -dy;
    }
  }
}

class FishWidget extends StatelessWidget {
  final Fish fish;

  const FishWidget({Key? key, required this.fish}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fish.color,
      ),
      child: Center(
        child: Text(
          '${fish.id}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
