"use strict";
const $ = id => document.getElementById(id);
const api = "/api/vehiculos";
let catalogos, editando = null, seleccionado = null, guardando = false, borrando = false;
let carga = 0, apertura = 0;
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
      for (const [nombre, clase, accion] of [[v.tieneHistorialContractual ? "Ver datos" : "Editar", "editar-fila", () => abrir(v.codigoGarantia)], ["Eliminar", "eliminar-fila", () => eliminar(v)]]) {
        const b = texto("button", nombre); b.type = "button"; b.className = clase; b.setAttribute("aria-label", `${nombre} vehículo ${v.codigoGarantia}`); b.addEventListener("click", accion); acciones.append(b);
      }
      celda.append(acciones); fila.append(celda); $("filas").append(fila);
    }
    $("contador").textContent = `${vehiculos.length} ${vehiculos.length === 1 ? "vehículo" : "vehículos"}`;
    $("vacio").hidden = vehiculos.length > 0; $("vacio").textContent = "No hay vehículos que coincidan. Puedes agregar uno o cambiar la búsqueda.";
  } catch (e) { if (turno === carga) { mensaje("aviso", e.message, true); $("contador").textContent = "Sin conexión"; $("vacio").textContent = "No se pudo cargar el inventario. Pulsa Ver todos para reintentar."; } }
  finally { if (turno === carga) $("resultados").setAttribute("aria-busy", "false"); }
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
$("nuevo").addEventListener("click", () => abrir());
$("busqueda").addEventListener("submit", e => { e.preventDefault(); mensaje("aviso", ""); cargar(); });
$("todos").addEventListener("click", () => { $("criterio").value = $("filtro-marca").value = ""; mensaje("aviso", ""); cargarMarcas().catch(e => mensaje("aviso", e.message, true)); cargar(); });
$("filtro-marca").addEventListener("change", () => { mensaje("aviso", ""); cargar(); });
cargarMarcas().catch(e => mensaje("aviso", e.message, true));
cargar();
