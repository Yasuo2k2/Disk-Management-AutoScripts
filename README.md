Script này được viết để giúp quản lý phân vùng ổ đĩa và Logical Volume Management (LVM) một cách dễ dàng. Dưới đây là các bước hướng dẫn cách sử dụng các chức năng của script:

Khi chạy script, bạn sẽ thấy danh sách các tùy chọn từ 1 đến 10.

1. Xem thông tin ổ đĩa
  Hiển thị các thông tin tổng quan về hệ thống tệp hiện tại, bao gồm dung lượng đã sử dụng và còn trống.
2. Tạo mới phân vùng
  Hiển thị danh sách các thiết bị lưu trữ.
  Nhập tên thiết bị (ví dụ: sdb) và số phân vùng muốn tạo (ví dụ: 1 để tạo phân vùng sdb1).
  Bạn có thể chỉ định kích thước phân vùng và script sẽ tự động tạo phân vùng và định dạng với hệ thống tệp ext4.
3. Xóa phân vùng
  Hiển thị danh sách thiết bị lưu trữ.
  Nhập tên thiết bị và số phân vùng cần xóa (ví dụ: sdb1).
  Script sẽ thực hiện thao tác unmount phân vùng và xóa phân vùng.
4. Quản lý Logical Volume (LVM)
  Bao gồm nhiều tùy chọn để tạo, xóa và hiển thị danh sách các Volume Group (VG) và Logical Volume (LV):
  Tạo Logical Volume: Cho phép tạo VG từ nhiều thiết bị và tạo LV với kích thước bạn chỉ định.
  Xóa Logical Volume: Xóa LV và các Physical Volume (PV) liên quan trong VG.
  Hiển thị danh sách Volume Group: Xem thông tin chi tiết về các VG đã tạo.
  Hiển thị danh sách Logical Volume: Xem danh sách các LV hiện có.
5. Kiểm tra tình trạng ổ đĩa
  Sử dụng công cụ smartctl để kiểm tra tình trạng của ổ đĩa (SMART status).
6. Danh sách các thiết bị lưu trữ
  Hiển thị danh sách các thiết bị lưu trữ trong hệ thống.
7. Thiết lập giới hạn Quota
  Cho phép thiết lập giới hạn sử dụng đĩa (Quota) cho người dùng. Bạn có thể thiết lập soft limit và hard limit cho một user cụ thể trên một phân vùng hoặc Logical Volume.
8. Kiểm tra giới hạn Quota
  Hiển thị danh sách giới hạn quota cho các user và group hiện tại trong hệ thống.
9. Xóa giới hạn Quota
  Xóa giới hạn Quota đã thiết lập cho một user.
10. Thoát
  Thoát khỏi chương trình.
