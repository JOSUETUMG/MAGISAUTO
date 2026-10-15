using System.Data;
using System.Globalization;
using MAGISAUTO.API.Modelos;
using Microsoft.Data.SqlClient;
using Fila = System.Collections.Generic.Dictionary<string, object?>;

namespace MAGISAUTO.API.Datos;

public sealed class ParametroCreditoRepositorio(ConexionSqlFactory conexiones)
{
    private static int Id(Fila f) => Convert.ToInt32(f["codigoParametro"]);
    private static bool Activo(Fila f) => Convert.ToBoolean(f["activo"]);
    private static string Porcentaje(Fila f, string k) => (Convert.ToDecimal(f[k])*100m).ToString("0.####",CultureInfo.InvariantCulture);
    private static object Publico(Fila f, HashSet<int> usados) => new {
        CodigoParametro=Id(f), Nombre=f["nombre"], Activo=Activo(f), EnUso=usados.Contains(Id(f)),
        TasaAnualPorcentaje=Porcentaje(f,"tasaAnual"), SeguroAutoMensualPorcentaje=Porcentaje(f,"tasaSeguroAuto"),
        SeguroVidaMensualPorcentaje=Porcentaje(f,"tasaSeguroVida"), EngancheMinimoPorcentaje=Porcentaje(f,"engancheMinimo"),
        ComisionPredeterminadaPorcentaje=Porcentaje(f,"comisionPredeterminada"), DepreciacionInicialPorcentaje=Porcentaje(f,"depreciacionInicial"),
        ManejoMensual=Convert.ToDecimal(f["manejoMensual"]).ToString("F2",CultureInfo.InvariantCulture)
    };
    private static Fila Valores(ParametroCreditoSolicitud s, bool activo) => new() {
        ["nombre"]=s.Nombre.Trim(),["activo"]=activo,["tasaAnual"]=s.TasaAnualPorcentaje!.Value/100m,
        ["tasaSeguroAuto"]=s.SeguroAutoMensualPorcentaje!.Value/100m,["tasaSeguroVida"]=s.SeguroVidaMensualPorcentaje!.Value/100m,
        ["engancheMinimo"]=s.EngancheMinimoPorcentaje!.Value/100m,["comisionPredeterminada"]=s.ComisionPredeterminadaPorcentaje!.Value/100m,
        ["depreciacionInicial"]=s.DepreciacionInicialPorcentaje!.Value/100m,["manejoMensual"]=25m
    };
    private async Task<T> Transaccion<T>(Func<SqlConnection,SqlTransaction,ClienteSqlSesion,Task<T>> tarea,CancellationToken ct)
    {
        await using var cn=conexiones.Crear(); await cn.OpenAsync(ct);
        await using var tx=(SqlTransaction)await cn.BeginTransactionAsync(IsolationLevel.Serializable,ct);
        try { var r=await tarea(cn,tx,new(cn,tx)); await tx.CommitAsync(ct); return r; }
        catch(SqlException ex) when(ex.Number is 2601 or 2627 or 1205)
        { throw new OperacionCatalogoException(409,"Otra operación cambió la configuración. Actualiza el listado e inténtalo de nuevo."); }
        catch(SqlException ex) when(ex.Number==547)
        { throw new OperacionCatalogoException(409,"La configuración está vinculada a créditos o contiene valores fuera de rango. Actualiza el listado."); }
        catch(SqlException ex) when(ex.Number==51008)
        { throw new OperacionCatalogoException(404,"La configuración ya no existe."); }
    }
    private static async Task<int?> Ejecutar(SqlConnection cn,SqlTransaction tx,string operacion,int? id,Fila? f,CancellationToken ct)
    {
        await using var cmd=cn.CreateCommand();cmd.Transaction=tx;cmd.CommandType=CommandType.StoredProcedure;
        cmd.CommandText="api.ParametroCredito_"+operacion;cmd.CommandTimeout=20;
        if(id is not null)cmd.Parameters.Add("@CodigoParametro",SqlDbType.Int).Value=id.Value;
        if(f is not null) {
            cmd.Parameters.Add("@Nombre",SqlDbType.NVarChar,100).Value=f["nombre"];
            cmd.Parameters.Add("@Activo",SqlDbType.Bit).Value=f["activo"];
            foreach(var k in new[]{"tasaAnual","manejoMensual","tasaSeguroAuto","tasaSeguroVida","engancheMinimo","comisionPredeterminada","depreciacionInicial"}) {
                var p=cmd.Parameters.Add("@"+char.ToUpperInvariant(k[0])+k[1..],SqlDbType.Decimal);
                p.Precision=(byte)(k=="manejoMensual"?18:9);p.Scale=(byte)(k=="manejoMensual"?2:6);p.Value=f[k];
            }
        }
        int? creado=null;
        await using var reader=await cmd.ExecuteReaderAsync(ct);
        do { while(await reader.ReadAsync(ct))if(operacion=="Insertar")creado=reader.GetInt32(0); }while(await reader.NextResultAsync(ct));
        return creado;
    }
    private static async Task<HashSet<int>> Usados(ClienteSqlSesion db,CancellationToken ct) =>
        (await db.Leer("Credito",ct)).Select(c=>Convert.ToInt32(c["codigoParametro"])).ToHashSet();
    public Task<object> Listar(string? criterio,CancellationToken ct)=>Transaccion<object>(async(cn,tx,db)=>{
        var filas=await db.Leer("ParametroCredito",ct);var usados=await Usados(db,ct);
        if(criterio is not null) {
            await using var cmd=cn.CreateCommand();cmd.Transaction=tx;cmd.CommandType=CommandType.StoredProcedure;
            cmd.CommandText="api.ParametroCredito_Buscar";cmd.CommandTimeout=20;
            cmd.Parameters.Add("@Criterio",SqlDbType.NVarChar,200).Value=criterio;
            var ids=new HashSet<int>();await using(var r=await cmd.ExecuteReaderAsync(ct))while(await r.ReadAsync(ct))ids.Add(r.GetInt32(r.GetOrdinal("CodigoParametro")));
            filas=filas.Where(f=>ids.Contains(Id(f))).ToList();
        }
        return filas.Select(f=>Publico(f,usados)).ToArray();
    },ct);
    public Task<int> Crear(ParametroCreditoSolicitud s,CancellationToken ct)=>Transaccion(async(cn,tx,db)=>{
        // Cada versión nueva comienza inactiva; activarla es una acción explícita distinta.
        return (await Ejecutar(cn,tx,"Insertar",null,Valores(s,false),ct))!.Value;
    },ct);
    public Task<int> Cambiar(int id,string accion,ParametroCreditoSolicitud? s,CancellationToken ct)=>Transaccion(async(cn,tx,db)=>{
        var filas=await db.Leer("ParametroCredito",ct);
        var f=filas.SingleOrDefault(f=>Id(f)==id)??throw new OperacionCatalogoException(404,"La configuración no existe.");
        if(accion=="Activar") {
            // El cambio de activa es atómico: ninguna lectura confirma el estado intermedio sin activa.
            if(Activo(f))return id;
            foreach(var anterior in filas.Where(Activo)){anterior["activo"]=false;await Ejecutar(cn,tx,"Actualizar",Id(anterior),anterior,ct);}
            f["activo"]=true;await Ejecutar(cn,tx,"Actualizar",id,f,ct);return id;
        }
        if((await Usados(db,ct)).Contains(id))
            throw new OperacionCatalogoException(409,"Esta configuración ya se usó en créditos. Conserva su historial y crea una copia para cambiar las condiciones.");
        if(accion=="Actualizar" && Activo(f))
            throw new OperacionCatalogoException(409,"La configuración activa se conserva. Crea una copia inactiva y actívala cuando esté lista.");
        if(accion=="Eliminar" && Activo(f))
            throw new OperacionCatalogoException(409,"Activa otra configuración antes de eliminar esta.");
        await Ejecutar(cn,tx,accion,id,s is null?null:Valores(s,Activo(f)),ct);return id;
    },ct);
}
