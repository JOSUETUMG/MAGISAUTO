"use strict";
const $ = id => document.getElementById(id);
const api = "/api/catalogos/lineas";
let editando = null, seleccionada = null;
let guardando = false, borrando = false, carga = 0;
let marcas = [];

function mensaje(id, texto, error = false) {
  $(id).textContent = texto;
  $(id).classList.toggle("error", error);
  $(id).hidden = !texto;
}

async function solicitar(url, opciones = {}) {
  let respuesta;
  try { respuesta = await fetch(url, opciones); }
  catch { throw new Error("No se pudo conectar con la aplicación. Comprueba que siga abierta y vuelve a intentarlo."); }
  let datos;
  try { datos = respuesta.status === 204 ? null : await respuesta.json(); }
  catch { throw new Error("La aplicación devolvió una respuesta inesperada. Actualiza la página e inténtalo de nuevo."); }
  if (!respuesta.ok) {
    const validaciones = datos?.errors ? Object.values(datos.errors).flat().join(" ") : null;
    throw new Error(validaciones || datos?.detail || datos?.title || "No se pudo completar la operación.");
  }
  return datos;
}

function opcionesMarcas(id, primera, valor) {
  $(id).replaceChildren(new Option(primera, ""));
  for (const marca of marcas) $(id).append(new Option(`${marca.descripcion} (${marca.codigoMarca})`, String(marca.codigoMarca)));
  $(id).value = valor;
  if ($(id).selectedIndex < 0) $(id).value = "";
}

function pintar(lineas) {
  $("filas").replaceChildren();
  for (const linea of lineas) {
    const fila = document.createElement("tr");
    for (const valor of [`${linea.nombreMarca} (${linea.codigoMarca})`, linea.codigoLinea, linea.descripcion]) {
      const celda = document.createElement("td"); celda.textContent = valor; fila.append(celda);
    }
    const celda = document.createElement("td"), acciones = document.createElement("div");
    acciones.className = "acciones";
    for (const [texto, clase, accion] of [["Editar", "editar-fila", () => abrirEditor(linea)], ["Eliminar", "eliminar-fila", () => abrirEliminar(linea)]]) {
      const boton = document.createElement("button"); boton.type = "button"; boton.className = clase; boton.textContent = texto;
      boton.setAttribute("aria-label", `${texto} ${linea.descripcion}, marca ${linea.nombreMarca}, código ${linea.codigoLinea}`);
      boton.addEventListener("click", accion); acciones.append(boton);
    }
    celda.append(acciones); fila.append(celda); $("filas").append(fila);
  }
  $("contador").textContent = `${lineas.length} ${lineas.length === 1 ? "línea" : "líneas"}`;
  $("vacio").textContent = "No hay líneas que coincidan. Prueba otros filtros o agrega una línea.";
  $("vacio").hidden = lineas.length !== 0;
}

async function cargar() {
  const turno = ++carga;
  const params = new URLSearchParams();
  const criterio = $("criterio").value.trim(), marca = $("filtro-marca").value;
  if (criterio) params.set("criterio", criterio);
  if (marca) params.set("codigoMarca", marca);
  $("resultados").setAttribute("aria-busy", "true");
  $("contador").textContent = "Cargando…"; $("filas").replaceChildren();
  $("vacio").textContent = "Cargando líneas…"; $("vacio").hidden = false;
  $("nueva").disabled = true; $("filtro-marca").disabled = true;
  try {
    const [datos, catalogo] = await Promise.all([solicitar(`${api}?${params}`), solicitar("/api/catalogos/marcas")]);
    if (turno !== carga) return;
    marcas = catalogo;
    opcionesMarcas("filtro-marca", "Todas las marcas", marca);
    $("filtro-marca").disabled = false;
    $("nueva").disabled = marcas.length === 0;
    pintar(datos);
    if (!marcas.length) mensaje("aviso", "Primero registra una marca en el catálogo de Marcas para poder agregar líneas.");
  } catch (error) {
    if (turno === carga) {
      $("contador").textContent = "No disponible";
      $("vacio").textContent = "No se pudo cargar el catálogo. Pulsa Ver todas para intentarlo de nuevo.";
      mensaje("aviso", error.message, true);
    }
  } finally { if (turno === carga) $("resultados").setAttribute("aria-busy", "false"); }
}

function abrirEditor(linea = null) {
  editando = linea; $("formulario").reset();
  opcionesMarcas("marca", "Selecciona una marca", String(linea?.codigoMarca ?? $("filtro-marca").value));
  // Conserva la identidad original incluso si otra sesión cambió el catálogo.
  if (linea && !$("marca").value) $("marca").append(new Option(linea.nombreMarca, String(linea.codigoMarca), false, true));
  $("marca").disabled = !!linea;
  $("codigo").value = linea?.codigoLinea ?? ""; $("codigo").readOnly = !!linea;
  $("nombre").value = linea?.descripcion ?? ""; $("nombre").setCustomValidity("");
  $("titulo-editor").textContent = linea ? "Editar línea" : "Agregar línea";
  $("ayuda-editor").textContent = linea ? "Puedes actualizar el nombre. La marca y el código se conservan." : "Selecciona una marca y completa los datos de la línea.";
  $("ayuda-codigo").textContent = linea ? "La marca y el código identifican esta línea." : "Usa un código entero que no exista dentro de esta marca.";
  mensaje("error-editor", ""); $("editor").showModal(); (linea ? $("nombre") : $("marca")).focus();
}

$("nombre").addEventListener("input", () => $("nombre").setCustomValidity(""));
$("formulario").addEventListener("submit", async evento => {
  evento.preventDefault(); if (guardando) return;
  const descripcion = $("nombre").value.trim();
  if (!descripcion) { $("nombre").setCustomValidity("Escribe el nombre de la línea."); $("nombre").reportValidity(); return; }
  const codigoMarca = Number($("marca").value), codigoLinea = Number($("codigo").value);
  guardando = true; $("guardar").disabled = $("cancelar").disabled = true; $("guardar").textContent = "Guardando…";
  mensaje("error-editor", "");
  try {
    await solicitar(editando ? `${api}/${editando.codigoMarca}/${editando.codigoLinea}` : api, {
      method: editando ? "PUT" : "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify(editando ? { descripcion } : { codigoMarca, codigoLinea, descripcion })
    });
    $("editor").close(); mensaje("aviso", editando ? "Línea actualizada correctamente." : "Línea agregada correctamente.");
    $("criterio").value = ""; $("filtro-marca").value = String(codigoMarca);
    await cargar(); $("nueva").focus();
  } catch (error) { mensaje("error-editor", error.message, true); }
  finally { guardando = false; $("guardar").disabled = $("cancelar").disabled = false; $("guardar").textContent = "Guardar línea"; }
});

function abrirEliminar(linea) {
  seleccionada = linea;
  $("detalle-eliminar").textContent = `${linea.nombreMarca} (${linea.codigoMarca}) · ${linea.descripcion} · Código de línea ${linea.codigoLinea}`;
  mensaje("error-eliminar", ""); $("confirmacion").showModal(); $("conservar").focus();
}
$("eliminar").addEventListener("click", async () => {
  if (borrando) return;
  borrando = true; $("eliminar").disabled = $("conservar").disabled = true; $("eliminar").textContent = "Eliminando…";
  mensaje("error-eliminar", "");
  try {
    await solicitar(`${api}/${seleccionada.codigoMarca}/${seleccionada.codigoLinea}`, { method: "DELETE" });
    $("confirmacion").close(); mensaje("aviso", "Línea eliminada correctamente."); await cargar(); $("nueva").focus();
  } catch (error) { mensaje("error-eliminar", error.message, true); }
  finally { borrando = false; $("eliminar").disabled = $("conservar").disabled = false; $("eliminar").textContent = "Eliminar línea"; }
});
$("editor").addEventListener("cancel", evento => { if (guardando) evento.preventDefault(); });
$("confirmacion").addEventListener("cancel", evento => { if (borrando) evento.preventDefault(); });
$("cancelar").addEventListener("click", () => $("editor").close());
$("conservar").addEventListener("click", () => $("confirmacion").close());
$("nueva").addEventListener("click", () => abrirEditor());
$("busqueda").addEventListener("submit", evento => { evento.preventDefault(); mensaje("aviso", ""); cargar(); });
$("filtro-marca").addEventListener("change", () => { mensaje("aviso", ""); cargar(); });
$("todas").addEventListener("click", () => { $("criterio").value = ""; $("filtro-marca").value = ""; mensaje("aviso", ""); cargar(); });
cargar();
