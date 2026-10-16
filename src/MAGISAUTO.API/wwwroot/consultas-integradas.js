'use strict';
const el = id => document.getElementById(id);
let definiciones = [], version = 0, peticion;
let eliminando = false;
const etiqueta = nombre => nombre.replace(/([a-záéíóú])([A-Z])/g, '$1 $2').replace('Codigo', 'Código').replace('Telefono', 'Teléfono').replace('Direccion', 'Dirección').replace('Numero', 'Número');
async function json(url, signal) {
  const respuesta = await fetch(url, { cache: 'no-store', signal });
  const datos = await respuesta.json();
  if (!respuesta.ok) throw new Error(datos.detail || datos.title || 'No se pudo consultar. Intenta de nuevo.');
  return datos;
}
async function consultar(todos) {
  if (eliminando) return;
  const criterio = el('criterio').value.trim();
  if (!todos && !criterio) { el('criterio').setCustomValidity('Escribe un dato para buscar o pulsa Ver todos.'); el('criterio').reportValidity(); return; }
  if (todos) el('criterio').value = '';
  el('criterio').setCustomValidity('');
  const actual = ++version;
  peticion?.abort(); peticion = new AbortController();
  el('resultado').hidden = true; el('resultado').setAttribute('aria-busy', 'true');
  el('mensaje').textContent = 'Consultando…';
  try {
    const datos = await json('/api/consultas-integradas/' + encodeURIComponent(el('entidad').value) + (todos ? '' : '?criterio=' + encodeURIComponent(criterio)), peticion.signal);
    if (actual !== version) return;
    el('cabecera').replaceChildren(); el('filas').replaceChildren();
    const encabezado = document.createElement('tr');
    const entidad = el('entidad').value;
    const permiteEliminar = ['personas', 'referencias'].includes(entidad);
    for (const columna of datos.columnas) { const th = document.createElement('th'); th.scope = 'col'; th.textContent = etiqueta(columna.nombre); encabezado.append(th); }
    if (permiteEliminar) { const th = document.createElement('th'); th.scope = 'col'; th.textContent = 'Acciones'; encabezado.append(th); }
    el('cabecera').append(encabezado);
    for (const fila of datos.filas) {
      const tr = document.createElement('tr');
      for (const columna of datos.columnas) { const td = document.createElement('td'); td.textContent = fila[columna.nombre] ?? 'Sin dato'; tr.append(td); }
      if (permiteEliminar) {
        const codigo = fila[entidad === 'personas' ? 'CodigoPersona' : 'CodigoReferencia'];
        const td = document.createElement('td'), boton = document.createElement('button');
        boton.type = 'button'; boton.className = 'secundario'; boton.textContent = 'Eliminar';
        boton.setAttribute('aria-label', `Eliminar ${entidad === 'personas' ? 'persona' : 'referencia'} ${codigo}`);
        boton.addEventListener('click', () => eliminar(entidad, codigo, fila));
        td.append(boton); tr.append(td);
      }
      el('filas').append(tr);
    }
    el('titulo').textContent = datos.titulo;
    el('cantidad').textContent = datos.filas.length + ' registro(s)';
    el('mensaje').textContent = datos.filas.length ? 'Consulta completada.' : 'No hay registros que coincidan.';
    el('resultado').hidden = false;
  } catch (error) { if (actual === version && error.name !== 'AbortError') el('mensaje').textContent = error.message; }
  finally { if (actual === version) el('resultado').setAttribute('aria-busy', 'false'); }
}
async function eliminar(entidad, codigo, fila) {
  if (eliminando) return;
  const detalle = entidad === 'personas'
    ? [fila.PrimerNombre, fila.SegundoNombre, fila.PrimerApellido, fila.SegundoApellido].filter(Boolean).join(' ')
    : `Persona ${fila.CodigoPersona}; lugar de trabajo: ${fila.LugarTrabajo}`;
  const regla = entidad === 'personas'
    ? 'Solo se eliminará si no tiene contactos ni roles vinculados.'
    : 'Solo se eliminará la ficha de referencia si no está vinculada a clientes. La persona y sus contactos se conservarán.';
  if (!window.confirm(`¿Eliminar ${entidad === 'personas' ? 'persona' : 'referencia'} ${codigo}?\n${detalle}\n\n${regla}\nEsta acción es permanente.`)) return;
  eliminando = true;
  ++version; peticion?.abort();
  const controles = [...document.querySelectorAll('#consulta input, #consulta select, #consulta button, #filas button')];
  controles.forEach(x => x.disabled = true);
  el('mensaje').textContent = 'Eliminando…';
  let exito = false;
  try {
    const respuesta = await fetch(`/api/consultas-integradas/${entidad}/${codigo}`, { method: 'DELETE', cache: 'no-store' });
    if (!respuesta.ok) { const error = await respuesta.json(); throw new Error(error.detail || 'No se pudo eliminar el registro.'); }
    exito = true;
  } catch (error) { el('mensaje').textContent = error.message; }
  finally { eliminando = false; controles.forEach(x => x.disabled = false); }
  if (exito) {
    await consultar(!el('criterio').value.trim());
    el('mensaje').textContent = 'Registro eliminado. ' + el('mensaje').textContent;
    el('todos').focus();
  }
}
el('criterio').addEventListener('input', () => el('criterio').setCustomValidity(''));
el('consulta').addEventListener('submit', evento => { evento.preventDefault(); consultar(false); });
el('todos').addEventListener('click', () => consultar(true));
el('entidad').addEventListener('change', () => { el('ayuda').textContent = definiciones.find(x => x.id === el('entidad').value).ayuda; consultar(true); });
(async () => {
  try {
    definiciones = await json('/api/consultas-integradas');
    el('entidad').replaceChildren(...definiciones.map(x => new Option(x.titulo, x.id)));
    for (const id of ['entidad', 'buscar', 'todos']) el(id).disabled = false;
    el('ayuda').textContent = definiciones[0].ayuda;
    await consultar(true);
  } catch { el('mensaje').textContent = 'No se pudieron cargar las consultas. Recarga la página para reintentar.'; }
})();
