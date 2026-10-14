"use strict";
const $ = id => document.getElementById(id);
const api = "/api/fiadores";
let catalogos, ficha, codigo = null, guardando = false, borrando = false, seleccion = null;
let carga = 0, apertura = 0, contadorCampos = 0;
let pendienteRecarga = false;
const vacia = () => ({ primerNombre: "", segundoNombre: null, primerApellido: "", segundoApellido: null, telefonos: [], direcciones: [] });

function elemento(tag, texto, clase) {
  const el = document.createElement(tag);
  if (texto !== undefined) el.textContent = texto;
  if (clase) el.className = clase;
  return el;
}
function aviso(id, texto, error = false) { $(id).textContent = texto; $(id).hidden = !texto; $(id).classList.toggle("error", error); }
async function solicitar(url, opciones = {}) {
  let r;
  try { r = await fetch(url, opciones); } catch { throw new Error("No se pudo conectar. Comprueba que la aplicación esté abierta y vuelve a intentar."); }
  const datos = r.status === 204 ? null : await r.json();
  if (!r.ok) throw new Error(datos.errors ? Object.values(datos.errors).flat().join(" ") : datos.detail || datos.title || "No se pudo completar la operación.");
  return datos;
}
function boton(texto, accion, clase = "secundario") {
  const b = elemento("button", texto, clase); b.type = "button"; b.addEventListener("click", accion); return b;
}
function campo(padre, etiqueta, obj, clave, { requerido = false, max = 64, tipo = "text", soloLectura = false, patron } = {}) {
  const div = elemento("div"), input = document.createElement("input"), id = `campo-${++contadorCampos}`;
  const label = elemento("label", etiqueta); label.htmlFor = id;
  input.id = id; input.type = tipo; input.required = requerido; input.maxLength = max; input.readOnly = soloLectura;
  input.autocomplete = "off"; input.value = obj[clave] ?? "";
  if (patron) { input.pattern = patron; input.inputMode = "numeric"; }
  input.addEventListener("input", () => {
    input.setCustomValidity("");
    obj[clave] = input.value || null;
    if (requerido && !input.value.trim()) input.setCustomValidity("Completa este campo sin usar solo espacios.");
  });
  div.append(label, input); padre.append(div); return input;
}
function selector(padre, etiqueta, obj, clave, opciones, cambio) {
  const div = elemento("div"), select = document.createElement("select"), id = `campo-${++contadorCampos}`;
  const label = elemento("label", etiqueta); label.htmlFor = id; select.id = id; select.required = true;
  select.append(new Option("Selecciona una opción", ""));
  for (const [valor, texto] of opciones) select.append(new Option(texto, valor));
  select.value = obj[clave] || "";
  select.addEventListener("change", () => { obj[clave] = Number(select.value); if (cambio) cambio(); });
  div.append(label, select); padre.append(div); return select;
}
const opciones = (tabla, key) => catalogos[tabla].map(x => [x[key], x.descripcion]);

function telefonos(padre, lista, bloqueado = false) {
  padre.replaceChildren();
  if (!lista.length) padre.append(elemento("p", "Todavía no hay teléfonos."));
  lista.forEach((t, i) => {
    const card = elemento("fieldset", undefined, "tarjeta-contacto"); card.disabled = bloqueado;
    card.append(elemento("h3", `Teléfono ${i + 1}`)); const grid = elemento("div", undefined, "rejilla");
    selector(grid, "Tipo de teléfono", t, "codigoTipoTelefono", opciones("TipoTelefono", "codigoTipoTelefono"));
    const numero = campo(grid, "Número (mínimo 8 caracteres)", t, "numero", { requerido: true, max: 32, tipo: "tel" }); numero.minLength = 8;
    card.append(grid, boton("Quitar teléfono", () => { lista.splice(i, 1); telefonos(padre, lista, bloqueado); })); padre.append(card);
  });
}
function direcciones(padre, lista, bloqueado = false) {
  padre.replaceChildren();
  if (!lista.length) padre.append(elemento("p", "Todavía no hay direcciones."));
  lista.forEach((d, i) => {
    const card = elemento("fieldset", undefined, "tarjeta-contacto"); card.disabled = bloqueado;
    card.append(elemento("h3", `Dirección ${i + 1}`)); const grid = elemento("div", undefined, "rejilla");
    selector(grid, "Tipo de dirección", d, "codigoTipoDireccion", opciones("TipoDireccion", "codigoTipoDireccion"));
    let municipio;
    selector(grid, "Departamento", d, "codigoDepartamento", opciones("Departamento", "codigoDepartamento"), () => {
      d.codigoMunicipio = 0; cargarMunicipios();
    });
    municipio = selector(grid, "Municipio", d, "codigoMunicipio", []);
    function cargarMunicipios() {
      municipio.replaceChildren(new Option("Selecciona un municipio", ""));
      for (const m of catalogos.Municipio.filter(m => m.codigoDepartamento === d.codigoDepartamento)) municipio.append(new Option(m.descripcion, m.codigoMunicipio));
      municipio.value = d.codigoMunicipio || "";
    }
    cargarMunicipios();
    campo(grid, "Dirección completa", d, "detalle", { requerido: true, max: 300 });
    card.append(grid, boton("Quitar dirección", () => { lista.splice(i, 1); direcciones(padre, lista, bloqueado); })); padre.append(card);
  });
}
function nombres(padre, p) {
  campo(padre, "Primer nombre *", p, "primerNombre", { requerido: true });
  campo(padre, "Segundo nombre", p, "segundoNombre");
  campo(padre, "Primer apellido *", p, "primerApellido", { requerido: true });
  campo(padre, "Segundo apellido", p, "segundoApellido");
}
function estado() {
  $("estado-expediente").replaceChildren();
  if (!codigo) { $("estado-expediente").append(elemento("p", "Puedes guardar los datos básicos y completar después teléfonos y direcciones.")); return; }
  const faltantes = ficha.faltantes || [];
  $("estado-expediente").append(elemento("strong", faltantes.length ? "Expediente guardado incompleto" : "Datos de contacto completos para revisión"));
  const lista = elemento("ul"); for (const f of faltantes) lista.append(elemento("li", f)); $("estado-expediente").append(lista);
  $("estado-expediente").append(elemento("p", "Este estado corresponde a la última versión guardada. Registrar un fiador no lo asigna a un crédito ni aprueba el financiamiento."));
}
async function abrir(id = null) {
  const turno = ++apertura; $("nuevo").disabled = true; aviso("aviso", "");
  try {
    const [cat, data] = await Promise.all([solicitar(`${api}/catalogos`), id ? solicitar(`${api}/${id}`) : Promise.resolve({ ...vacia(), dpi: "", nit: "", correoElectronico: "" })]);
    if (turno !== apertura) return;
    catalogos = cat; ficha = data; codigo = id; pendienteRecarga = false;
    $("datos-basicos").replaceChildren(); const grid = $("datos-basicos");
    campo(grid, "DPI *", ficha, "dpi", { requerido: true, max: 13, patron: "[0-9]{13}", soloLectura: !!id });
    campo(grid, "NIT *", ficha, "nit", { requerido: true, max: 20 }); nombres(grid, ficha);
    campo(grid, "Correo electrónico *", ficha, "correoElectronico", { requerido: true, max: 254, tipo: "email" });
    telefonos($("telefonos"), ficha.telefonos); direcciones($("direcciones"), ficha.direcciones); estado();
    $("titulo-expediente").textContent = id ? `Expediente del fiador ${id}` : "Nuevo fiador";
    $("resumen-expediente").textContent = id ? ficha.nombreCompleto : "Guarda primero los datos básicos o completa todo el expediente.";
    aviso("error-editor", ""); $("expediente").hidden = false; $("listado").hidden = true; $("titulo-expediente").focus();
    if (!guardando) { $("campos-expediente").disabled = false; $("guardar").disabled = false; $("guardar").textContent = "Guardar expediente"; }
    return true;
  } catch (e) { aviso("aviso", e.message, true); return false; }
  finally { $("nuevo").disabled = false; }
}
async function cargar() {
  const turno = ++carga, criterio = $("criterio").value.trim(); $("resultados").setAttribute("aria-busy", "true");
  $("filas").replaceChildren(); $("contador").textContent = "Cargando…"; $("vacio").textContent = "Cargando fiadores…"; $("vacio").hidden = false;
  try {
    const fiadores = await solicitar(api + (criterio ? `?criterio=${encodeURIComponent(criterio)}` : ""));
    if (turno !== carga) return;
    for (const c of fiadores) {
      const tr = elemento("tr");
      for (const v of [c.codigoFiador, c.nombreCompleto, `${c.dpi} / ${c.nit}`, c.faltantes.length ? "Teléfono pendiente" : "Datos completos para revisión"]) tr.append(elemento("td", v));
      const td = elemento("td"), acciones = elemento("div", undefined, "acciones");
      acciones.append(boton("Abrir expediente", () => abrir(c.codigoFiador), "editar-fila"), boton("Eliminar", () => {
        seleccion = c; aviso("error-eliminar", ""); $("detalle-eliminar").textContent = `${c.nombreCompleto} · Código ${c.codigoFiador}`; $("confirmacion").showModal(); $("conservar").focus();
      }, "eliminar-fila")); td.append(acciones); tr.append(td); $("filas").append(tr);
    }
    $("contador").textContent = `${fiadores.length} ${fiadores.length === 1 ? "fiador" : "fiadores"}`;
    $("vacio").hidden = fiadores.length > 0; $("vacio").textContent = "No hay fiadores que coincidan. Puedes agregar uno o cambiar la búsqueda.";
  } catch (e) { if (turno === carga) { aviso("aviso", e.message, true); $("contador").textContent = "Sin conexión"; $("vacio").textContent = "No se pudo cargar el listado. Pulsa Ver todos para reintentar."; } }
  finally { if (turno === carga) $("resultados").setAttribute("aria-busy", "false"); }
}
$("nuevo").addEventListener("click", () => abrir());
$("volver").addEventListener("click", () => { ++apertura; $("expediente").hidden = true; $("listado").hidden = false; cargar(); });
$("busqueda").addEventListener("submit", e => { e.preventDefault(); aviso("aviso", ""); cargar(); });
$("todos").addEventListener("click", () => { $("criterio").value = ""; aviso("aviso", ""); cargar(); });
$("agregar-telefono").addEventListener("click", () => { ficha.telefonos.push({ correlativo: 0, codigoTipoTelefono: 0, numero: "" }); telefonos($("telefonos"), ficha.telefonos); });
$("agregar-direccion").addEventListener("click", () => { ficha.direcciones.push({ correlativo: 0, codigoTipoDireccion: 0, codigoDepartamento: 0, codigoMunicipio: 0, detalle: "" }); direcciones($("direcciones"), ficha.direcciones); });
$("formulario").addEventListener("submit", async e => {
  e.preventDefault(); if (guardando) return;
  guardando = true; $("campos-expediente").disabled = $("guardar").disabled = $("volver").disabled = true; $("guardar").textContent = "Guardando…"; aviso("error-editor", "");
  try {
    if (pendienteRecarga) {
      pendienteRecarga = !await abrir(codigo);
      if (pendienteRecarga) aviso("error-editor", "La operación anterior se guardó. Recarga el expediente antes de hacer otros cambios.", true);
      return;
    }
    const respuesta = await solicitar(codigo ? `${api}/${codigo}` : api, { method: codigo ? "PUT" : "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(ficha) });
    const id = codigo || respuesta.codigoFiador;
    codigo = id;
    pendienteRecarga = !await abrir(id);
    if (pendienteRecarga) aviso("error-editor", "El expediente se guardó, pero no se pudo cargar su nueva versión. Pulsa Recargar expediente antes de continuar.", true);
    else aviso("aviso", "Expediente guardado correctamente. Revisa el estado y los datos que aún falten.");
  } catch (error) { aviso("error-editor", error.message, true); $("error-editor").scrollIntoView({ block: "center" }); }
  finally { guardando = false; $("campos-expediente").disabled = pendienteRecarga; $("guardar").disabled = $("volver").disabled = false; $("guardar").textContent = pendienteRecarga ? "Recargar expediente" : "Guardar expediente"; }
});
$("conservar").addEventListener("click", () => $("confirmacion").close());
$("confirmacion").addEventListener("cancel", e => { if (borrando) e.preventDefault(); });
$("eliminar").addEventListener("click", async () => {
  if (borrando) return; borrando = true; $("eliminar").disabled = $("conservar").disabled = true;
  try { await solicitar(`${api}/${seleccion.codigoFiador}`, { method: "DELETE" }); $("confirmacion").close(); aviso("aviso", "Registro de fiador eliminado. La ficha personal se conserva."); await cargar(); }
  catch (e) { aviso("error-eliminar", e.message, true); }
  finally { borrando = false; $("eliminar").disabled = $("conservar").disabled = false; }
});
cargar();
