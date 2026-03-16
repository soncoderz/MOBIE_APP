# MOBIE_APP - Hệ Thống Quản Lý Bệnh Viện

> Nền tảng quản lý bệnh viện toàn diện với dịch vụ web, ứng dụng di động và backend để quản lý lịch hẹn, hồ sơ y tế, bác sĩ, bệnh nhân và các hoạt động của bệnh viện.

![Status](https://img.shields.io/badge/status-hoạt%20động-success)
![Node.js](https://img.shields.io/badge/Node.js-v22.14.0-green)
![React](https://img.shields.io/badge/React-19.0.0-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.10.0%2B-blue)

## 📋 Mục Lục

- [Tính Năng](#tính-năng)
- [Công Nghệ Sử Dụng](#công-nghệ-sử-dụng)
- [Cấu Trúc Dự Án](#cấu-trúc-dự-án)
- [Yêu Cầu Hệ Thống](#yêu-cầu-hệ-thống)
- [Cài Đặt & Thiết Lập](#cài-đặt--thiết-lập)
- [Chạy Dự Án](#chạy-dự-án)
- [Tài Khoản Kiểm Thử](#tài-khoản-kiểm-thử)
- [Tài Liệu API](#tài-liệu-api)
- [Cài Đặt Ứng Dụng Di Động](#cài-đặt-ứng-dụng-di-động)
- [Triển Khai](#triển-khai)
- [Đóng Góp](#đóng-góp)

## ✨ Tính Năng

### Tính Năng Cơ Bản
- **Quản Lý Người Dùng**: Đăng ký bệnh nhân, quản lý hồ sơ và xác thực
- **Quản Lý Bác Sĩ**: Hồ sơ bác sĩ, chuyên khoa, lịch làm việc và sự sẵn có
- **Lịch Hẹn**: Đặt lịch, rescheduling và quản lý cuộc hẹn y tế
- **Hồ Sơ Y Tế**: Lưu trữ và quản lý lịch sử bệnh nhân và tài liệu
- **Đơn Thuốc**: Tạo và quản lý đơn thuốc
- **Nhập Viện**: Quản lý nhập viện và phân bổ giường bệnh
- **Tư Vấn Video Trực Tiếp**: Gọi video thời gian thực bằng LiveKit
- **Hệ Thống Chat**: Nhắn tin thời gian thực giữa bệnh nhân và bác sĩ qua Socket.io
- **Xử Lý Thanh Toán**: Nhiều tùy chọn thanh toán (PayPal, MoMo)
- **Hệ Thống Tính Phí**: Quản lý các khoản phí bệnh viện
- **Tin Tức & Cập Nhật**: Thông báo và tin tức y tế của bệnh viện
- **Thông Báo**: Thông báo thời gian thực về lịch hẹn và cập nhật
- **Đánh Giá**: Đánh giá từ bệnh nhân cho bác sĩ và dịch vụ
- **Analytics**: Bảng điều khiển với biểu đồ và thống kê

### Tính Năng Nâng Cao
- **Chatbot AI**: Chatbot tư vấn y tế do Google Generative AI hỗ trợ
- **Tạo Mã QR**: Cho hồ sơ y tế và đơn thuốc
- **Xác Thực Xã Hội**: Đăng nhập qua Google và Facebook
- **Quản Lý Kho Thuốc**: Theo dõi tồn kho thuốc bệnh viện
- **Mã Giảm Giá**: Áp dụng mã khuyến mãi cho cuộc hẹn
- **Ghi Hình Video**: Lưu trữ các buổi tư vấn

## 🛠️ Công Nghệ Sử Dụng

### Backend
- **Runtime**: Node.js (v22.14.0)
- **Framework**: Express.js
- **Database**: MongoDB với Mongoose
- **Real-time**: Socket.io, LiveKit
- **Xác Thực**: JWT, Passport.js (Google, Facebook OAuth)
- **Thanh Toán**: SDK PayPal, tích hợp MoMo
- **Lưu Trữ File**: Cloudinary
- **Email**: SendGrid
- **AI**: Google Generative AI SDK
- **Lập Lịch**: node-cron, node-cache

### Frontend (Web)
- **Framework**: React 19
- **Build Tool**: Vite
- **CSS**: Tailwind CSS
- **Thành Phần UI**: Material-UI, Ant Design, React Bootstrap
- **Quản Lý Trạng Thái**: React Context
- **HTTP Client**: Axios
- **Real-time**: Socket.io-client
- **Video Call**: LiveKit React Components
- **Biểu Đồ**: Chart.js, Recharts
- **Routing**: React Router v7
- **Xử Lý Ngày**: date-fns, Moment.js
- **Animation**: Framer Motion
- **Toast Notifications**: React Hot Toast, React Toastify

### Mobile (Flutter)
- **Framework**: Flutter 3.10.0+
- **Quản Lý Trạng Thái**: Provider
- **Networking**: Dio
- **Lưu Trữ**: Shared Preferences, Flutter Secure Storage
- **Xác Thực**: Google Sign-In, Facebook Auth
- **Routing**: GoRouter
- **Thông Báo**: Bot Toast
- **Thanh Toán**: URL Launcher cho PayPal/MoMo
- **WebView**: flutter_webview_flutter

## 📁 Cấu Trúc Dự Án

```
MOBIE_APP/
├── client/                      # Frontend React
│   ├── src/
│   │   ├── components/          # Các thành phần React tái sử dụng
│   │   ├── pages/               # Các trang
│   │   ├── context/             # React Context để quản lý trạng thái
│   │   ├── utils/               # Các hàm tiện ích
│   │   ├── App.jsx
│   │   └── main.jsx
│   ├── public/                  # Tài nguyên tĩnh
│   ├── package.json
│   ├── vite.config.js
│   ├── tailwind.config.js
│   └── vercel.json              # Cấu hình triển khai Vercel
│
├── server/                      # Backend Express.js
│   ├── config/                  # Tệp cấu hình
│   │   ├── database.js          # Kết nối MongoDB
│   │   ├── cloudinary.js        # Dịch vụ tải ảnh
│   │   ├── passport.js          # Cấu hình OAuth
│   │   ├── paypal.js            # Thiết lập PayPal
│   │   └── socketConfig.js      # Cấu hình Socket.io
│   │
│   ├── controllers/             # Logic nghiệp vụ (30+ controller)
│   │   ├── authController.js
│   │   ├── appointmentController.js
│   │   ├── doctorController.js
│   │   ├── medicalRecordController.js
│   │   ├── prescriptionController.js
│   │   ├── billingController.js
│   │   ├── chatbotController.js
│   │   └── ... (thêm controller)
│   │
│   ├── models/                  # Schemas MongoDB
│   │   ├── User.js
│   │   ├── Doctor.js
│   │   ├── Appointment.js
│   │   ├── MedicalRecord.js
│   │   ├── Prescription.js
│   │   └── ... (thêm models)
│   │
│   ├── routes/                  # API endpoints (30+ tệp routes)
│   │   ├── user.js              # Routes người dùng
│   │   ├── doctor.js            # Routes bác sĩ
│   │   ├── appointmentRoutes.js
│   │   ├── medicalRecordRoutes.js
│   │   ├── paymentRoutes.js
│   │   ├── chatRoutes.js
│   │   └── ... (thêm routes)
│   │
│   ├── middlewares/             # Express middlewares
│   │   ├── auth.js              # Xác minh JWT
│   │   ├── errorHandler.js
│   │   └── ... (thêm middlewares)
│   │
│   ├── services/                # Dịch vụ logic nghiệp vụ
│   ├── utils/                   # Hàm tiện ích
│   ├── validation/              # Schemas xác thực đầu vào
│   ├── scripts/                 # Scripts seeding database
│   ├── logs/                    # Logs ứng dụng
│   ├── server.js                # Entry point server chính
│   ├── package.json
│   └── .env                     # Biến môi trường (đã cấu hình)
│
└── hospital_mobile_app/         # Ứng dụng Di Động Flutter
    ├── lib/
    │   ├── core/                # Chức năng cốt lõi
    │   ├── data/                # Models dữ liệu và repositories
    │   ├── domain/              # Entities logic nghiệp vụ
    │   ├── presentation/        # Screens và widgets UI
    │   └── main.dart
    ├── android/                 # Mã native Android
    ├── ios/                     # Mã native iOS
    ├── pubspec.yaml             # Phụ thuộc Flutter
    └── google-services.json     # Cấu hình Firebase
```

## 📋 Yêu Cầu Hệ Thống

- **Node.js** v22.14.0 trở lên
- **npm** hoặc **yarn** package manager
- **MongoDB** (sử dụng MongoDB Atlas miễn phí)
- **Git** đã cài đặt
- **Flutter** 3.10.0+ (cho phát triển ứng dụng di động)
- **Android Studio** hoặc **Xcode** (cho ứng dụng di động)

## 🚀 Cài Đặt & Thiết Lập

### 1. Clone Repository

```bash
git clone https://github.com/soncoderz/DACS-hospitalweb.git
cd MOBIE_APP
```

### 2. Thiết Lập Backend

```bash
cd server

# Cài đặt phụ thuộc
npm install

# Tệp .env đã được cấu hình sẵn với:
# - Chuỗi kết nối MongoDB
# - Khóa bí mật JWT
# - Thông tin xác thực OAuth (Google, Facebook)
# - Khóa API Cloudinary
# - Thông tin PayPal
# - Khóa API SendGrid

# Khởi động server ở chế độ development
npm run dev
```

**Server chạy tại**: `http://localhost:5000`

### 3. Thiết Lập Frontend

```bash
cd ../client

# Cài đặt phụ thuộc (sử dụng --force để tránh xung đột)
npm install --force

# Tệp .env đã được cấu hình sẵn với:
# - URL API base: http://localhost:5000/api
# - Khóa nhà cung cấp OAuth
# - Thông tin thanh toán

# Khởi động development server
npm run dev
```

**Frontend chạy tại**: `http://localhost:3000`

### 4. Khởi Động Cả Hai Dịch Vụ (Khuyến Nghị: Sử Dụng 2 Terminal)

**Terminal 1 - Backend:**
```bash
cd server
npm run dev
```

**Terminal 2 - Frontend:**
```bash
cd client
npm run dev
```

Sau đó truy cập `http://localhost:3000` trong trình duyệt của bạn.

## 🧪 Tài Khoản Kiểm Thử

### Tài Khoản Admin
- **Email**: `admin@congson.com`
- **Mật khẩu**: `qwe123`
- **Vai trò**: Truy cập toàn bộ hệ thống

### Tài Khoản Bệnh Nhân
- **Email 1**: `user1@example.com` | **Mật khẩu**: `HospitalApp@123`
- **Email 2**: `user2@example.com` | **Mật khẩu**: `HospitalApp@123`
- **Lựa chọn khác**: Đăng nhập qua Google hoặc Facebook OAuth

### Tài Khoản Bác Sĩ
- **Email 1**: `nguyenhoanglan5008@gmail.com` | **Mật khẩu**: `qwe123`
- **Email 2**: `doctor.b@example.com` | **Mật khẩu**: `HospitalApp@123`
- **Email 3**: `doctor.c@example.com` | **Mật khẩu**: `HospitalApp@123`
- **Email 4**: `doctor.d@example.com` | **Mật khẩu**: `HospitalApp@123`
- **Tạo Thêm**: Sử dụng tài khoản admin để tạo thêm tài khoản bác sĩ

## 📡 Tài Liệu API

### URL Cơ Sở
```
http://localhost:5000/api
```

### Các Endpoints API Chính

| Tính Năng | Routes |
|---------|--------|
| **Người Dùng** | `/users/*`, `/auth/*` |
| **Bác Sĩ** | `/doctors/*`, `/doctor-auth/*` |
| **Lịch Hẹn** | `/appointments/*` |
| **Hồ Sơ Y Tế** | `/medical-records/*` |
| **Đơn Thuốc** | `/prescriptions/*` |
| **Tính Phí** | `/billing/*` |
| **Chat** | `/chat/*` |
| **Thanh Toán** | `/payments/*`, `/paypal/*` |
| **Gọi Video** | `/video-room/*`, `/doctor-meeting/*` |
| **Thông Báo** | `/notifications/*` |
| **Tin Tức** | `/news/*` |
| **Chatbot** | `/chatbot/*` |
| **Thông Tin Bệnh Viện** | `/hospital/*`, `/services/*` |
| **Phân Tích** | `/statistics/*` |

### Xác Thực
Tất cả các yêu cầu API (ngoại trừ login/register) đòi hỏi JWT token trong header:
```
Authorization: Bearer <your_token>
```

### Tính Năng Thời Gian Thực
- **Socket.io Events**: Tin nhắn chat, thông báo, cập nhật trạng thái
- **Tích Hợp LiveKit**: Phòng tư vấn video với khả năng ghi hình

## 📱 Cài Đặt Ứng Dụng Di Động

### Yêu Cầu
- Flutter SDK 3.10.0 trở lên
- Android SDK hoặc Xcode

### Cài Đặt

```bash
cd hospital_mobile_app

# Lấy phụ thuộc
flutter pub get

# Chạy trên thiết bị kết nối hoặc emulator
flutter run

# Build APK (Android)
flutter build apk

# Build ứng dụng iOS
flutter build ios
```

### Tính Năng
- Lịch hẹn và hồ sơ y tế của bệnh nhân
- Thanh toán trong ứng dụng (PayPal, MoMo)
- Tìm kiếm và đặt lịch bác sĩ
- Chat với nhà cung cấp dịch vụ y tế
- Thông báo đẩy
- Khả năng hoạt động ngoại tuyến

## 🚢 Triển Khai

### Triển Khai Backend (Railway)
1. Đẩy mã của bạn lên GitHub
2. Kết nối Railway với repository GitHub của bạn
3. Đặt biến môi trường trong dashboard Railway
4. Triển khai tự động khi đẩy

### Triển Khai Frontend (Vercel)
1. Cấu hình đã có sẵn trong `vercel.json`
2. Kết nối Vercel với repository GitHub
3. Biến môi trường được tự động cấu hình
4. Triển khai tự động khi đẩy đến nhánh main

### URL API trong Sản Xuất
Cập nhật URL API trong `client/.env` để trỏ tới backend Railway của bạn.

## 🤝 Đóng Góp

1. Tạo nhánh mới cho tính năng của bạn
   ```bash
   git checkout -b feature/TinhNangTuyetVoi
   ```

2. Commit các thay đổi của bạn
   ```bash
   git commit -m 'Thêm một số TinhNangTuyetVoi'
   ```

3. Đẩy đến nhánh
   ```bash
   git push origin feature/TinhNangTuyetVoi
   ```

4. Mở Pull Request trên GitHub

## 📝 Cấu Hình Môi Trường

### Biến Backend (.env)
```
NODE_ENV=development
PORT=5000
MONGODB_URI=<your_mongodb_atlas_uri>
JWT_SECRET=<your_jwt_secret>
CLOUDINARY_NAME=<your_cloudinary_name>
CLOUDINARY_KEY=<your_cloudinary_key>
CLOUDINARY_SECRET=<your_cloudinary_secret>
PAYPAL_MODE=sandbox
PAYPAL_CLIENT_ID=<your_paypal_client_id>
PAYPAL_SECRET=<your_paypal_secret>
GOOGLE_ID=<your_google_oauth_id>
GOOGLE_SECRET=<your_google_oauth_secret>
FB_APP_ID=<your_facebook_app_id>
FB_APP_SECRET=<your_facebook_app_secret>
SENDGRID_API_KEY=<your_sendgrid_key>
GOOGLE_GENAI_KEY=<your_google_genai_key>
```

### Biến Frontend (.env)
```
VITE_API_URL=http://localhost:5000/api
VITE_GOOGLE_CLIENT_ID=<your_google_client_id>
VITE_PAYPAL_CLIENT_ID=<your_paypal_client_id>
VITE_FB_APP_ID=<your_facebook_app_id>
```

## 📦 Build cho Sản Xuất

### Build Frontend
```bash
cd client
npm run build
# Output: dist/
```

### Backend Sản Xuất
```bash
cd server
npm start
```

## 🐛 Khắc Phục Sự Cố

### Xung Đột Phụ Thuộc
Nếu gặp xung đột phụ thuộc khi cài đặt:
```bash
cd client
npm install --force
```

### Cổng Đang Được Sử Dụng
- Backend (5000): Tìm và dừng quy trình
- Frontend (3000): Tìm và dừng quy trình

### Vấn Đề Kết Nối Database
- Xác minh thông tin MongoDB Atlas trong .env
- Kiểm tra danh sách IP trong dashboard MongoDB Atlas
- Đảm bảo kết nối mạng

### Lỗi Build
- Xóa cache: `npm cache clean --force`
- Xóa node_modules: `rm -rf node_modules`
- Cài đặt lại: `npm install --force`

## 📚 Tài Nguyên Bổ Sung

- [Express.js Tài Liệu](https://expressjs.com/)
- [React Tài Liệu](https://react.dev/)
- [Flutter Tài Liệu](https://flutter.dev/docs)
- [MongoDB Tài Liệu](https://docs.mongodb.com/)
- [Socket.io Tài Liệu](https://socket.io/docs/)



## 👨‍💻 Tác Giả

**Sơn Coderz** - [GitHub](https://github.com/soncoderz)

---

**Trạng Thái**: Sẵn Sàng Sản Xuất ✅  
**Cập Nhật Lần Cuối**: 2026-03-16  
**Triển Khai**: Railway (Backend) + Vercel (Frontend)