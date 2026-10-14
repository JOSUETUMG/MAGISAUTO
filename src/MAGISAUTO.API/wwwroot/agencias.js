"use strict";
const $ = id => document.getElementById(id);
const api = "/api/catalogos/agencias";
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

function pintar(agencias) {
  $("filas").replaceChildren();
  for (const agencia of agencias) {
    const fila = document.createElement("tr");
    for (const valor of [agencia.codigoAgencia, agencia.nombre, agencia.region]) {
      const celda = document.createElement("td");
      celda.textContent = valor;
      fila.append(celda);
    }
    const celda = document.createElement("td");
    const acciones = document.createElement("div");
    acciones.className = "acciones";
    for (const [texto, clase, accion] of [["Editar", "editar-fila", () => abrirEditor(agencia)], ["Eliminar", "eliminar-fila", () => abrirEliminar(agencia)]]) {
      const boton = document.createElement("button");
      boton.type = "button";
      boton.className = clase;
      boton.textContent = texto;
      boton.setAttribute("aria-label", `${texto} ${agencia.nombre}, código ${agencia.codigoAgencia}`);
      boton.addEventListener("click", accion);
      acciones.append(boton);
    }
    celda.append(acciones); fila.append(celda); $("filas").append(fila);
  }
  $("contador").textContent = `${agencias.length} ${agencias.length === 1 ? "agencia" : "agencias"}`;
  $("vacio").textContent = "No hay agencias que coincidan. Prueba otra búsqueda o agrega una agencia.";
  $("vacio").hidden = agencias.length !== 0;
}

async function cargar() {
  const turno = ++carga;
  const criterio = $("criterio").value.trim();
  $("resultados").setAttribute("aria-busy", "true");
  $("contador").textContent = "Cargando…";
  $("filas").replaceChildren();
  $("vacio").textContent = "Cargando agencias…";
  $("vacio").hidden = false;
  try {
    const agencias = await solicitar(api + (criterio ? `?criterio=${encodeURIComponent(criterio)}` : ""));
    if (turno === carga) pintar(agencias);
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

function abrirEditor(agencia = null) {
  editando = agencia;
  $("formulario").reset();
  $("codigo").value = agencia?.codigoAgencia ?? "";
  $("codigo").readOnly = true;
  $("region").value = agencia?.region ?? "";
  $("region").setCustomValidity("");
  $("nombre").value = agencia?.nombre ?? "";
  $("nombre").setCustomValidity("");
  $("titulo-editor").textContent = agencia ? "Editar agencia" : "Agregar agencia";
  $("ayuda-editor").textContent = agencia ? "Actualiza el nombre y la región de la agencia seleccionada." : "Escribe el nombre y la región. El código se asigna automáticamente.";
  $("ayuda-codigo").textContent = agencia ? "El código identifica la agencia y se conserva al editar." : "El sistema asigna un código al guardar la nueva agencia.";
  mensaje("error-editor", "");
  $("editor").showModal();
  $("nombre").focus();
}

$("region").addEventListener("input", () => $("region").setCustomValidity(""));
$("nombre").addEventListener("input", () => $("nombre").setCustomValidity(""));
$("formulario").addEventListener("submit", async evento => {
  evento.preventDefault();
  if (guardando) return;
  const nombre = $("nombre").value.trim();
  if (!nombre) { $("nombre").setCustomValidity("Escribe el nombre de la agencia."); $("nombre").reportValidity(); return; }
  const region = $("region").value.trim();
  if (!region) { $("region").setCustomValidity("Escribe la región de la agencia."); $("region").reportValidity(); return; }
  guardando = true;
  $("guardar").disabled = $("cancelar").disabled = true;
  $("guardar").textContent = "Guardando…";
  mensaje("error-editor", "");
  try {
    await solicitar(editando ? `${api}/${editando.codigoAgencia}` : api, {
      method: editando ? "PUT" : "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ nombre, region })
    });
    $("editor").close();
    mensaje("aviso", editando ? "Agencia actualizada correctamente." : "Agencia agregada correctamente.");
    $("criterio").value = "";
    await cargar();
    $("nueva").focus();
  } catch (error) { mensaje("error-editor", error.message, true); }
  finally { guardando = false; $("guardar").disabled = $("cancelar").disabled = false; $("guardar").textContent = "Guardar agencia"; }
});

function abrirEliminar(agencia) {
  seleccionada = agencia;
  $("detalle-eliminar").textContent = `${agencia.nombre} · Código ${agencia.codigoAgencia}`;
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
    await solicitar(`${api}/${seleccionada.codigoAgencia}`, { method: "DELETE" });
    $("confirmacion").close();
    mensaje("aviso", "Agencia eliminada correctamente.");
    await cargar();
    $("nueva").focus();
  } catch (error) { mensaje("error-eliminar", error.message, true); }
  finally { borrando = false; $("eliminar").disabled = $("conservar").disabled = false; $("eliminar").textContent = "Eliminar agencia"; }
});

$("editor").addEventListener("cancel", evento => { if (guardando) evento.preventDefault(); });
$("confirmacion").addEventListener("cancel", evento => { if (borrando) evento.preventDefault(); });
$("cancelar").addEventListener("click", () => $("editor").close());
$("conservar").addEventListener("click", () => $("confirmacion").close());
$("nueva").addEventListener("click", () => abrirEditor());
$("busqueda").addEventListener("submit", evento => { evento.preventDefault(); mensaje("aviso", ""); cargar(); });
$("todas").addEventListener("click", () => { $("criterio").value = ""; mensaje("aviso", ""); cargar(); });
cargar();
