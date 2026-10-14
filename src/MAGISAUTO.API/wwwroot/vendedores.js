"use strict";
const $ = id => document.getElementById(id);
const api = "/api/vendedores";
let editando = null;
let seleccionada = null;
let guardando = false;
let borrando = false;
let carga = 0;

function mensaje(id, texto, error = false) {
  const elemento = $(id);
  elemento.textContent = texto;
  elemento.classList.toggle("error", error);
  elemento.hidden = !texto;
}

async function solicitar(url, opciones = {}) {
  let respuesta;
  try { respuesta = await fetch(url, opciones); }
  catch { throw new Error("No se pudo conectar con la aplicación. Comprueba que siga abierta y vuelve a intentarlo."); }
  const datos = respuesta.status === 204 ? null : await respuesta.json();
  if (!respuesta.ok) {
    const validaciones = datos.errors ? Object.values(datos.errors).flat().join(" ") : null;
    throw new Error(validaciones || datos.detail || datos.title || "No se pudo completar la operación.");
  }
  return datos;
}

function pintar(vendedores) {
  $("filas").replaceChildren();
  for (const vendedor of vendedores) {
    const fila = document.createElement("tr");
    for (const valor of [vendedor.codigoVendedor, vendedor.codigoEmpleado, vendedor.nombreCompleto, vendedor.dpi, `${vendedor.nombreAgencia} · ${vendedor.region}`]) {
      const celda = document.createElement("td");
      celda.textContent = valor;
      fila.append(celda);
    }
    const celda = document.createElement("td");
    const acciones = document.createElement("div");
    acciones.className = "acciones";
    for (const [texto, clase, accion] of [["Editar", "editar-fila", () => abrirEditor(vendedor)], ["Eliminar", "eliminar-fila", () => abrirEliminar(vendedor)]]) {
      const boton = document.createElement("button");
      boton.type = "button";
      boton.className = clase;
      boton.textContent = texto;
      boton.setAttribute("aria-label", `${texto} ${vendedor.nombreCompleto}, código ${vendedor.codigoVendedor}`);
      boton.addEventListener("click", accion);
      acciones.append(boton);
    }
    celda.append(acciones); fila.append(celda); $("filas").append(fila);
  }
  $("contador").textContent = `${vendedores.length} ${vendedores.length === 1 ? "vendedor" : "vendedores"}`;
  $("vacio").textContent = "No hay vendedores que coincidan. Prueba otra búsqueda o agrega un vendedor.";
  $("vacio").hidden = vendedores.length !== 0;
}

async function cargar() {
  const turno = ++carga;
  const criterio = $("criterio").value.trim();
  $("resultados").setAttribute("aria-busy", "true");
  $("contador").textContent = "Cargando…";
  $("filas").replaceChildren();
  $("vacio").textContent = "Cargando vendedores…";
  $("vacio").hidden = false;
  try {
    const filtros = new URLSearchParams();
    if (criterio) filtros.set("criterio", criterio);
    if ($("filtro-agencia").value) filtros.set("codigoAgencia", $("filtro-agencia").value);
    const vendedores = await solicitar(api + (filtros.size ? `?${filtros}` : ""));
    if (turno === carga) pintar(vendedores);
  } catch (error) {
    if (turno === carga) {
      $("contador").textContent = "Sin conexión";
      $("vacio").textContent = "No se pudo cargar el catálogo. Pulsa Ver todas para intentarlo de nuevo.";
      mensaje("aviso", error.message, true);
    }
  } finally {
    if (turno === carga) $("resultados").setAttribute("aria-busy", "false");
  }
}

let agencias = [];
let aperturaEditor = 0;
async function cargarAgencias() {
  agencias = await solicitar("/api/catalogos/agencias");
  for (const id of ["agencia", "filtro-agencia"]) {
    const anterior = $(id).value;
    $(id).replaceChildren(new Option(id === "agencia" ? "Selecciona una agencia" : "Todas las agencias", ""));
    for (const a of agencias) $(id).append(new Option(`${a.nombre} · ${a.region}`, a.codigoAgencia));
    $(id).value = anterior;
  }
}
async function abrirEditor(vendedor = null) {
  const apertura = ++aperturaEditor;
  editando = vendedor;
  $("formulario").reset();
  $("codigo").value = vendedor?.codigoVendedor ?? "";
  $("empleado").value = vendedor?.codigoEmpleado ?? "";
  $("dpi").value = vendedor?.dpi ?? "";
  $("dpi").readOnly = !!vendedor;
  $("nombre").value = vendedor?.primerNombre ?? "";
  $("segundo-nombre").value = vendedor?.segundoNombre ?? "";
  $("apellido").value = vendedor?.primerApellido ?? "";
  $("segundo-apellido").value = vendedor?.segundoApellido ?? "";
  for (const id of ["empleado", "nombre", "apellido"]) $(id).setCustomValidity("");
  $("titulo-editor").textContent = vendedor ? "Editar vendedor" : "Agregar vendedor";
  $("ayuda-editor").textContent = vendedor ? "Actualiza los nombres, código de empleado y agencia; se conserva su identidad." : "Completa los datos del vendedor; el código interno se asigna al guardar.";
  mensaje("error-editor", "");
  $("guardar").disabled = true;
  $("editor").showModal();
  $("empleado").focus();
  try {
    await cargarAgencias();
    if (apertura !== aperturaEditor || !$("editor").open) return;
    $("agencia").value = vendedor?.codigoAgencia ?? "";
    if (!agencias.length) mensaje("error-editor", "Primero registra una agencia en el catálogo Agencias.", true);
    $("guardar").disabled = agencias.length === 0;
  } catch (error) {
    if (apertura === aperturaEditor && $("editor").open)
      mensaje("error-editor", error.message + " Cierra y vuelve a abrir el formulario para reintentar.", true);
  }
}
for (const id of ["empleado", "nombre", "apellido"]) $(id).addEventListener("input", () => $(id).setCustomValidity(""));
$("formulario").addEventListener("submit", async evento => {
  evento.preventDefault();
  if (guardando) return;
  for (const id of ["empleado", "nombre", "apellido"]) {
    if (!$(id).value.trim()) { $(id).setCustomValidity("Completa este campo sin usar solo espacios."); $(id).reportValidity(); return; }
  }
  const datos = {
    codigoEmpleado: $("empleado").value.trim(), dpi: $("dpi").value,
    primerNombre: $("nombre").value.trim(), segundoNombre: $("segundo-nombre").value.trim() || null,
    primerApellido: $("apellido").value.trim(), segundoApellido: $("segundo-apellido").value.trim() || null,
    codigoAgencia: Number($("agencia").value)
  };
  guardando = true;
  $("guardar").disabled = $("cancelar").disabled = true;
  $("guardar").textContent = "Guardando…";
  mensaje("error-editor", "");
  try {
    await solicitar(editando ? `${api}/${editando.codigoVendedor}` : api, {
      method: editando ? "PUT" : "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify(datos)
    });
    $("editor").close();
    mensaje("aviso", editando ? "Vendedor actualizado correctamente." : "Vendedor agregado correctamente.");
    $("criterio").value = ""; $("filtro-agencia").value = "";
    await cargar();
    $("nueva").focus();
  } catch (error) { mensaje("error-editor", error.message, true); }
  finally { guardando = false; $("guardar").disabled = $("cancelar").disabled = false; $("guardar").textContent = "Guardar vendedor"; }
});

function abrirEliminar(vendedor) {
  seleccionada = vendedor;
  $("detalle-eliminar").textContent = `${vendedor.nombreCompleto} · Código ${vendedor.codigoVendedor}`;
  mensaje("error-eliminar", "");
  $("confirmacion").showModal();
  $("conservar").focus();
}

$("eliminar").addEventListener("click", async () => {
  if (borrando) return;
  borrando = true;
  $("eliminar").disabled = $("conservar").disabled = true;
  $("eliminar").textContent = "Eliminando…";
  mensaje("error-eliminar", "");
  try {
    await solicitar(`${api}/${seleccionada.codigoVendedor}`, { method: "DELETE" });
    $("confirmacion").close();
    mensaje("aviso", "Vendedor eliminado correctamente.");
    await cargar();
    $("nueva").focus();
  } catch (error) { mensaje("error-eliminar", error.message, true); }
  finally { borrando = false; $("eliminar").disabled = $("conservar").disabled = false; $("eliminar").textContent = "Eliminar vendedor"; }
});

$("editor").addEventListener("cancel", evento => { if (guardando) evento.preventDefault(); });
$("confirmacion").addEventListener("cancel", evento => { if (borrando) evento.preventDefault(); });
$("cancelar").addEventListener("click", () => $("editor").close());
$("conservar").addEventListener("click", () => $("confirmacion").close());
$("nueva").addEventListener("click", () => abrirEditor());
$("busqueda").addEventListener("submit", evento => { evento.preventDefault(); mensaje("aviso", ""); cargar(); });
$("todas").addEventListener("click", () => { $("criterio").value = ""; $("filtro-agencia").value = ""; mensaje("aviso", ""); cargar(); });
$("filtro-agencia").addEventListener("change", () => { mensaje("aviso", ""); cargar(); });
cargarAgencias().catch(error => mensaje("aviso", error.message, true));
cargar();
