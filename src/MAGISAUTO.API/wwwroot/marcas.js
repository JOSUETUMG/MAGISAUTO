"use strict";
const $ = id => document.getElementById(id);
const api = "/api/catalogos/marcas";
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

function pintar(marcas) {
  $("filas").replaceChildren();
  for (const marca of marcas) {
    const fila = document.createElement("tr");
    for (const valor of [marca.codigoMarca, marca.descripcion]) {
      const celda = document.createElement("td");
      celda.textContent = valor;
      fila.append(celda);
    }
    const celda = document.createElement("td");
    const acciones = document.createElement("div");
    acciones.className = "acciones";
    for (const [texto, clase, accion] of [["Editar", "editar-fila", () => abrirEditor(marca)], ["Eliminar", "eliminar-fila", () => abrirEliminar(marca)]]) {
      const boton = document.createElement("button");
      boton.type = "button";
      boton.className = clase;
      boton.textContent = texto;
      boton.setAttribute("aria-label", `${texto} ${marca.descripcion}, código ${marca.codigoMarca}`);
      boton.addEventListener("click", accion);
      acciones.append(boton);
    }
    celda.append(acciones); fila.append(celda); $("filas").append(fila);
  }
  $("contador").textContent = `${marcas.length} ${marcas.length === 1 ? "marca" : "marcas"}`;
  $("vacio").textContent = "No hay marcas que coincidan. Prueba otra búsqueda o agrega una marca.";
  $("vacio").hidden = marcas.length !== 0;
}

async function cargar() {
  const turno = ++carga;
  const criterio = $("criterio").value.trim();
  $("resultados").setAttribute("aria-busy", "true");
  $("contador").textContent = "Cargando…";
  $("filas").replaceChildren();
  $("vacio").textContent = "Cargando marcas…";
  $("vacio").hidden = false;
  try {
    const marcas = await solicitar(api + (criterio ? `?criterio=${encodeURIComponent(criterio)}` : ""));
    if (turno === carga) pintar(marcas);
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

function abrirEditor(marca = null) {
  editando = marca;
  $("formulario").reset();
  $("codigo").value = marca?.codigoMarca ?? "";
  $("codigo").readOnly = !!marca;
  $("nombre").value = marca?.descripcion ?? "";
  $("nombre").setCustomValidity("");
  $("titulo-editor").textContent = marca ? "Editar marca" : "Agregar marca";
  $("ayuda-editor").textContent = marca ? "Actualiza el nombre de la marca seleccionada." : "Completa los dos campos para registrar una marca.";
  $("ayuda-codigo").textContent = marca ? "El código identifica la marca y se conserva al editar." : "Usa un código entero que todavía no exista.";
  mensaje("error-editor", "");
  $("editor").showModal();
  (marca ? $("nombre") : $("codigo")).focus();
}

$("nombre").addEventListener("input", () => $("nombre").setCustomValidity(""));
$("formulario").addEventListener("submit", async evento => {
  evento.preventDefault();
  if (guardando) return;
  const descripcion = $("nombre").value.trim();
  if (!descripcion) { $("nombre").setCustomValidity("Escribe el nombre de la marca."); $("nombre").reportValidity(); return; }
  const codigoMarca = Number($("codigo").value);
  guardando = true;
  $("guardar").disabled = $("cancelar").disabled = true;
  $("guardar").textContent = "Guardando…";
  mensaje("error-editor", "");
  try {
    await solicitar(editando ? `${api}/${editando.codigoMarca}` : api, {
      method: editando ? "PUT" : "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify(editando ? { descripcion } : { codigoMarca, descripcion })
    });
    $("editor").close();
    mensaje("aviso", editando ? "Marca actualizada correctamente." : "Marca agregada correctamente.");
    $("criterio").value = "";
    await cargar();
    $("nueva").focus();
  } catch (error) { mensaje("error-editor", error.message, true); }
  finally { guardando = false; $("guardar").disabled = $("cancelar").disabled = false; $("guardar").textContent = "Guardar marca"; }
});

function abrirEliminar(marca) {
  seleccionada = marca;
  $("detalle-eliminar").textContent = `${marca.descripcion} · Código ${marca.codigoMarca}`;
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
    await solicitar(`${api}/${seleccionada.codigoMarca}`, { method: "DELETE" });
    $("confirmacion").close();
    mensaje("aviso", "Marca eliminada correctamente.");
    await cargar();
    $("nueva").focus();
  } catch (error) { mensaje("error-eliminar", error.message, true); }
  finally { borrando = false; $("eliminar").disabled = $("conservar").disabled = false; $("eliminar").textContent = "Eliminar marca"; }
});

$("editor").addEventListener("cancel", evento => { if (guardando) evento.preventDefault(); });
$("confirmacion").addEventListener("cancel", evento => { if (borrando) evento.preventDefault(); });
$("cancelar").addEventListener("click", () => $("editor").close());
$("conservar").addEventListener("click", () => $("confirmacion").close());
$("nueva").addEventListener("click", () => abrirEditor());
$("busqueda").addEventListener("submit", evento => { evento.preventDefault(); mensaje("aviso", ""); cargar(); });
$("todas").addEventListener("click", () => { $("criterio").value = ""; mensaje("aviso", ""); cargar(); });
cargar();
