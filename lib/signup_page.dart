import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login_page.dart';


class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool showPassword = true; // Điều khiển hiển thị mật khẩu

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                SizedBox(height: constraints.maxHeight * 0.03),
                Image.asset(
                    'assets/logo_removebg2.png',
                    height: 60,
                    // width: 100, 
                  ),
                SizedBox(height: constraints.maxHeight * 0.01),
                Text(
                  "Đăng kí",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold, 
                      color: Colors.black, 
                    ),
                ),
                SizedBox(height: 10,),
                // SizedBox(height: constraints.maxHeight * 0.000),
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    // padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Name
                          TextFormField(
                            cursorColor: Colors.green[300],
                            controller: nameController,
                            decoration: const InputDecoration(
                              hintText: 'Họ tên',
                              filled: true,
                              fillColor: Color(0xFFF5FCF9),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 24.0, vertical: 16.0),
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.all(Radius.circular(50)),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Nhập tên của bạn';
                              }
                              return null;
                            },
                            // style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 10.0),
                          // Phone
                          TextFormField(
                            cursorColor: Colors.green[300],
                            controller: phoneController,
                            decoration: const InputDecoration(
                              hintText: 'Số điện thoại',
                              filled: true,
                              fillColor: Color(0xFFF5FCF9),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 24.0, vertical: 16.0),
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.all(Radius.circular(50)),
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Nhập số điện thoại của bạn';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10.0),
                          // Email
                          TextFormField(
                            cursorColor: Colors.green[300],
                            controller: emailController,
                            decoration: const InputDecoration(
                              hintText: 'Email',
                              filled: true,
                              fillColor: Color(0xFFF5FCF9),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 24.0, vertical: 16.0),
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.all(Radius.circular(50)),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Nhập email của bạn';
                              } else if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                                return 'Email không hợp lệ';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10.0),
                          // Password
                          TextFormField(
                            cursorColor: Colors.green[300],
                            controller: passwordController,
                            decoration: InputDecoration(
                              hintText: 'Mật khẩu',
                              filled: true,
                              fillColor: const Color(0xFFF5FCF9),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24.0, vertical: 16.0),
                              border: const OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.all(Radius.circular(50)),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  showPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                      color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    showPassword = !showPassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: showPassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Nhập mật khẩu của bạn';
                              } else if (value.length < 8) {
                                return 'Mật khẩu ít nhất 8 kí tự';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10.0),
                          // Confirm Password
                          TextFormField(
                            cursorColor: Colors.green[300],
                            controller: confirmPasswordController,
                            decoration: InputDecoration(
                              hintText: 'Xác nhận mật khẩu',
                              filled: true,
                              fillColor: const Color(0xFFF5FCF9),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24.0, vertical: 16.0),
                              border: const OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.all(Radius.circular(50)),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  showPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                      color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    showPassword = !showPassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: showPassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Xác nhận mật khẩu';
                              } else if (value != passwordController.text) {
                                return 'Mật khẩu không khớp';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10.0),
                          // Sign Up Button
                          ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                String name = nameController.text;
                                String phone = phoneController.text;
                                String email = emailController.text;
                                String password = passwordController.text;
                    
                                try {
                                  // Đăng ký người dùng mới
                                  UserCredential userCredential = await FirebaseAuth.instance
                                      .createUserWithEmailAndPassword(email: email, password: password);
                    
                                  // Lấy UID của người dùng sau khi đăng ký thành công
                                  String uid = userCredential.user!.uid;
                                  print("User UID: $uid");
                    
                                  // Tạo một batch để lưu dữ liệu đồng thời vào nhiều collection
                                  WriteBatch batch = FirebaseFirestore.instance.batch();
                    
                                  // Lưu thông tin vào collection 'khach hang'
                                  DocumentReference khachHangRef = FirebaseFirestore.instance.collection('khach hang').doc(uid);
                                  batch.set(khachHangRef, {
                                    'uid': uid,
                                    'name': name,
                                    'email': email,
                                    'phone': phone,
                                    'createdAt': Timestamp.now(),
                                    'address': '',
                                  });
                    
                                  // Lưu thông tin vào collection 'cam bien'
                                  DocumentReference camBienRef = FirebaseFirestore.instance.collection('cam bien').doc(uid);
                                  batch.set(camBienRef, {
                                    'uid': uid,
                                  });
                    
                                  // Lưu thông tin vào collection 'lich su'
                                  DocumentReference lichSuRef = FirebaseFirestore.instance.collection('lich su').doc(uid);
                                  batch.set(lichSuRef, {
                                    'uid': uid,
                                  //   'history': [],
                                  //   'createdAt': Timestamp.now(),
                                  });
                    
                                  // Lưu thông tin vào collection 'thong bao'
                                  DocumentReference thongBaoRef = FirebaseFirestore.instance.collection('thong bao').doc(uid);
                                  batch.set(thongBaoRef, {
                                    'uid': uid,
                                  //   'notifications': [],
                                  //   'createdAt': Timestamp.now(),
                                  });
                    
                                  // Lưu thông tin vào collection 'nhat ky'
                                  DocumentReference nhatKyRef = FirebaseFirestore.instance.collection('nhat ky').doc(uid);
                                  batch.set(nhatKyRef, {
                                    'uid': uid,
                                  //   'logs': [],
                                  //   'createdAt': Timestamp.now(),
                                  });

                                  DocumentReference cayTrongRef = FirebaseFirestore.instance.collection('cay_trong').doc(uid);
                                  batch.set(cayTrongRef, {
                                    'uid': uid,
                                  //   'logs': [],
                                  //   'createdAt': Timestamp.now(),
                                  });
                    
                                  // Lưu đồng thời vào Firestore
                                  await batch.commit();
                    
                                  // Lưu vào Realtime Database tại `sensorData`
                                  DatabaseReference sensorDataRef = FirebaseDatabase.instance.ref('sensorData/$uid');
                                  await sensorDataRef.set({'uid': uid});

                                  DatabaseReference controlSensorDataRef = FirebaseDatabase.instance.ref('controlData/$uid');
                                  await controlSensorDataRef.set({'uid': uid});
                    
                                  // Hiển thị thông báo đăng ký thành công
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Tạo tài khoản thành công!')),
                                  );
                    
                                  // Chuyển hướng người dùng đến trang đăng nhập
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => SignInScreen()),
                                  );
                                } on FirebaseAuthException catch (e) {
                                  String errorMessage;
                                  if (e.code == 'weak-password') {
                                    errorMessage = 'The password is too weak.';
                                  } else if (e.code == 'email-already-in-use') {
                                    errorMessage = 'An account already exists for that email.';
                                  } else {
                                    errorMessage = 'Error: ${e.message}';
                                  }
                    
                                  // Hiển thị thông báo lỗi nếu có
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(errorMessage)),
                                  );
                                } catch (e) {
                                  // Bắt lỗi khi lưu vào Firestore hoặc Realtime Database thất bại
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to save user data: $e')),
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
                            child: const Text("Đăng kí"),
                          ),
                          const SizedBox(height: 12.0),
                          // Already have an account
                          TextButton(
                            style: ButtonStyle(
                                overlayColor: MaterialStateProperty.all<Color>(Colors.green.withOpacity(0.2)),
                              ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => SignInScreen()),
                              );
                            },
                            child: Text.rich(
                              TextSpan(
                                text: "Bạn đã có tài khoản? ",
                                children: [
                                  TextSpan(
                                    text: "Đăng nhập",
                                    style: const TextStyle(color: Color(0xFF00BF6D)),
                                  ),
                                ],
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
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
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
