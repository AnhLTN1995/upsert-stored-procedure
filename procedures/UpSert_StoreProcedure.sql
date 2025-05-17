ALTER PROCEDURE dbo.ups_fact_revenue 
AS
BEGIN
    DECLARE @createDate DATETIME;
    DECLARE @updateDate DATETIME;
    BEGIN
        -- Transformed Query: Tạo bảng tạm
        SELECT 
            SOH.SalesOrderID,
            SOD.SalesOrderDetailID,
            SOD.ProductID,
            SOH.OrderDate,
            SOH.CustomerID,
            SOD.OrderQty,
            SOD.OrderQty * (SOD.UnitPrice - COALESCE(SOD.UnitPriceDiscount, 0)) AS LineTotal,
            SOH.TaxAmt * (SOD.OrderQty * (SOD.UnitPrice - COALESCE(SOD.UnitPriceDiscount, 0))) / 
                SUM(SOD.OrderQty * (SOD.UnitPrice - COALESCE(SOD.UnitPriceDiscount, 0))) OVER (PARTITION BY SOD.SalesOrderID) AS TaxAmt,
            @createDate AS CreateDate,
            @updateDate AS UpdateDate,
            CONCAT_WS('|', SOH.SalesOrderID, SOD.SalesOrderDetailID) AS IntegrationID
        INTO #TempRevenueTable
        FROM Sales.SalesOrderDetail SOD
        INNER JOIN Sales.SalesOrderHeader SOH
            ON SOD.SalesOrderID = SOH.SalesOrderID
        WHERE SOH.OrderDate > '2013-12-31';

        -- UpSert Revenue
        MERGE dbo.fact_revenue AS TGT
        USING (
            SELECT 
                SalesOrderID,
                SalesOrderDetailID,
                ProductID,
                OrderDate,
                CustomerID,
                OrderQty,
                LineTotal,
                TaxAmt,
                CreateDate,
                UpdateDate,
                IntegrationID
            FROM #TempRevenueTable
        ) AS SRC
        ON TGT.IntegrationID = SRC.IntegrationID
        WHEN MATCHED THEN 
            UPDATE SET 
                TGT.ProductID = SRC.ProductID,
                TGT.OrderDate = SRC.OrderDate,
                TGT.CustomerID = SRC.CustomerID,
                TGT.OrderQty = SRC.OrderQty,
                TGT.LineTotal = SRC.LineTotal,
                TGT.TaxAmt = SRC.TaxAmt,
                TGT.UpdateDate = @updateDate,
                TGT.CreateDate = TGT.CreateDate
        WHEN NOT MATCHED THEN
            INSERT (
                SalesOrderID, 
                SalesOrderDetailID, 
                ProductID, 
                OrderDate, 
                CustomerID, 
                OrderQty, 
                LineTotal, 
                TaxAmt, 
                IntegrationID, 
                CreateDate, 
                UpdateDate
            )
            VALUES (
                SRC.SalesOrderID, 
                SRC.SalesOrderDetailID, 
                SRC.ProductID, 
                SRC.OrderDate, 
                SRC.CustomerID, 
                SRC.OrderQty, 
                SRC.LineTotal, 
                SRC.TaxAmt,  
                SRC.IntegrationID, 
                @createDate, 
                @updateDate
            );
        -- Xóa bảng tạm
        DROP TABLE IF EXISTS #TempRevenueTable;

    END;
END;
