views = [
'''CREATE VIEW dbo.vw_CreditoResumen AS
 SELECT c.*,CONVERT(decimal(18,2),c.PrecioContado-c.Enganche) AS MontoFinanciado,
 r.TotalIntereses,r.TotalNetoRecaudable
 FROM dbo.Credito c LEFT JOIN dbo.ResumenCredito r ON r.NumeroCredito=c.NumeroCredito;''',
'''CREATE VIEW dbo.vw_CuotaDesglosada AS
 SELECT q.*,c.ManejoMensual AS ManejoCuenta,s.SeguroAuto,s.SeguroVida,
 CONVERT(decimal(18,2),q.Capital+q.Interes+c.ManejoMensual+s.SeguroAuto+s.SeguroVida) AS Total
 FROM dbo.DetalleCuota q JOIN dbo.Credito c ON c.NumeroCredito=q.NumeroCredito
 CROSS APPLY(SELECT CONVERT(decimal(18,2),ROUND((c.PrecioContado-c.Enganche)*c.TasaSeguroAuto,2)) SeguroAuto,
 CONVERT(decimal(18,2),ROUND((c.PrecioContado-c.Enganche)*c.TasaSeguroVida,2)) SeguroVida)s;''',
'''CREATE VIEW dbo.vw_PagoDesglosado AS
 SELECT p.*,c.PorcentajeComision,
 CONVERT(decimal(18,2),ROUND(p.Monto*c.PorcentajeComision,2)) AS Comision
 FROM dbo.DetallePago p JOIN dbo.Credito c ON c.NumeroCredito=p.NumeroCredito;''',
'''CREATE VIEW dbo.vw_DepreciacionCalculada AS
 SELECT d.*,CONVERT(decimal(18,2),ROUND(d.ValorOriginal*(1-d.Porcentaje),2)) AS ValorDepreciado
 FROM dbo.Depreciacion d;'''
]
for view in views:
    emit("EXEC(N'" + view.replace("'", "''") + "');")
