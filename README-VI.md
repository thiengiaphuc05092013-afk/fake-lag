# RealPing V22 — Java và dự án rebuild từ APK

Đầu vào: `RealPing-V22-Clear.apk`, package `com.kimquynh.dev`, versionName 3.0.7 / versionCode 8.

## Kết quả bản cập nhật
- 786 tệp Java do JADX dịch ngược từ ba DEX.
- 348 hàm native đọc/ghi trường dữ liệu đã được thay bằng phần thân Java trong 8 tệp nguồn. Có dấu vết JNI với hai bộ giá trị thử và kiểm tra cú pháp Java cho cả 8 tệp.
- Cả 1.237 khai báo native gốc đã đối chiếu được với địa chỉ ARM64, qua export hoặc mô phỏng đăng ký động của hai thư viện.
- 889 khai báo native gốc vẫn CHƯA được chuyển thành phần thân Java. Địa chỉ native và mã giả C không phải phần thân Java.
- Dự án smali đã build lại thành công; Java/Gradle chưa được xác nhận build hoặc chạy thành công trên Android.

Đây chưa phải mã nguồn gốc hoặc dự án Full Java build độc lập. Không thay các hàm còn thiếu bằng hàm rỗng/trả giá trị mặc định.

## Nội dung
- `java-gradle/`: Java dịch ngược, có 348 phần thân Java khôi phục thêm, manifest, tài nguyên, assets và jniLibs. Cấu hình Gradle được JADX xuất, còn cần sửa để biên dịch được.
- `apktool-project/`: smali gốc của cả ba DEX, tài nguyên, assets, thư viện ARM64 và cấu hình Apktool. Các thay đổi Java KHÔNG tự đồng bộ vào dự án này.
- `original-dex/`: ba DEX nguyên bản.
- `tools/apktool.jar`: Apktool 2.11.1, giấy phép trong JAR.
- `native-analysis/`: mã giả C, ARM64, chuỗi ký tự, ELF, bảng địa chỉ native và bằng chứng khôi phục Java.
- `reports/`: log dịch ngược, log build, phân tích native và SHA-256 đầu vào.

## Build đã kiểm tra
Cài Java 17 trở lên, giải nén ZIP rồi chạy `sh build.sh` (Linux/macOS) hoặc `build.bat` (Windows). Kết quả `out/RealPing-V22-unsigned.apk` được tạo từ smali, giữ nguyên hai thư viện native gốc.

Bảy ảnh mang đuôi PNG nhưng chứa JPEG đã được chuyển thành PNG thật để AAPT2 build được. Bản Java và bản smali là hai tuyến chỉnh sửa độc lập; build.sh không biên dịch các thay đổi Java.

APK đầu ra chưa ký. Dùng Android SDK Build Tools và keystore của bạn:
```sh
zipalign -p -f 4 out/RealPing-V22-unsigned.apk out/RealPing-V22-aligned.apk
apksigner sign --ks YOUR_KEYSTORE.jks --out out/RealPing-V22-signed.apk out/RealPing-V22-aligned.apk
apksigner verify out/RealPing-V22-signed.apk
```
Không có khóa ký gốc trong APK. Ký khác khóa thường cần gỡ bản cũ trước khi cài, có thể mất dữ liệu cũ. Chưa kiểm thử trên điện thoại.

## Bằng chứng Java
- `native-analysis/java-recovery/recovered-accessors.json`: danh sách chính xác 348 hàm đã sửa, địa chỉ, câu lệnh Java và hai dấu vết JNI cho từng hàm.
- `native-analysis/java-recovery/accessor-fragments.java.txt`: bản trích các hàm Java đã khôi phục.
- `native-analysis/java-recovery/java-syntax-check.json`: kết quả kiểm tra cú pháp cho 8 tệp Java đã sửa. Đây là kiểm tra cú pháp, KHÔNG phải build Gradle, kiểm chứng kiểu dữ liệu hoặc thử nghiệm Android.
- Chỉ các hàm thể hiện một thao tác đọc/ghi trường phù hợp với giá trị truyền/giá trị trả về trong cả hai dấu vết được chuyển. Chưa chứng minh tương đương toàn bộ chương trình, mọi trạng thái cache, mọi ngoại lệ hoặc mọi thiết bị.
- Bộ đăng ký native vẫn còn trong dự án Java. Khi biên dịch và chạy Java tái tạo, cần xử lý đăng ký cho những hàm đã chuyển sang Java; chưa xác nhận việc khởi tạo native hoặc liên kết JNI sau biên dịch.

JADX còn một lỗi dịch ngược tại `androidx.localbroadcastmanager.content.LocalBroadcastManager.executePendingBroadcasts()`, xem `reports/java-issues.txt`; nhiều cảnh báo khác nằm trong Java. Các kiểu, tên tổng hợp, thư viện và cấu hình Gradle cũng có thể cần sửa.

## Bảng ánh xạ native
- `native-analysis/java-native-methods.json`: 1.237 khai báo gốc, lớp, vị trí smali, chữ ký và địa chỉ tương ứng. Bản cập nhật sửa các tên lớp chưa được nhận diện trong thống kê cũ.
- `emulated-native-registration.json`: 1.160 đăng ký native trong 270 class ID của libpy360; cả 270 lượt mô phỏng hoàn tất.
- `smali-native-registration.json`: 270 lời gọi đăng ký theo class ID trích trực tiếp từ smali.
- Hàm bootstrap `Python.registerNativesForClass` khớp địa chỉ `0x3aa7bc` bằng đối chiếu lệnh đăng ký và chữ ký.
- `emulated-delayx-registration.json`: 63 bản ghi đăng ký trong libdelayxcore, đọc sau khi mô phỏng hàm khởi tạo bảng tại `0x25fc4`.
- Một số hàm có cả export JNI và đăng ký động; không cộng các số này để đếm hàm duy nhất.

## Giới hạn native và mã giả C
Mỗi thư viện có `decompiled.c`, `functions.tsv`, `disassembly-aarch64.txt`, `strings.tsv`, `symbols.json`, `elf-details.txt`. C là mã giả Ghidra, chưa thể dùng để biên dịch thay `.so` gốc. Tên gốc, kiểu, comment và cấu hình C/C++ ban đầu không có đầy đủ trong APK.

Phân tích tĩnh libpy360 dừng sau giới hạn 240 giây và còn nhiều nhánh gián tiếp chưa giải được. Trạng thái `decompiled` chỉ cho biết công cụ trả mã giả, không chứng minh mã đó đúng hoặc đầy đủ. Hàm Ghidra nhận diện có thể là thunk, stub hoặc ranh giới sai; không đồng nghĩa với hàm Java.

Disassembly là giải mã tuyến tính các section thực thi, có thể chứa vùng dữ liệu; `.byte` là byte chưa giải mã được. Địa chỉ Ghidra trong gói cũ dùng image base `0x100000`; địa chỉ từ ELF và bảng mô phỏng không cộng image base. Offset chuỗi là offset tệp.

`native-analysis/reproduce/` có script và hướng dẫn mô phỏng lại; `summary.json` tóm tắt các con số và giới hạn.
