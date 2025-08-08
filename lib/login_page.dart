import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import 'signup_page.dart';
import 'services/fcm.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart.gitignore';

// ignore: must_be_immutable
class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {

  bool _isObscure = true;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  FirebaseService firebaseService = FirebaseService();
  PushNotificationService pushNotificationService = PushNotificationService();

  void _showForgotPasswordDialog(BuildContext context) {
    TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Center(
          child: const Text(
            "Quên mật khẩu",
            style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold, 
                        color: Colors.green, 
                        
                      ),
            ),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: TextField(
            cursorColor: Colors.green[300],
            controller: emailController,
            decoration: const InputDecoration(
              hintText: 'Email',
              hintStyle: TextStyle(color: Colors.black, fontSize: 14),
              filled: true,
              fillColor: Color(0xFFF5FCF9),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(50)),
              ),
            ),
            style: TextStyle(color: Colors.black, fontSize: 14), 
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: ButtonStyle(
              overlayColor: MaterialStateProperty.all<Color>(Colors.green.withOpacity(0.2)),
              backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                (states) {
                  if (states.contains(MaterialState.hovered)) {
                    return Colors.green.withOpacity(0.2); 
                  }
                  return Colors.transparent; 
                },
              ),
              // shape: MaterialStateProperty.all(
              //   RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Bo góc nhẹ
              // ),
            ),
            child: const Text(
              "Hủy",
              style: TextStyle(color: Colors.black),
              
              ),
          ),
          ElevatedButton(
            onPressed: () async {
              String email = emailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Nhập email của bạn")),
                );
                return;
              }

              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                Navigator.pop(context); // Đóng popup sau khi gửi yêu cầu
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Email lấy lại mật khẩu đã được gửi!")),
                );
              } on FirebaseAuthException catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.message ?? "Lỗi gửi email")),
                );
              }
            },
            style: ButtonStyle(
              overlayColor: MaterialStateProperty.all<Color>(Colors.green.withOpacity(0.2)),
              backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                (states) {
                  if (states.contains(MaterialState.hovered)) {
                    return Colors.green.withOpacity(0.2); // Màu nền khi hover vào
                  }
                  return const Color(0xFFF5FCF9); // Màu nền mặc định
                },
              ),
              shadowColor: MaterialStateProperty.all(Colors.transparent),
              
              // shape: MaterialStateProperty.all(
              //   RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Bo góc nhẹ
              // ),
            ),
            child: const Text(
              "Quên mật khẩu",
              style: TextStyle(color: Colors.black),
              ),
          ),
        ],
      ),
    );
  }
                  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  SizedBox(height: constraints.maxHeight * 0.1),
                  Image.asset(
                    'assets/logo_removebg2.png',
                    height: 60,
                    // width: 100, 
                  ),
                  SizedBox(height: constraints.maxHeight * 0.05),
                  Text(
                    "Đăng nhập",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold, 
                      color: Colors.black, 
                    ),
                  ),
                  SizedBox(height: constraints.maxHeight * 0.05),
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85, 
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min, 
                          children: [
                            TextFormField(
                              cursorColor: Colors.green[300],
                              controller: _emailController,
                              decoration: const InputDecoration(
                                hintText: 'Email',
                                filled: true,
                                fillColor: Color(0xFFF5FCF9),
                                contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.all(Radius.circular(50)),
                                ),
                              ),
                              style: TextStyle(color: Colors.black, fontSize: 14),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Nhập email của bạn';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16.0),
                            TextFormField(
                              cursorColor: Colors.green[300],
                              controller: _passwordController,
                              obscureText: _isObscure, // Sử dụng biến trạng thái
                              decoration: InputDecoration(
                                hintText: 'Mật khẩu',
                                filled: true,
                                fillColor: Color(0xFFF5FCF9),
                                contentPadding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.all(Radius.circular(50)),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isObscure ? Icons.visibility_off : Icons.visibility, 
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isObscure = !_isObscure; // Thay đổi trạng thái hiển thị mật khẩu
                                    });
                                  },
                                ),
                              ),
                              style: TextStyle(color: Colors.black, fontSize: 14),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Nhập mật khẩu của bạn';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16.0),

                            // Sign In Button
                            ElevatedButton(
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  try {
                                    UserCredential userCredential = await FirebaseAuth.instance
                                        .signInWithEmailAndPassword(
                                      email: _emailController.text.trim(),
                                      password: _passwordController.text.trim(),
                                    );

                                    String? token = await FirebaseMessaging.instance.getToken();
                                    pushNotificationService.saveTokenToFirestore(token);
                                    
                                    firebaseService.listenForChanges(); 

                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => HomePage(uid: userCredential.user!.uid),
                                      ),
                                    );
                                  } on FirebaseAuthException catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.message ?? "Lỗi")),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                elevation: 2,
                                backgroundColor: const Color(0xFF00BF6D),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 48),
                                shape: const StadiumBorder(),
                              ),
                              child: const Text("Đăng Nhập"),
                            ),
                            const SizedBox(height: 16.0),

                            // Forgot Password
                            TextButton(
                              onPressed: () => _showForgotPasswordDialog(context),
                              style: ButtonStyle(
                                overlayColor: MaterialStateProperty.all<Color>(Colors.green.withOpacity(0.2)),
                              ),
                              child: Text(
                                'Quên Mật Khẩu?',
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                      fontSize: 13, 
                                      color: Colors.grey[700], 
                                    ),
                              ),
                            ),

                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => SignUpScreen()),
                                );
                              },
                              style: ButtonStyle(
                                overlayColor: MaterialStateProperty.all<Color>(Colors.green.withOpacity(0.2)), // Màu nền khi bấm vào
                              ),
                              child: Text.rich(
                                const TextSpan(
                                  text: "Chưa có tài khoản? ",
                                  style: TextStyle(fontSize: 13),
                                  children: [
                                    TextSpan(
                                      text: "Tạo tài khoản",
                                      style: TextStyle(color: Color(0xFF00BF6D)),
                                    ),
                                  ],
                                ),
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .color!
                                          .withOpacity(0.64),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )

                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
