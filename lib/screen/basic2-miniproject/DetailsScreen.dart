import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {

    // 순서2, 로그인 화면에서, 전달한 데이터를 받기
    final args = ModalRoute.of(context)!.settings.arguments as Map<String,dynamic>;

    return Scaffold(
      appBar: AppBar(title: const Text('상세 화면')),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              // height: 150,
              padding: const EdgeInsets.all(30.0),
              color: Colors.blue,
              child: Center(
                child: Column(
                  children: [
                    Text(
                        args['title'],
                      style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold
                      ),
                    ),
                    Text(
                      '임시 ID : ${args['id']} 번 데이터 정보 받기 '
                    ),
                    Text(
                        '임시 email : ${args['email']} '
                    ),
                    Text(
                        '임시 password : ${args['password']} '
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: List.generate(
                  20,
                      (index) => ListTile(
                    leading: const FlutterLogo(),
                    title: Text('항목 $index'),
                    subtitle: const Text('상세 설명'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
