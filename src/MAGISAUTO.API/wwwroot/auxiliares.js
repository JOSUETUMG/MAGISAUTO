"use strict";
(() => {
  const $ = id => document.getElementById(id);
  const api = "/api/catalogos/auxiliares";
  let definiciones = [], actual = null, departamentos = [], editando = null, eliminando = null;
  let ocupado = false, listo = false, turno = 0, lectura = null;
  const nodo = (tag, texto) => { const n = document.createElement(tag); n.textContent = texto; return n; };
  function aviso(id, texto, error = false) { $(id).textContent = texto; $(id).hidden = !texto; $(id).classList.toggle("error", error); }
  async function pedir(url, opciones = {}) {
    let r, d;
    try {
      r = await fetch(url, opciones);
      d = r.status === 204 ? null : await r.json();
    } catch (e) {
      if (e.name === "AbortError") throw e;
      throw Error("No se pudo comunicar con la aplicación. Revisa la conexión e inténtalo de nuevo.");
    }
    if (!r.ok) throw Error(Object.values(d?.errors || {}).flat().join(" ") || d?.detail || "No se pudo completar la operación.");
    return d;
  }
  function controles() {
    $("catalogo").disabled = ocupado || !actual;
    $("nuevo").disabled = ocupado || !listo;
    for (const id of ["buscar", "todos", "criterio", "filtro-departamento"]) $(id).disabled = ocupado || !actual;
    $("campos").disabled = ocupado;
    for (const id of ["guardar", "cancelar", "conservar", "eliminar"]) $(id).disabled = ocupado;
  }
  function opcionesDepartamento(id, encabezado) {
    const previo = $(id).value;
    $(id).replaceChildren(new Option(encabezado, ""), ...departamentos.map(d => new Option(`${d.descripcion} (${d.codigo})`, d.codigo)));
    if (departamentos.some(d => String(d.codigo) === previo)) $(id).value = previo;
  }
  function nombreDepartamento(codigo) {
    const d = departamentos.find(d => d.codigo === codigo);
    return d ? `${d.descripcion} (${codigo})` : `Departamento ${codigo}`;
  }
  function pintar(filas) {
    $("filas").replaceChildren();
    for (const f of filas) {
      const tr = document.createElement("tr"); tr.append(nodo("td", f.codigo));
      if (actual.usaDepartamento) tr.append(nodo("td", nombreDepartamento(f.codigoDepartamento)));
      tr.append(nodo("td", f.descripcion));
      if (actual.usaReferenciaBancaria) tr.append(nodo("td", f.requiereReferencia ? "Sí" : "No"));
      const td = document.createElement("td"), acciones = document.createElement("div"); acciones.className = "acciones";
      for (const [texto, clase, accion] of [["Editar", "editar-fila", () => abrir(f)], ["Eliminar", "eliminar-fila", () => confirmar(f)]]) {
        const b = nodo("button", texto); b.type = "button"; b.className = clase;
        b.setAttribute("aria-label", `${texto} ${f.descripcion}, código ${f.codigo}${f.codigoDepartamento ? ', departamento ' + f.codigoDepartamento : ''}`);
        b.addEventListener("click", accion); acciones.append(b);
      }
      td.append(acciones); tr.append(td); $("filas").append(tr);
    }
    $("contador").textContent = `${filas.length} registro(s)`;
    $("vacio").textContent = "No hay registros para estos filtros."; $("vacio").hidden = filas.length > 0;
  }
  async function cargar() {
    // Una respuesta de un catálogo/filtro anterior nunca debe reemplazar la selección actual.
    const version = ++turno, catalogo = actual;
    lectura?.abort(); lectura = new AbortController(); const signal = lectura.signal;
    listo = false; controles(); $("filas").replaceChildren(); $("contador").textContent = "Cargando…";
    $("vacio").hidden = false; $("vacio").textContent = "Cargando registros…"; $("resultados").setAttribute("aria-busy", "true");
    const q = new URLSearchParams(), criterio = $("criterio").value.trim();
    if (criterio) q.set("criterio", criterio);
    if (catalogo.usaDepartamento && $("filtro-departamento").value) q.set("codigoDepartamento", $("filtro-departamento").value);
    try {
      const [filas, deps] = await Promise.all([
        pedir(`${api}/${catalogo.id}${q.size ? '?' + q : ''}`, { signal }),
        catalogo.usaDepartamento ? pedir(`${api}/departamentos`, { signal }) : Promise.resolve([])
      ]);
      if (version !== turno) return;
      departamentos = deps; opcionesDepartamento("filtro-departamento", "Todos los departamentos");
      pintar(filas); listo = true;
    } catch (e) {
      if (version !== turno || e.name === "AbortError") return;
      aviso("aviso", e.message, true); $("contador").textContent = "No disponible";
      $("vacio").textContent = "No se pudo cargar el catálogo. Pulsa Ver todos para intentarlo de nuevo.";
    } finally { if (version === turno) { $("resultados").setAttribute("aria-busy", "false"); controles(); } }
  }
  function seleccionar() {
    actual = definiciones.find(d => d.id === $("catalogo").value);
    $("titulo-catalogo").textContent = actual.nombre; $("ayuda-catalogo").textContent = actual.ayuda;
    $("campo-filtro-departamento").hidden = $("th-departamento").hidden = !actual.usaDepartamento;
    $("th-referencia").hidden = !actual.usaReferenciaBancaria;
    $("criterio").value = $("filtro-departamento").value = ""; aviso("aviso", ""); cargar();
  }
  function abrir(fila = null) {
    if (ocupado || !listo) return;
    editando = fila; $("formulario").reset(); aviso("error-editor", "");
    $("catalogo-editor").textContent = actual.nombre; $("titulo-editor").textContent = fila ? "Editar registro" : "Agregar registro";
    $("codigo").value = fila?.codigo ?? ""; $("codigo").readOnly = !!fila;
    $("ayuda-codigo").textContent = fila ? "El código y el departamento se conservan al editar." : "Escribe un código entero positivo disponible en este catálogo.";
    $("descripcion").value = fila?.descripcion ?? ""; $("descripcion").setCustomValidity("");
    $("campo-departamento").hidden = !actual.usaDepartamento; $("departamento").required = actual.usaDepartamento;
    opcionesDepartamento("departamento", "Selecciona un departamento");
    $("departamento").value = fila?.codigoDepartamento ?? $("filtro-departamento").value;
    $("departamento").disabled = !!fila || !actual.usaDepartamento;
    $("campo-referencia").hidden = !actual.usaReferenciaBancaria; $("requiere-referencia").required = actual.usaReferenciaBancaria;
    $("requiere-referencia").value = fila ? String(fila.requiereReferencia) : "";
    $("editor").showModal(); (fila ? $("descripcion") : actual.usaDepartamento ? $("departamento") : $("codigo")).focus();
  }
  // Municipio usa dos claves: no basta con el código visible para editar o eliminar.
  function rutaFila(fila) { return `${api}/${actual.id}/${fila.codigo}${actual.usaDepartamento ? '?codigoDepartamento=' + fila.codigoDepartamento : ''}`; }
  $("formulario").addEventListener("submit", async e => {
    e.preventDefault(); if (ocupado) return;
    const descripcion = $("descripcion").value.trim();
    if (!descripcion) { $("descripcion").setCustomValidity("Escribe una descripción."); $("descripcion").reportValidity(); return; }
    const datos = { descripcion };
    if (actual.usaReferenciaBancaria) datos.requiereReferencia = $("requiere-referencia").value === "true";
    if (!editando) {
      datos.codigo = Number($("codigo").value);
      if (actual.usaDepartamento) datos.codigoDepartamento = Number($("departamento").value);
    }
    ocupado = true; controles(); aviso("error-editor", ""); $("guardar").textContent = "Guardando…";
    try {
      const guardado = await pedir(editando ? rutaFila(editando) : `${api}/${actual.id}`, { method: editando ? "PUT" : "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(datos) });
      $("editor").close(); $("criterio").value = "";
      if (actual.usaDepartamento) $("filtro-departamento").value = String(guardado.codigoDepartamento);
      aviso("aviso", "Registro guardado correctamente."); await cargar();
    } catch (e) { aviso("error-editor", e.message, true); }
    finally { ocupado = false; controles(); $("guardar").textContent = "Guardar registro"; if (!$("editor").open) $("nuevo").focus(); }
  });
  function confirmar(fila) {
    if (ocupado || !listo) return;
    eliminando = fila; aviso("error-eliminar", "");
    $("detalle-eliminar").textContent = `${actual.nombre}: ${fila.descripcion} · Código ${fila.codigo}${actual.usaDepartamento ? ' · ' + nombreDepartamento(fila.codigoDepartamento) : ''}`;
    $("confirmacion").showModal(); $("conservar").focus();
  }
  $("eliminar").addEventListener("click", async () => {
    if (ocupado) return; ocupado = true; controles(); aviso("error-eliminar", "");
    try { await pedir(rutaFila(eliminando), { method: "DELETE" }); $("confirmacion").close(); aviso("aviso", "Registro eliminado correctamente."); await cargar(); }
    catch (e) { aviso("error-eliminar", e.message, true); }
    finally { ocupado = false; controles(); if (!$("confirmacion").open) $("nuevo").focus(); }
  });
  for (const id of ["editor", "confirmacion"]) $(id).addEventListener("cancel", e => { if (ocupado) e.preventDefault(); });
  $("descripcion").addEventListener("input", () => $("descripcion").setCustomValidity(""));
  $("cancelar").addEventListener("click", () => $("editor").close()); $("conservar").addEventListener("click", () => $("confirmacion").close());
  $("nuevo").addEventListener("click", () => abrir()); $("catalogo").addEventListener("change", seleccionar);
  $("busqueda").addEventListener("submit", e => { e.preventDefault(); if (actual && !ocupado) { aviso("aviso", ""); cargar(); } });
  $("todos").addEventListener("click", () => { $("criterio").value = $("filtro-departamento").value = ""; aviso("aviso", ""); cargar(); });
  $("filtro-departamento").addEventListener("change", () => { aviso("aviso", ""); cargar(); });
  async function iniciar() {
    $("reintentar").hidden = true; aviso("aviso", "");
    try { definiciones = await pedir(api); $("catalogo").replaceChildren(...definiciones.map(d => new Option(d.nombre, d.id))); seleccionar(); }
    catch (e) { aviso("aviso", e.message, true); $("contador").textContent = "No disponible"; $("vacio").textContent = "No se pudo cargar la lista de catálogos."; $("resultados").setAttribute("aria-busy", "false"); $("reintentar").hidden = false; }
  }
  $("reintentar").addEventListener("click", iniciar); iniciar();
})();
