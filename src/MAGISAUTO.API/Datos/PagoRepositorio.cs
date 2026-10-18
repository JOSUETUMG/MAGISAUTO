using System.Data;
using System.Globalization;
using System.Text.Json;
using MAGISAUTO.API.Modelos;
using Microsoft.Data.SqlClient;
using Fila = System.Collections.Generic.Dictionary<string,object?>;

namespace MAGISAUTO.API.Datos;

public sealed class PagoRepositorio(ConexionSqlFactory conexiones)
{
    private static int Id(Fila f,string k)=>Convert.ToInt32(f[k]);
    private static decimal Importe(Fila f,string k)=>Convert.ToDecimal(f[k],CultureInfo.InvariantCulture);
    private static string Texto(decimal n)=>n.ToString("F2",CultureInfo.InvariantCulture);
    private static string? Limpiar(string? s)=>string.IsNullOrWhiteSpace(s)?null:s.Trim();
    // Los identificadores bigint y los importes no pasan por la precisión limitada de JavaScript.
    private static Fila Publicar(Fila f)=>f.ToDictionary(x=>x.Key,x=>x.Value switch{
        decimal d=>(object)d.ToString(CultureInfo.InvariantCulture),long n=>n.ToString(CultureInfo.InvariantCulture),_=>x.Value});
    private async Task<T> Leer<T>(Func<ClienteSqlSesion,Task<T>> accion,CancellationToken ct)
    {
        await using var cn=conexiones.Crear();await cn.OpenAsync(ct);
        await using var tx=(SqlTransaction)await cn.BeginTransactionAsync(IsolationLevel.Serializable,ct);
        var r=await accion(new(cn,tx));await tx.CommitAsync(ct);return r;
    }
    private static async Task<List<Fila>> Pagos(ClienteSqlSesion db,CancellationToken ct)
    {
        var personas=(await db.Leer("Persona",ct)).ToDictionary(f=>Id(f,"codigoPersona"));
        var clientes=(await db.Leer("Deudor",ct)).ToDictionary(f=>Id(f,"codigoDeudor"));
        var creditos=(await db.Leer("Credito",ct)).ToDictionary(f=>f["numeroCredito"]!.ToString()!,StringComparer.OrdinalIgnoreCase);
        var tipos=(await db.Leer("TipoPago",ct)).ToDictionary(f=>Id(f,"codigoTipoPago"));
        return (await db.Leer("DetallePago",ct)).Select(f=>{
            var c=creditos[f["numeroCredito"]!.ToString()!];var p=personas[Id(clientes[Id(c,"codigoDeudor")],"codigoPersona")];
            f["cliente"]=string.Join(" ",new[]{"primerNombre","segundoNombre","primerApellido","segundoApellido"}.Select(k=>p[k]?.ToString()).Where(x=>!string.IsNullOrWhiteSpace(x)));
            f["medioPago"]=tipos[Id(f,"codigoTipoPago")]["descripcion"];
            f["estado"]=f["fechaAnulacion"] is null?"EFECTIVO":"ANULADO";
            f["comisionEfectiva"]=f["fechaAnulacion"] is null?f["comision"]:0m;
            return f;
        }).ToList();
    }
    public Task<object> Listar(string? criterio,string? numeroCredito,CancellationToken ct)=>Leer<object>(async db=>
        (await Pagos(db,ct)).Where(f=>(numeroCredito is null||string.Equals(f["numeroCredito"]?.ToString(),numeroCredito,StringComparison.OrdinalIgnoreCase))&&
            (criterio is null||new[]{"comprobante","numeroCredito","cliente","referenciaBancaria","medioPago","estado"}.Any(k=>f[k]?.ToString()?.Contains(criterio,StringComparison.OrdinalIgnoreCase)==true)))
            .OrderByDescending(f=>Convert.ToInt64(f["codigoPago"])).Select(Publicar).ToArray(),ct);
    public Task<object> Obtener(long codigo,CancellationToken ct)=>Leer<object>(async db=>{
        var f=(await Pagos(db,ct)).SingleOrDefault(f=>Convert.ToInt64(f["codigoPago"])==codigo);
        return f is null?throw new OperacionCatalogoException(404,"El pago no existe."):Publicar(f);
    },ct);
    public Task<object> Catalogos(CancellationToken ct)=>Leer<object>(async db=>new{
        TiposPago=await db.Leer("TipoPago",ct),
        Creditos=(await db.Leer("Credito",ct)).Select(c=>new{NumeroCredito=c["numeroCredito"],Estado=c["estado"]})
    },ct);
    public Task<object> EstadoCuenta(string numero,CancellationToken ct)=>Leer<object>(async db=>{
        var c=(await db.Leer("Credito",ct)).SingleOrDefault(c=>string.Equals(c["numeroCredito"]?.ToString(),numero,StringComparison.OrdinalIgnoreCase));
        if(c is null)throw new OperacionCatalogoException(404,"El crédito no existe.");
        numero=c["numeroCredito"]!.ToString()!;
        var pagos=(await db.Leer("DetallePago",ct)).Where(p=>p["numeroCredito"]?.ToString()==numero).ToArray();
        var cuotas=(await db.Leer("DetalleCuota",ct)).Where(q=>q["numeroCredito"]?.ToString()==numero).Select(q=>{
            var abonado=pagos.Where(p=>Id(p,"cuota")==Id(q,"cuota")&&p["fechaAnulacion"] is null).Sum(p=>Importe(p,"monto"));
            var saldo=Importe(q,"total")-abonado;
            q["pagado"]=abonado;q["saldoPendiente"]=saldo;q["permitePago"]=c["estado"]?.ToString()=="VIGENTE"&&saldo>0;
            q["estadoPago"]=saldo==0?"PAGADA":abonado>0?"PARCIAL":"PENDIENTE";
            return q;
        }).ToArray();
        var total=cuotas.Sum(q=>Importe(q,"total"));var pagado=cuotas.Sum(q=>Importe(q,"pagado"));
        return new{NumeroCredito=numero,Estado=c["estado"],TotalPlan=Texto(total),TotalPagado=Texto(pagado),
            SaldoPlan=Texto(total-pagado),SaldoPorCobrar=Texto(c["estado"]?.ToString()=="VIGENTE"?total-pagado:0),
            ComisionEfectiva=Texto(pagos.Where(p=>p["fechaAnulacion"] is null).Sum(p=>Importe(p,"comision"))),Cuotas=cuotas.Select(Publicar)};
    },ct);
    private async Task<Fila?> Escribir(string nombre,Fila parametros,CancellationToken ct)
    {
        await using var cn=conexiones.Crear();await cn.OpenAsync(ct);
        await using var cmd=cn.CreateCommand();cmd.CommandType=CommandType.StoredProcedure;cmd.CommandText="api."+nombre;cmd.CommandTimeout=30;
        foreach(var(k,v) in parametros){SqlParameter p=k switch{
            "CodigoPago"=>cmd.Parameters.Add("@"+k,SqlDbType.BigInt),
            "NumeroCredito"=>cmd.Parameters.Add("@"+k,SqlDbType.VarChar,20),
            "Cuota"=>cmd.Parameters.Add("@"+k,SqlDbType.SmallInt),
            "CodigoTipoPago"=>cmd.Parameters.Add("@"+k,SqlDbType.Int),
            "Monto"=>cmd.Parameters.Add("@"+k,SqlDbType.Decimal),
            _=>cmd.Parameters.Add("@"+k,SqlDbType.NVarChar,k is "Motivo" or "Observacion"?300:100)};
            if(k=="Monto"){p.Precision=18;p.Scale=2;}p.Value=v??DBNull.Value;
        }
        try{
            await using var reader=await cmd.ExecuteReaderAsync(ct);Fila? result=null;
            // Consumir todos los resultados antes de responder, también el COMMIT del procedimiento.
            do{while(await reader.ReadAsync(ct)){if(result is not null)continue;result=new();for(var i=0;i<reader.FieldCount;i++)result[JsonNamingPolicy.CamelCase.ConvertName(reader.GetName(i))]=reader.IsDBNull(i)?null:reader.GetValue(i);}}while(await reader.NextResultAsync(ct));
            return result is null?null:Publicar(result);
        }
        catch(SqlException ex) when(ex.Number is 51213 or 51215){throw new OperacionCatalogoException(404,"El pago no existe.");}
        catch(SqlException ex) when(ex.Number is >=51200 and <=51299){throw new OperacionCatalogoException(409,ex.Message);}
        catch(SqlException ex) when(ex.Number is 547 or 8115){throw new OperacionCatalogoException(409,"Revisa los importes y datos seleccionados. El pago no se registró.");}
        catch(SqlException ex) when(ex.Number==1205){throw new OperacionCatalogoException(409,"Otra operación coincidió con esta. Consulta el saldo actualizado antes de volver a intentar.");}
    }
    public Task<Fila?> Registrar(PagoSolicitud s,CancellationToken ct)=>Escribir("DetallePago_Insertar",new(){
        ["NumeroCredito"]=s.NumeroCredito.Trim(),["Cuota"]=s.Cuota,["Monto"]=s.Monto,["CodigoTipoPago"]=s.CodigoTipoPago,
        ["Responsable"]=s.Responsable.Trim(),["ReferenciaBancaria"]=Limpiar(s.ReferenciaBancaria),["Observacion"]=Limpiar(s.Observacion)},ct);
    public Task<Fila?> Actualizar(long codigo,PagoObservacion s,CancellationToken ct)=>Escribir("DetallePago_Actualizar",new(){["CodigoPago"]=codigo,["Observacion"]=Limpiar(s.Observacion)},ct);
    public Task<Fila?> Anular(long codigo,PagoAnulacion s,CancellationToken ct)=>Escribir("DetallePago_Anular",new(){["CodigoPago"]=codigo,["Responsable"]=s.Responsable.Trim(),["Motivo"]=s.Motivo.Trim()},ct);
    public Task<Fila?> Eliminar(long codigo,CancellationToken ct)=>Escribir("DetallePago_Eliminar",new(){["CodigoPago"]=codigo},ct);
}
