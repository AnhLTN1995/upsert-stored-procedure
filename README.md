# 💼 Stored Procedure: `ups_fact_revenue`

## 🧩 Mô tả

`ups_fact_revenue` là stored procedure thực hiện chức năng **ETL dạng UpSert** (Insert hoặc Update) dữ liệu doanh thu từ hệ thống đơn hàng vào bảng **fact_revenue**. Procedure này:

- **Trích xuất & tính toán dữ liệu đơn hàng** từ bảng `SalesOrderHeader` và `SalesOrderDetail`
- Tính các giá trị doanh thu (`LineTotal`) và thuế (`TaxAmt`)
- Gộp kết quả vào bảng tạm `#TempRevenueTable`
- Dùng lệnh `MERGE` để:
  - **UPDATE** nếu bản ghi đã tồn tại (dựa trên `IntegrationID`)
  - **INSERT** nếu bản ghi chưa có

## 📁 Dữ liệu liên quan

| Bảng | Vai trò |
|------|---------|
| `Sales.SalesOrderDetail` | Chi tiết từng dòng đơn hàng |
| `Sales.SalesOrderHeader` | Thông tin tổng quan đơn hàng |
| `dbo.fact_revenue` | Bảng dữ liệu doanh thu cần được cập nhật |

## ⚙️ Các bước thực hiện trong procedure

1. **Tính toán doanh thu và thuế** cho từng dòng sản phẩm
2. Tạo `IntegrationID` duy nhất từ `SalesOrderID` + `SalesOrderDetailID`
3. Sử dụng bảng tạm `#TempRevenueTable` để lưu dữ liệu trung gian
4. Thực hiện `MERGE` vào bảng `fact_revenue`
5. Dọn dẹp bảng tạm sau khi kết thúc

## Lưu ý:

1. Sử dụng: Microsoft SQL Server và Azure Data Studio
2. Mình dùng:
   - IntegrationID được dùng làm khóa chính xác định duy nhất từng dòng
   - COALESCE(UnitPriceDiscount, 0) đảm bảo không lỗi khi có null
   - Có xử lý DROP TABLE IF EXISTS để tránh lỗi khi gọi lại nhiều lần
3. Cách chạy thử:
   - (Tùy chọn) Thiết lập giá trị ngày
      DECLARE @createDate DATETIME = GETDATE();
      DECLARE @updateDate DATETIME = GETDATE();
   - Gọi procedure
      EXEC dbo.ups_fact_revenue;
