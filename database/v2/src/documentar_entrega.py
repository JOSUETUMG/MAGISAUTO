# Generador histórico de informes de v2.0; no reutilizar sus resultados como evidencia de v2.1.
from pathlib import Path
import json, hashlib, zipfile, re

root=Path(__file__).resolve().parent.parent
repo=root.parent.parent
out=root/'entrega'
inv=json.loads((out/'inventario.json').read_text(encoding='utf-8-sig'))
tests=json.loads((out/'validacion-integracion.json').read_text(encoding='utf-8-sig'))
assert tests['Estado']=='Correcto'
test_count=len(tests['Pruebas'])
if json.loads((out/'inventario.json').read_text(encoding='utf-8-sig')).get('version') != '2.0':
    raise SystemExit('Este informe es historico de v2.0. Para v2.1 consulte docs/FASE_6_Creditos.md; no se sobrescribieron informes.')

readme='''# MAGIS-AUTO — SQL versión 2.0

Preparado el 8 de octubre de 2026, rama pruebas-diego.

## Contenido

Instalación nueva con **26 tablas, 150 procedimientos, 4 vistas y 2 funciones**, llaves, índices, restricciones, catálogos y parámetros. Incluye los 20 reportes descritos en reportes.json. Sin clientes, referencias, fiadores, vendedores, vehículos, créditos, cuotas ni pagos de ejemplo.

Es una ampliación académica del modelo del ingeniero, conforme al PDF y los acuerdos. No es copia literal de MagisV1 ni migración de una base existente. API y pantallas se desarrollan por separado.

## Instalación en SSMS

1. Conectarse al motor SQL Server 2022/2025 con permiso para crear bases.
2. Abrir MAGISAUTO_Proyecto_Completo.sql. El nombre predeterminado es MAGISAUTO_Proyecto_V2; puede cambiarse la variable @Base por otro nombre NUEVO.
3. Ejecutar TODO, sin selección parcial ni modo SQLCMD.
4. Comprobar: 26 tablas, 150 procedimientos y 20 reportes, seguido de instalación completa.
5. Seleccionar la nueva base y ejecutar VERIFICAR_INSTALACION.sql.

Si el nombre existe, se detiene. No borra, migra ni sobrescribe. Un error revierte la transacción de objetos; la base nueva puede quedar vacía para inspección. No ejecutar después el archivo original del ingeniero encima de esta versión.

## Cambios frente a v1

- DetalleCuota guarda fecha, capital e interés. Los cargos mensuales se obtienen de las condiciones originales del crédito mediante vw_CuotaDesglosada. Sigue disponible todo el desglose de los incisos C y E.
- El porcentaje de comisión pertenece al contrato; vw_PagoDesglosado calcula la comisión de cada pago.
- ResumenCredito conserva TotalIntereses y TotalNetoRecaudable en la transacción de aprobación. Un borrador no tiene resumen y muestra NULL en esos totales hasta aprobar.
- MontoFinanciado y ValorDepreciado se exponen en vistas de lectura.
- **Monto depositado sigue almacenado en DetallePago**, como pide el inciso E. CHECK y procedimiento exigen igualdad con los cinco componentes. Es redundancia controlada; no se afirma normalización física absoluta.
- Procedimientos, índices y los 20 reportes utilizan las nuevas fuentes.

ResumenCredito tiene Listar y Buscar; su alta pertenece a la aprobación. No se permite editar/borrar manualmente el resumen de un contrato aprobado. Las 25 entidades operativas conservan Insertar, Actualizar, Eliminar, Listar y Buscar con restricciones financieras. La excepción de esta tabla derivada debe explicarse junto con la interpretación del borrado financiero en la evaluación.

## Reglas conservadas

- Identidad única por rol, correo compartido permitido, contactos múltiples y tres referencias completas al aprobar. Persona admite datos opcionales cuando el rol no los requiere.
- VIN/chasis único, placa opcional, vehículos nuevos y un crédito vigente por vehículo. Fiadores N:M; uno por defecto, cero o más según comité; no puede ser su propio cliente.
- Enganche mínimo 20%, mayor permitido; plazos 12/24/36/48/60, predeterminado 60.
- Sistema francés sobre saldo programado; nominal anual inicial 12.5%, mensual anual/12, configurable; tasa cero y ajuste final de centavos.
- Vencimientos desde el día original, con ajuste al último día si no existe en ese mes.
- Q25 de manejo; seguros académicos de prueba: auto 0.15% y vida 0.05% mensual del monto original financiado. No son cotizaciones de mercado. Condiciones históricas inmutables por contrato.
- Comisión inicial 2%, configurable por crédito, sobre pagos efectivos completos; se revierte al anular, no se carga al cliente. El reporte no certifica desembolso al vendedor.
- Depreciación inicial 15%, seleccionable hasta 20%, con historial. No reduce la deuda ni se aplica periódicamente de forma automática.
- Abonos parciales por cuota, reparto proporcional en centavos, sin sobrepago ni anticipos extraordinarios a capital.
- Recibo único, hora de Guatemala, cinco medios y referencia bancaria según medio. Movimientos cronológicos, sin futuro ni anteriores a aprobación.
- Mora desde el día posterior al vencimiento, sin penalización monetaria. Cortes consideran pagos y anulaciones hasta el final del día.
- Historial financiero conservado: físicos solo registros sin dependencias/borradores; pagos se anulan con fecha, motivo y responsable. Un pago solo permite actualizar observación; corregir importe requiere anular y registrar de nuevo.
- TotalNetoRecaudable = suma de cuotas completas, excluye enganche y no resta comisiones. No equivale a utilidad ni saldo pendiente.

Pendientes del ingeniero: confirmar esa interpretación de total neto recaudable y la anulación frente al borrado físico por entidad. No se presentan como instrucciones textuales del PDF.

## Catálogos y acceso

Incluye cabeceras de Jalapa/Jutiapa (no todo Guatemala), cinco marcas/líneas, tipos de contacto/referencia/garantía/pago, agencia académica y parámetros activos. Ampliables con procedimientos; no requiere el complemento de clase.

La aplicación debe llamar solo procedimientos api.* con parámetros y una cuenta del rol magis_api. Ese rol permite EXECUTE en api y deniega lectura/escritura directa en dbo. El instalador no crea logins ni contraseñas. Vistas y funciones son fuentes internas. El login del personal sigue opcional; el responsable escrito no verifica identidad.

Operaciones financieras: Credito_Aprobar, Credito_Anular y DetallePago_Anular. Listar/Buscar no están paginadas todavía y se orientan al volumen académico.

## Evidencia y límites

'''
readme+=f'''- Sintaxis: 159 bloques sin errores.
- Modelo: 195 objetos sin mensajes.
- Instalación real en SQL Server 2025: MAGISAUTO_ValidacionV2.
- **{test_count} comprobaciones de integración correctas**, incluida ejecución de los 20 reportes, condiciones históricas, abonos, anulaciones, liquidación y dos pagos simultáneos.
- Fórmulas: 75 planes y 1,000 repartos de abonos en SQL Server, con variables de tabla sin operaciones persistentes.

No son pruebas exhaustivas ni de rendimiento masivo. La API, interfaz y autenticación no se probaron aquí. Ejecutar reportes no sustituye la revisión académica de su utilidad.

La base de ensayo conserva datos ficticios; NO están en el instalador. MAGISAUTO_Proyecto y las bases de clase no se modificaron. Todavía falta instalar v2 como base de trabajo y configurar la conexión de la aplicación.

## Archivos

- MAGISAUTO_Proyecto_Completo.sql: instalación nueva.
- VERIFICAR_INSTALACION.sql: estructura y ausencia de operaciones.
- inventario.json y reportes.json: objetos y utilidad de consultas.
- validacion-*.json: resultados obtenidos; no certificados de otra instalación.
- SHA256SUMS.txt: integridad de esta entrega.

Fuentes y ensayo aislado están en ../src en el repositorio. El ZIP no incluye credenciales, permisos de la cuenta técnica ni datos ficticios del ensayo.
'''
(out/'LEEME.md').write_text(readme,encoding='utf-8-sig')
catalogs={'Departamento','Municipio','TipoTelefono','TipoDireccion','TipoGarantia','TipoReferencia','TipoPago','Marca','Linea','Agencia','ParametroCredito'}
verify="""-- Seleccionar en SSMS la base NUEVA instalada con v2. Solo lectura administrativa.
SET NOCOUNT ON;
IF (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0)<>26 THROW 52100,'Se esperaban 26 tablas.',1;
IF (SELECT COUNT(*) FROM sys.views WHERE is_ms_shipped=0)<>4 THROW 52101,'Se esperaban 4 vistas.',1;
IF (SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID('api'))<>150 THROW 52102,'Se esperaban 150 procedimientos.',1;
IF (SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID('api') AND name LIKE 'Reporte%')<>20 THROW 52103,'Se esperaban 20 reportes.',1;
IF EXISTS(SELECT 1 FROM sys.foreign_keys WHERE is_disabled=1 OR is_not_trusted=1) THROW 52104,'Relaciones deshabilitadas o no confiables.',1;
"""
for table in inv['tablas']:
    verify+=f"IF OBJECT_ID(N'dbo.{table}',N'U') IS NULL THROW 52105,'Falta {table}.',1;\n"
    if table not in catalogs:
        verify+=f"IF EXISTS(SELECT 1 FROM dbo.[{table}]) THROW 52106,'Ya hay operaciones en {table}; no es instalacion vacia.',1;\n"
verify+="SELECT DB_NAME() BaseVerificada,26 Tablas,4 Vistas,150 Procedimientos,20 Reportes,N'Estructura y ausencia de operaciones verificadas.' Resultado;\n"
(out/'VERIFICAR_INSTALACION.sql').write_text(verify,encoding='utf-8-sig')
phase3=repo/'docs'/'FASE_3_Modelo_Relacional_3FN.md'
p=phase3.read_text(encoding='utf-8-sig')
p=p.replace('Estado: revisión de diseño terminada; ajustes propuestos pendientes de aprobación antes de implementarlos.', 'Estado: ajustes aprobados por Diego y llevados a v2. La Fase 4 documenta el resultado y la corrección de Monto conforme al inciso E.')
p=p.replace('- [ ] Aprobación de estos ajustes por Diego.', '- [x] Aprobación de estos ajustes por Diego.')
p=p.replace('- [ ] Implementación y pruebas de la nueva versión en la fase siguiente.', '- [x] Implementación y pruebas de v2 documentadas en FASE_4_SQL_Implementado.md.')
if '## Aclaración aplicada en Fase 4' not in p:
    p+='''
## Aclaración aplicada en Fase 4

El inciso E exige almacenar el monto depositado: se conservó DetallePago.Monto. CHECK y procedimiento exigen coincidencia con el desglose. La propuesta anterior de calcular exclusivamente Monto es antecedente de revisión, no el esquema final. Se reconoce esta redundancia controlada sin afirmar 3FN estricta de cada columna física. La fuente final es database/v2/src/deployment_payload.sql y el diccionario final está en la Fase 4.
'''
phase3.write_text(p,encoding='utf-8-sig')
payload=(root/'src'/'deployment_payload.sql').read_text(encoding='utf-8')
tables=re.findall(r'CREATE TABLE dbo\.\[(.*?)\]\(\n (.*?)\n\);',payload,re.S)
phase=f'''# Fase 4 — Implementación SQL de MAGIS-AUTO

Fecha: 8 de octubre de 2026. Rama: pruebas-diego.

Estado: v2 implementada y validada en una base aislada. No conectada aún a la API ni instalada sobre MAGISAUTO_Proyecto.

## Resultado y correspondencia con el PDF

26 tablas, 150 procedimientos, 4 vistas, 2 funciones y 20 reportes. Instalador sin operaciones de ejemplo. Se completaron {test_count} comprobaciones de integración en MAGISAUTO_ValidacionV2, creada por Diego en SSMS. Los datos ficticios están solo allí; no se modificaron la base del proyecto ni las bases de clase.

| Inciso | Implementación |
| --- | --- |
| A | Persona, Deudor, contactos y referencias; tres referencias completas al aprobar e identidad única según rol. |
| B | Garantia, Marca, Linea, VIN único, placa opcional, historial Depreciacion y un crédito vigente por vehículo. |
| C | Crédito, fiadores N:M, condiciones históricas, plan con desglose completo y resumen con totales guardados. |
| D | Vendedor/Agencia, comisión pactada por contrato sobre pagos efectivos y reversión al anular. |
| E | Cuotas mensuales, abonos, comprobante único, fecha/hora, monto depositado almacenado, medio y referencia. |
| Operaciones | Procedimientos de aplicación, búsquedas y 20 reportes; conexión desde API pendiente. |

El inciso E exige guardar el monto depositado: se mantiene Monto y se valida contra el desglose. Es redundancia controlada. ResumenCredito es un agregado contractual generado al aprobar; no tiene edición manual. No se afirma normalización física absoluta. Explicar al ingeniero la excepción de tabla derivada y la interpretación de anulación frente al borrado, además de confirmar el total neto recaudable.

## Relaciones financieras

Un crédito genera muchas cuotas y cada cuota recibe varios pagos. Un crédito tiene cero o un resumen (exactamente uno tras aprobar). CreditoFiador relaciona créditos y fiadores muchos a muchos. Un vehículo conserva su historial de créditos, con solo uno vigente, y múltiples valoraciones. Vendedor coloca múltiples créditos. Las vistas presentan cargos contractuales y resultados calculados; los procedimientos siguen siendo la vía de operación.

## Diccionario físico final

Extraído del SQL v2: columnas, tipos, nulabilidad y condiciones de columna. Las FK y CHECK de tabla completos, índices y módulos están en deployment_payload.sql y en el instalador.

'''
for name,body in tables:
    phase+=f'### {name}\n\n| Campo | Tipo y condiciones |\n| --- | --- |\n'
    for col,tail in re.findall(r'^\s*\[(\w+)\]\s+(.*?)(?:,)?$',body,re.M):
        phase+='| '+col+' | '+tail.rstrip(',')+' |\n'
    pk=re.search(r'PRIMARY KEY \(([^\n]+)\)',body).group(1)
    phase+=f'\nPK: {pk}.\n\n'
phase+='''## Validación y pendientes

- [x] Sintaxis y referencias del modelo sin errores.
- [x] Instalación real: 26 tablas, 150 procedimientos y 20 reportes.
- [x] Aprobación, plan/resumen, rechazo de doble aprobación.
- [x] Enganche mínimo, plazo y rechazo de vehículo con crédito activo.
- [x] Cuotas francesas, ajuste final, vencimientos enero/febrero/marzo y desglose.
- [x] Abonos, monto/desglose, comisión, rechazo de sobrepago y referencia bancaria.
- [x] Nuevos parámetros no alteran contratos aprobados.
- [x] Anulación preserva comprobante y saldos históricos; liquidación/reapertura.
- [x] Dos sesiones pagan la última cuota: solo una se acepta.
- [x] Ejecución de los 20 reportes.
- [x] Fórmulas: 75 planes y 1,000 repartos de centavos.
- [ ] Instalar v2 como base de trabajo de la aplicación.
- [ ] Conectar la API con cuenta limitada y probar llamadas desde C#.
- [ ] Interfaz y aceptación de usuarios.
- [ ] Confirmar las interpretaciones académicas pendientes con el ingeniero.

No se certifican todos los casos posibles, rendimiento masivo ni una interfaz no conectada. El paquete actualizado es database/v2/entrega; database/entrega-companero conserva v1 como antecedente.
'''
(repo/'docs'/'FASE_4_SQL_Implementado.md').write_text(phase,encoding='utf-8-sig')
hashes=[]
for file in sorted(out.iterdir()):
    if file.is_file() and file.name!='SHA256SUMS.txt':
        hashes.append(hashlib.sha256(file.read_bytes()).hexdigest().upper()+'  '+file.name)
(out/'SHA256SUMS.txt').write_text('\n'.join(hashes)+'\n',encoding='ascii')
target=Path(r'C:\Users\dfern\Documents\Codex\2026-09-12\hol\output\MAGISAUTO_SQL_Proyecto_v2.zip')
with zipfile.ZipFile(target,'w',zipfile.ZIP_DEFLATED) as z:
    for file in sorted(out.iterdir()):
        if file.is_file():z.write(file,file.name)
with zipfile.ZipFile(target) as z:
    assert z.testzip() is None
    assert len(z.namelist())==10
print(json.dumps({'tablas':len(tables),'pruebasIntegracion':test_count,'zip':str(target),'archivos':10}))
