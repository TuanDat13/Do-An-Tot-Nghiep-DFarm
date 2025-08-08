<?php
// Kết nối cơ sở dữ liệu
$servername = "sql213.infinityfree.com";
$username = "if0_38167896";
$password = "juWbxhQkFQ";
$dbname = "if0_38167896_nntm";

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    die("Kết nối thất bại: " . $conn->connect_error);
}

// Nhận dữ liệu từ yêu cầu POST
$data = json_decode(file_get_contents("php://input"), true);

$name = $data['name'];
$email = $data['email'];
$phone = $data['phone'];
$password = password_hash($data['password'], PASSWORD_BCRYPT); // Mã hóa mật khẩu
$uid = $data['uid'];

// Chèn dữ liệu vào bảng khachhang
$sql_khachhang = "INSERT INTO khachhang (ten, email, sdt) VALUES (?, ?, ?)";
$stmt_khachhang = $conn->prepare($sql_khachhang);
$stmt_khachhang->bind_param("sss", $name, $email, $phone);
if ($stmt_khachhang->execute()) {
    // Lấy id của bản ghi vừa thêm
    $id_khach = $stmt_khachhang->insert_id;

    // Chèn dữ liệu vào bảng account
    $sql_account = "INSERT INTO account (id_khach, taikhoan, matkhau, uid) VALUES (?, ?, ?, ?)";
    $stmt_account = $conn->prepare($sql_account);
    $stmt_account->bind_param("isss", $id_khach, $email, $password, $uid);
    if ($stmt_account->execute()) {
        echo json_encode(["success" => true, "message" => "Tài khoản đã được tạo!"]);
    } else {
        echo json_encode(["success" => false, "message" => "Lỗi thêm vào bảng account: " . $stmt_account->error]);
    }
} else {
    echo json_encode(["success" => false, "message" => "Lỗi thêm vào bảng khachhang: " . $stmt_khachhang->error]);
}

$stmt_khachhang->close();
$stmt_account->close();
$conn->close();
?>
