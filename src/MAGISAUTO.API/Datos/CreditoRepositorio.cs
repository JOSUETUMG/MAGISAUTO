using System.Data;
using System.Globalization;
using MAGISAUTO.API.Modelos;
using Microsoft.Data.SqlClient;
using Fila = System.Collections.Generic.Dictionary<string, object?>;

namespace MAGISAUTO.API.Datos;

public sealed class CreditoRepositorio(ConexionSqlFactory conexiones)
{
    private static int Id(Fila f,string k)=>Convert.ToInt32(f[k]);
    private static string Nombre(Fila f)=>string.Join(" ",new[]{"primerNombre","segundoNombre","primerApellido","segundoApellido"}.Select(k=>f[k]?.ToString()).Where(x=>!string.IsNullOrWhiteSpace(x)));
    private static Fila Dinero(Fila f)=>f.ToDictionary(p=>p.Key,p=>p.Value is decimal d ? (object)d.ToString(CultureInfo.InvariantCulture):p.Value);
    private async Task<T> Transaccion<T>(Func<SqlConnection,SqlTransaction,ClienteSqlSesion,Task<T>> accion,CancellationToken ct)
    {
        await using var cn=conexiones.Crear(); await cn.OpenAsync(ct);
        await using var tx=(SqlTransaction)await cn.BeginTransactionAsync(IsolationLevel.Serializable,ct);
        try { var r=await accion(cn,tx,new(cn,tx)); await tx.CommitAsync(ct);return r; }
        catch(SqlException ex) when(ex.Number is >=51000 and <=51399)
        { throw new OperacionCatalogoException(409,ex.Message); }
        catch(SqlException ex) when(ex.Number is 2601 or 2627)
        { throw new OperacionCatalogoException(409,"Ese número de crédito o vínculo ya existe. Revisa el listado."); }
        catch(SqlException ex) when(ex.Number==547)
        { throw new OperacionCatalogoException(409,"Hay datos vinculados o una selección dejó de existir. Revisa cliente, vehículo, vendedor y fiadores."); }
        catch(SqlException ex) when(ex.Number is 2812 or 207)
        { throw new OperacionCatalogoException(503,"Falta instalar la actualización SQL de presentación de créditos. Consulta la documentación del módulo."); }
        catch(SqlException ex) when(ex.Number==8115)
        { throw new OperacionCatalogoException(409,"Los importes superan la capacidad del cálculo financiero. Revisa las condiciones del crédito."); }
    }
    private static async Task Ejecutar(SqlConnection cn,SqlTransaction tx,string proc,Fila valores,CancellationToken ct)
    {
        await using var cmd=cn.CreateCommand();cmd.Transaction=tx;cmd.CommandType=CommandType.StoredProcedure;cmd.CommandText="api."+proc;cmd.CommandTimeout=30;
        foreach(var (k,v) in valores)
        {
            SqlParameter p=k switch {
                "NumeroCredito" => cmd.Parameters.Add("@"+k,SqlDbType.VarChar,20),
                "Enganche" or "PorcentajeComision" => cmd.Parameters.Add("@"+k,SqlDbType.Decimal),
                "Plazo" or "FiadoresRequeridos" => cmd.Parameters.Add("@"+k,SqlDbType.SmallInt),
                _ when k.StartsWith("Codigo") => cmd.Parameters.Add("@"+k,SqlDbType.Int),
                _ => cmd.Parameters.Add("@"+k,SqlDbType.NVarChar,k=="Motivo"?300:100)
            };
            if(k=="Enganche"){p.Precision=18;p.Scale=2;}
            if(k=="PorcentajeComision"){p.Precision=9;p.Scale=6;}
            p.Value=v??DBNull.Value;
        }
        await cmd.ExecuteNonQueryAsync(ct);
    }
    private static async Task<Fila> Existe(ClienteSqlSesion db,string numero,CancellationToken ct)
    {
        var c=(await db.Leer("Credito",ct)).SingleOrDefault(c=>string.Equals(c["numeroCredito"]?.ToString(),numero,StringComparison.OrdinalIgnoreCase));
        if(c is null) throw new OperacionCatalogoException(404,"El crédito no existe.");
        if(!c.ContainsKey("fechaPresentacion")) throw new OperacionCatalogoException(503,"Falta instalar la actualización SQL de presentación de créditos.");
        return c;
    }
    public Task<object> Catalogos(CancellationToken ct)=>Transaccion<object>(async(cn,tx,db)=>{
        var personas=(await db.Leer("Persona",ct)).ToDictionary(p=>Id(p,"codigoPersona"));
        async Task<object[]> Roles(string entidad,string clave)=> (await db.Leer(entidad,ct)).Select(r=>(object)new{Codigo=Id(r,clave),Nombre=Nombre(personas[Id(r,"codigoPersona")]),CodigoPersona=Id(r,"codigoPersona")}).ToArray();
        var marcas=(await db.Leer("Marca",ct)).ToDictionary(r=>Id(r,"codigoMarca"));
        var lineas=(await db.Leer("Linea",ct)).ToDictionary(r=>(Id(r,"codigoMarca"),Id(r,"codigoLinea")));
        return new {Clientes=await Roles("Deudor","codigoDeudor"),Vendedores=await Roles("Vendedor","codigoVendedor"),Fiadores=await Roles("Fiador","codigoFiador"),
            Vehiculos=(await db.Leer("Garantia",ct)).Select(g=>new{Codigo=Id(g,"codigoGarantia"),Nombre=$"{marcas[Id(g,"codigoMarca")]["descripcion"]} · {lineas[(Id(g,"codigoMarca"),Id(g,"codigoLinea"))]["descripcion"]} · {g["vin"]}",Precio=Convert.ToDecimal(g["valorAgencia"]).ToString("F2",CultureInfo.InvariantCulture)}),
            Parametros=(await db.Leer("ParametroCredito",ct)).Where(p=>Convert.ToBoolean(p["activo"])).Select(Dinero)};
    },ct);
    public Task<object> Listar(string? criterio,CancellationToken ct)=>Transaccion<object>(async(cn,tx,db)=>{
        var personas=(await db.Leer("Persona",ct)).ToDictionary(p=>Id(p,"codigoPersona"));
        var clientes=(await db.Leer("Deudor",ct)).ToDictionary(p=>Id(p,"codigoDeudor"));
        var vehiculos=(await db.Leer("Garantia",ct)).ToDictionary(p=>Id(p,"codigoGarantia"));
        return (await db.Leer("Credito",ct)).Select(c=>{var f=Dinero(c);f["cliente"]=Nombre(personas[Id(clientes[Id(c,"codigoDeudor")],"codigoPersona")]);f["vin"]=vehiculos[Id(c,"codigoGarantia")]["vin"];return f;})
            .Where(c=>criterio is null || new[]{"numeroCredito","cliente","vin","estado"}.Any(k=>c[k]?.ToString()?.Contains(criterio,StringComparison.OrdinalIgnoreCase)==true)).ToArray();
    },ct);
    public Task<object> Obtener(string numero,CancellationToken ct)=>Transaccion<object>(async(cn,tx,db)=>{
        var c=Dinero(await Existe(db,numero,ct)); numero=c["numeroCredito"]!.ToString()!;
        c["fiadores"]=(await db.Leer("CreditoFiador",ct)).Where(f=>f["numeroCredito"]?.ToString()==numero).Select(f=>Id(f,"codigoFiador")).ToArray();
        c["cuotas"]=(await db.Leer("DetalleCuota",ct)).Where(f=>f["numeroCredito"]?.ToString()==numero).Select(Dinero).ToArray();
        return c;
    },ct);
    public Task<int> Guardar(string? numero,CreditoSolicitud s,CancellationToken ct)=>Transaccion(async(cn,tx,db)=>{
        decimal? comision=s.ComisionPorcentaje/100m;
        if(numero is not null){var actual=await Existe(db,numero,ct);if(!string.Equals(numero,s.NumeroCredito,StringComparison.OrdinalIgnoreCase))throw new OperacionCatalogoException(400,"El número de crédito se conserva.");
            comision??=Convert.ToDecimal(actual["porcentajeComision"]);
            // Retirar los vínculos dentro de la misma transacción permite cambiar cliente y fiadores juntos.
            foreach(var f in (await db.Leer("CreditoFiador",ct)).Where(f=>string.Equals(f["numeroCredito"]?.ToString(),numero,StringComparison.OrdinalIgnoreCase)))
                await Ejecutar(cn,tx,"CreditoFiador_Eliminar",new(){["NumeroCredito"]=numero,["CodigoFiador"]=f["codigoFiador"]},ct);
        }
        var datos=new Fila{["NumeroCredito"]=s.NumeroCredito,["CodigoDeudor"]=s.CodigoDeudor,["CodigoGarantia"]=s.CodigoGarantia,["CodigoVendedor"]=s.CodigoVendedor,["Enganche"]=s.Enganche,["Plazo"]=s.Plazo,["FiadoresRequeridos"]=s.FiadoresRequeridos};
        datos["PorcentajeComision"]=comision;
        // Si la pantalla vio otra versión activa, el SP rechaza la operación en vez de aplicar una nueva a escondidas.
        if(s.CodigoParametro is not null)datos["CodigoParametro"]=s.CodigoParametro.Value;
        await Ejecutar(cn,tx,numero is null?"Credito_Insertar":"Credito_Actualizar",datos,ct);
        // Comprobar la versión dentro de la transacción: sin migración no queda un alta parcial.
        await Existe(db,s.NumeroCredito,ct);
        foreach(var id in s.Fiadores)await Ejecutar(cn,tx,"CreditoFiador_Insertar",new(){["NumeroCredito"]=s.NumeroCredito,["CodigoFiador"]=id},ct);
        return 1;
    },ct);
    public Task<int> Accion(string numero,string accion,CreditoAccion? s,CancellationToken ct)=>Transaccion(async(cn,tx,db)=>{
        await Existe(db,numero,ct);
        var datos=new Fila{["NumeroCredito"]=numero};
        if(s is not null)datos["Responsable"]=s.Responsable.Trim();
        if(s is CreditoAnulacion a)datos["Motivo"]=a.Motivo.Trim();
        // Eliminar únicamente el borrador completo (asignaciones propias incluidas), nunca un contrato.
        if(accion=="Eliminar")foreach(var f in (await db.Leer("CreditoFiador",ct)).Where(f=>string.Equals(f["numeroCredito"]?.ToString(),numero,StringComparison.OrdinalIgnoreCase)))
            await Ejecutar(cn,tx,"CreditoFiador_Eliminar",new(){["NumeroCredito"]=numero,["CodigoFiador"]=f["codigoFiador"]},ct);
        await Ejecutar(cn,tx,"Credito_"+accion,datos,ct);return 1;
    },ct);
}
