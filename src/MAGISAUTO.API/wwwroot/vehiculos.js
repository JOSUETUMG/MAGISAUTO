"use strict";
const $ = id => document.getElementById(id);
const api = "/api/vehiculos";
let catalogos, editando = null, seleccionado = null, guardando = false, borrando = false;
let carga = 0, apertura = 0, vehiculoValoraciones = null, edicionValoracion = null, cargandoValoraciones = 0, guardandoValoracion = false;
function mensaje(id, texto, error = false) { $(id).textContent = texto; $(id).hidden = !texto; $(id).classList.toggle("error", error); }
async function solicitar(url, opciones = {}) {
  let r;
  try { r = await fetch(url, opciones); } catch { throw new Error("No se pudo conectar. Comprueba que la aplicación esté abierta y vuelve a intentar."); }
  const datos = r.status === 204 ? null : await r.json();
  if (!r.ok) throw new Error(datos.errors ? Object.values(datos.errors).flat().join(" ") : datos.detail || datos.title || "No se pudo completar la operación.");
  return datos;
}
function texto(tag, contenido) { const el = document.createElement(tag); el.textContent = contenido; return el; }
function dinero(valor) {
  // El importe viaja como texto para conservar todos los centavos de decimal(18,2).
  const [entero, centavos = ""] = String(valor).split(".");
  return `Q${entero.replace(/\B(?=(\d{3})+(?!\d))/g, ",")}.${centavos.padEnd(2, "0")}`;
}
function porcentaje(valor) { return `${Number(valor)}%`; }
function fecha(valor) { const [a, m, d] = String(valor).slice(0, 10).split("-"); return a && m && d ? `${d}/${m}/${a}` : "Sin fecha"; }
function opciones(id, lista, clave, encabezado) {
  $(id).replaceChildren(new Option(encabezado, ""));
  for (const item of lista) $(id).append(new Option(item.descripcion, item[clave]));
}
function lineas(valor = "") {
  const lista = catalogos.lineas.filter(l => l.codigoMarca === Number($("marca").value));
  opciones("linea", lista, "codigoLinea", "Selecciona una línea"); $("linea").value = valor;
  $("linea").disabled = lista.length === 0;
  $("ayuda-linea").textContent = !$("marca").value ? "Primero selecciona una marca." : lista.length ? "Solo se muestran líneas de esta marca." : "Esta marca no tiene líneas. Registra una en Líneas de vehículos antes de guardar.";
  $("guardar").disabled = guardando || !!editando?.tieneHistorialContractual || !lista.length || !catalogos.tiposGarantia.length;
}
async function cargarMarcas() {
  const cat = await solicitar(`${api}/catalogos`);
  const anterior = $("filtro-marca").value;
  opciones("filtro-marca", cat.marcas, "codigoMarca", "Todas las marcas"); $("filtro-marca").value = anterior;
}
async function cargar() {
  const turno = ++carga; $("resultados").setAttribute("aria-busy", "true");
  $("filas").replaceChildren(); $("contador").textContent = "Cargando…"; $("vacio").hidden = false; $("vacio").textContent = "Cargando vehículos…";
  try {
    const filtro = new URLSearchParams();
    if ($("criterio").value.trim()) filtro.set("criterio", $("criterio").value.trim());
    if ($("filtro-marca").value) filtro.set("codigoMarca", $("filtro-marca").value);
    const vehiculos = await solicitar(api + (filtro.size ? `?${filtro}` : ""));
    if (turno !== carga) return;
    for (const v of vehiculos) {
      const fila = document.createElement("tr");
      fila.append(texto("td", v.codigoGarantia));
      const detalle = texto("td", `${v.marca} · ${v.linea}`); detalle.append(texto("small", `${v.anio} · Nuevo de agencia`));
      if (v.tieneHistorialContractual) detalle.append(texto("small", "Historial contractual · datos protegidos"));
      fila.append(detalle, texto("td", v.vin), texto("td", dinero(v.valorAgencia)), texto("td", v.placa || "Sin placa"));
      const celda = document.createElement("td"), acciones = document.createElement("div"); acciones.className = "acciones";
      for (const [nombre, clase, accion] of [[v.tieneHistorialContractual ? "Ver datos" : "Editar", "editar-fila", () => abrir(v.codigoGarantia)], [`Valoraciones (${v.valoracionesRegistradas})`, "secundario", () => abrirValoraciones(v)], ["Eliminar", "eliminar-fila", () => eliminar(v)]]) {
        const b = texto("button", nombre); b.type = "button"; b.className = clase; b.setAttribute("aria-label", `${nombre} vehículo ${v.codigoGarantia}`); b.addEventListener("click", accion); acciones.append(b);
      }
      celda.append(acciones); fila.append(celda); $("filas").append(fila);
    }
    $("contador").textContent = `${vehiculos.length} ${vehiculos.length === 1 ? "vehículo" : "vehículos"}`;
    $("vacio").hidden = vehiculos.length > 0; $("vacio").textContent = "No hay vehículos que coincidan. Puedes agregar uno o cambiar la búsqueda.";
  } catch (e) { if (turno === carga) { mensaje("aviso", e.message, true); $("contador").textContent = "Sin conexión"; $("vacio").textContent = "No se pudo cargar el inventario. Pulsa Ver todos para reintentar."; } }
  finally { if (turno === carga) $("resultados").setAttribute("aria-busy", "false"); }
}
async function cargarValoraciones() {
  if (!vehiculoValoraciones) return;
  const turno = ++cargandoValoraciones; $("resultado-valoraciones").setAttribute("aria-busy", "true"); $("filas-valoraciones").replaceChildren();
  $("vacio-valoraciones").hidden = false; $("vacio-valoraciones").textContent = "Cargando valoraciones…";
  try {
    const filtro = new URLSearchParams({ codigoGarantia: vehiculoValoraciones.codigoGarantia });
    if ($("criterio-valoracion").value.trim()) filtro.set("criterio", $("criterio-valoracion").value.trim());
    const valoraciones = await solicitar(`/api/valoraciones?${filtro}`);
    if (turno !== cargandoValoraciones || !$("historial-valoraciones").open) return;
    for (const v of valoraciones) {
      const fila = document.createElement("tr");
      fila.append(texto("td", fecha(v.fechaValoracion)), texto("td", dinero(v.valorOriginal)), texto("td", porcentaje(v.porcentaje)), texto("td", dinero(v.valorDepreciado)), texto("td", v.observacion));
      const celda = document.createElement("td"), acciones = document.createElement("div"); acciones.className = "acciones";
      if (v.protegidaPorContrato) acciones.append(texto("small", "Historial protegido"));
      else {
        for (const [nombre, clase, accion] of [["Editar", "editar-fila", () => abrirEditorValoracion(v)], ["Eliminar", "eliminar-fila", () => eliminarValoracion(v)]]) {
          const b = texto("button", nombre); b.type = "button"; b.className = clase; b.addEventListener("click", accion); acciones.append(b);
        }
      }
      celda.append(acciones); fila.append(celda); $("filas-valoraciones").append(fila);
    }
    $("vacio-valoraciones").hidden = valoraciones.length > 0; $("vacio-valoraciones").textContent = "No hay valoraciones para estos filtros.";
  } catch (e) { if (turno === cargandoValoraciones) { mensaje("aviso-valoraciones", e.message, true); $("vacio-valoraciones").textContent = "No se pudo cargar el historial."; } }
  finally { if (turno === cargandoValoraciones) $("resultado-valoraciones").setAttribute("aria-busy", "false"); }
}
function abrirValoraciones(vehiculo) {
  vehiculoValoraciones = vehiculo; $("criterio-valoracion").value = ""; mensaje("aviso-valoraciones", "");
  $("titulo-valoraciones").textContent = `Valoraciones del vehículo ${vehiculo.codigoGarantia}`;
  $("detalle-valoraciones").textContent = `${vehiculo.marca} · ${vehiculo.linea} · VIN ${vehiculo.vin}`;
  $("nueva-valoracion").disabled = !vehiculo.tieneHistorialContractual;
  if (!vehiculo.tieneHistorialContractual) mensaje("aviso-valoraciones", "La valoración inicial se genera al aprobar el crédito. Aún no hay un contrato aprobado para este vehículo.");
  $("historial-valoraciones").showModal(); cargarValoraciones();
}
function abrirEditorValoracion(valoracion = null) {
  edicionValoracion = valoracion; $("formulario-valoracion").reset(); mensaje("error-valoracion", "");
  $("valoracion-garantia").value = valoracion?.codigoGarantia ?? vehiculoValoraciones.codigoGarantia;
  $("fecha-valoracion").value = valoracion?.fechaValoracion?.slice(0, 10) ?? "";
  $("valor-original").value = valoracion?.valorOriginal ?? ""; $("porcentaje-valoracion").value = valoracion?.porcentaje ?? "";
  $("observacion-valoracion").value = valoracion?.observacion ?? "";
  $("titulo-editor-valoracion").textContent = valoracion ? "Editar valoración" : "Registrar valoración";
  $("guardar-valoracion").textContent = valoracion ? "Guardar cambios" : "Guardar valoración";
  $("editor-valoracion").showModal(); $("fecha-valoracion").focus();
}
async function eliminarValoracion(valoracion) {
  if (!window.confirm(`¿Eliminar la valoración del ${fecha(valoracion.fechaValoracion)}?`)) return;
  mensaje("aviso-valoraciones", "");
  try { await solicitar(`/api/valoraciones/${valoracion.codigoDepreciacion}`, { method: "DELETE" }); mensaje("aviso-valoraciones", "Valoración eliminada correctamente."); await cargarValoraciones(); await cargar(); }
  catch (e) { mensaje("aviso-valoraciones", e.message, true); }
}
async function abrir(codigo = null) {
  const turno = ++apertura; editando = null; $("formulario").reset(); mensaje("error-editor", "");
  $("titulo-editor").textContent = codigo ? "Consultar vehículo" : "Agregar vehículo";
  $("campos").disabled = $("guardar").disabled = true; $("ayuda-editor").textContent = "Cargando datos…";
  $("editor").showModal();
  try {
    const [cat, v] = await Promise.all([solicitar(`${api}/catalogos`), codigo ? solicitar(`${api}/${codigo}`) : Promise.resolve(null)]);
    if (turno !== apertura || !$("editor").open) return;
    catalogos = cat; editando = v;
    opciones("marca", cat.marcas, "codigoMarca", "Selecciona una marca");
    opciones("tipo", cat.tiposGarantia, "codigoTipoGarantia", "Selecciona un tipo");
    $("codigo").value = v?.codigoGarantia ?? ""; $("vin").value = v?.vin ?? ""; $("marca").value = v?.codigoMarca ?? "";
    $("anio").value = v?.anio ?? ""; $("precio").value = v?.valorAgencia ?? ""; $("placa").value = v?.placa ?? "";
    $("tipo").value = v?.codigoTipoGarantia ?? (cat.tiposGarantia.length === 1 ? cat.tiposGarantia[0].codigoTipoGarantia : "");
    $("campos").disabled = !!v?.tieneHistorialContractual; lineas(v?.codigoLinea ?? "");
    $("titulo-editor").textContent = v?.tieneHistorialContractual ? "Datos del vehículo" : v ? "Editar vehículo" : "Agregar vehículo";
    $("ayuda-editor").textContent = v?.tieneHistorialContractual ? "Este vehículo tiene historial de un crédito aprobado. Sus datos están protegidos, incluida la placa." : "El código interno se conserva. Completa el VIN, marca, línea, año y precio al contado.";
    if (!cat.marcas.length || !cat.tiposGarantia.length) mensaje("error-editor", "Faltan marcas o tipos de garantía en los catálogos. Completa los catálogos antes de registrar el vehículo.", true);
    if (!v?.tieneHistorialContractual) $("vin").focus();
  } catch (e) { if (turno === apertura && $("editor").open) mensaje("error-editor", e.message + " Cierra y vuelve a abrir para reintentar.", true); }
}
$("vin").addEventListener("input", () => { $("vin").value = $("vin").value.toUpperCase(); });
$("marca").addEventListener("change", () => lineas());
$("formulario").addEventListener("submit", async e => {
  e.preventDefault(); if (guardando || $("guardar").disabled) return;
  const datos = { vin: $("vin").value.trim().toUpperCase(), codigoMarca: Number($("marca").value), codigoLinea: Number($("linea").value), anio: Number($("anio").value), valorAgencia: $("precio").value.trim(), placa: $("placa").value.trim() || null, codigoTipoGarantia: Number($("tipo").value) };
  guardando = true; $("nuevo").disabled = $("campos").disabled = $("guardar").disabled = $("cancelar").disabled = true; $("guardar").textContent = "Guardando…"; mensaje("error-editor", "");
  try {
    await solicitar(editando ? `${api}/${editando.codigoGarantia}` : api, { method: editando ? "PUT" : "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(datos) });
    $("editor").close(); mensaje("aviso", editando ? "Vehículo actualizado correctamente." : "Vehículo agregado correctamente.");
    $("criterio").value = $("filtro-marca").value = ""; await cargar(); $("nuevo").focus();
  } catch (error) { mensaje("error-editor", error.message, true); $("error-editor").scrollIntoView({ block: "nearest" }); }
  finally { guardando = false; $("nuevo").disabled = $("campos").disabled = $("cancelar").disabled = false; lineas($("linea").value); $("guardar").textContent = "Guardar vehículo"; }
});
function eliminar(v) {
  seleccionado = v; $("detalle-eliminar").textContent = `${v.marca} ${v.linea} · VIN ${v.vin} · Código ${v.codigoGarantia}`;
  mensaje("error-eliminar", ""); $("confirmacion").showModal(); $("conservar").focus();
}
$("eliminar").addEventListener("click", async () => {
  if (borrando) return; borrando = true; $("eliminar").disabled = $("conservar").disabled = true; mensaje("error-eliminar", "");
  try { await solicitar(`${api}/${seleccionado.codigoGarantia}`, { method: "DELETE" }); $("confirmacion").close(); mensaje("aviso", "Vehículo eliminado correctamente."); await cargar(); }
  catch (e) { mensaje("error-eliminar", e.message, true); }
  finally { borrando = false; $("eliminar").disabled = $("conservar").disabled = false; }
});
$("editor").addEventListener("cancel", e => { if (guardando) e.preventDefault(); else ++apertura; });
$("confirmacion").addEventListener("cancel", e => { if (borrando) e.preventDefault(); });
$("cancelar").addEventListener("click", () => { ++apertura; $("editor").close(); });
$("conservar").addEventListener("click", () => $("confirmacion").close());
$("busqueda-valoraciones").addEventListener("submit", e => { e.preventDefault(); mensaje("aviso-valoraciones", ""); cargarValoraciones(); });
$("todas-valoraciones").addEventListener("click", () => { $("criterio-valoracion").value = ""; mensaje("aviso-valoraciones", ""); cargarValoraciones(); });
$("nueva-valoracion").addEventListener("click", () => abrirEditorValoracion());
$("cerrar-valoraciones").addEventListener("click", () => { ++cargandoValoraciones; $("historial-valoraciones").close(); });
$("formulario-valoracion").addEventListener("submit", async e => {
  e.preventDefault(); if (guardandoValoracion) return;
  const datos = { codigoGarantia: Number($("valoracion-garantia").value), fechaValoracion: $("fecha-valoracion").value, valorOriginal: $("valor-original").value.trim(), porcentaje: $("porcentaje-valoracion").value.trim(), observacion: $("observacion-valoracion").value.trim() };
  guardandoValoracion = true; $("campos-valoracion").disabled = $("guardar-valoracion").disabled = $("cancelar-valoracion").disabled = true; mensaje("error-valoracion", "");
  try {
    const url = edicionValoracion ? `/api/valoraciones/${edicionValoracion.codigoDepreciacion}` : "/api/valoraciones";
    await solicitar(url, { method: edicionValoracion ? "PUT" : "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(datos) });
    $("editor-valoracion").close(); mensaje("aviso-valoraciones", edicionValoracion ? "Valoración actualizada correctamente." : "Valoración registrada correctamente."); await cargarValoraciones(); await cargar();
  } catch (error) { mensaje("error-valoracion", error.message, true); }
  finally { guardandoValoracion = false; $("campos-valoracion").disabled = $("guardar-valoracion").disabled = $("cancelar-valoracion").disabled = false; }
});
$("cancelar-valoracion").addEventListener("click", () => $("editor-valoracion").close());
$("editor-valoracion").addEventListener("cancel", e => { if (guardandoValoracion) e.preventDefault(); });
$("historial-valoraciones").addEventListener("cancel", () => { ++cargandoValoraciones; });
$("nuevo").addEventListener("click", () => abrir());
$("busqueda").addEventListener("submit", e => { e.preventDefault(); mensaje("aviso", ""); cargar(); });
$("todos").addEventListener("click", () => { $("criterio").value = $("filtro-marca").value = ""; mensaje("aviso", ""); cargarMarcas().catch(e => mensaje("aviso", e.message, true)); cargar(); });
$("filtro-marca").addEventListener("change", () => { mensaje("aviso", ""); cargar(); });
cargarMarcas().catch(e => mensaje("aviso", e.message, true));
cargar();
