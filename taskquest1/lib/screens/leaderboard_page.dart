

import 'package:flutter/material.dart';
import 'components/const/colors.dart';


class LeaderboardPage extends StatelessWidget {
  final List<Map<String, dynamic>> leaderboardData = [
    {'name': '🥇 Camilla', 'score': 42, 'avatar': 'assets/avatars/dolphin.png'},
    {'name': '🥈 Ammar', 'score': 38, 'avatar': 'assets/avatars/cow.png'},
    {'name': '🥉 Kareema', 'score': 36, 'avatar': 'assets/avatars/Cat.png'},
    {'name': 'Snigdha', 'score': 30, 'avatar': 'assets/avatars/dolphin.png'},
    {'name': 'Leo', 'score': 28, 'avatar': 'assets/avatars/panda.png'},
    {'name': 'Sara', 'score': 25, 'avatar': 'assets/avatars/zebra.png'},
    {'name': 'Nina', 'score': 22, 'avatar': 'assets/avatars/turtle.png'},
    {'name': 'David', 'score': 20, 'avatar': 'assets/avatars/cow.png'},
    {'name': 'Ali', 'score': 18, 'avatar': 'assets/avatars/zebra.png'},
    {'name': 'Zoe', 'score': 16, 'avatar': 'assets/avatars/turtle.png'},
    {'name': 'Liam', 'score': 14, 'avatar': 'assets/avatars/dolphin.png'},
    {'name': 'Emma', 'score': 12, 'avatar': 'assets/avatars/turtle.png'},
    {'name': 'Noah', 'score': 10, 'avatar': 'assets/avatars/zebra.png'},
    {'name': 'Olivia', 'score': 8, 'avatar': 'assets/avatars/turtle.png'},
    {'name': 'Ava', 'score': 6, 'avatar': 'assets/avatars/panda.png'},
    {'name': 'Ethan', 'score': 4, 'avatar': 'assets/avatars/turtle.png'},
    {'name': 'Mia', 'score': 2, 'avatar': 'assets/avatars/Cat.png'},
    {'name': 'Logan', 'score': 0, 'avatar': 'assets/avatars/giraffe.png'},
    {'name': 'Sophia', 'score': 0, 'avatar': 'assets/avatars/zebra.png'},
    {'name': 'Lucas', 'score': 0, 'avatar': 'assets/avatars/turtle.png'},
  ];


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: leaderboardData.length,
        itemBuilder: (context, index) {
          final user = leaderboardData[index];
          final bool isFirstPlace = index == 0;
          final bool isSecondPlace = index == 1;
          final bool isThirdPlace = index == 2;


          Color? cardColor;
          if (isFirstPlace) cardColor = Colors.amber[200];
          else if (isSecondPlace) cardColor = Colors.grey[300];
          else if (isThirdPlace) cardColor = Colors.brown[200];


          return Card(
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: isFirstPlace ? 28 : 24,
                    backgroundImage: AssetImage(user['avatar']),
                  ),
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.black87,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                user['name'],
                style: TextStyle(
                  fontWeight: isFirstPlace ? FontWeight.bold : FontWeight.normal,
                  fontSize: isFirstPlace ? 20 : 16,
                ),
              ),
              trailing: Text(
                '${user['score']} pts',
                style: TextStyle(
                  fontWeight: isFirstPlace ? FontWeight.bold : FontWeight.normal,
                  fontSize: isFirstPlace ? 18 : 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

