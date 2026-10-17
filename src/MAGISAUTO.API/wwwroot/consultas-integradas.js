'use strict';
const el = id => document.getElementById(id);
let definiciones = [], version = 0, peticion;
let eliminando = false;
const mantenibles = ['personas', 'telefonos', 'direcciones', 'referencias', 'cuotas', 'resumenes'];
let fichaActual, guardandoFicha = false, versionFicha = 0;
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
    const permiteEliminar = mantenibles.includes(entidad);
    el('nuevo-registro').hidden = !permiteEliminar;
    for (const columna of datos.columnas) { const th = document.createElement('th'); th.scope = 'col'; th.textContent = etiqueta(columna.nombre); encabezado.append(th); }
    if (permiteEliminar) { const th = document.createElement('th'); th.scope = 'col'; th.textContent = 'Acciones'; encabezado.append(th); }
    el('cabecera').append(encabezado);
    for (const fila of datos.filas) {
      const tr = document.createElement('tr');
      for (const columna of datos.columnas) { const td = document.createElement('td'); td.textContent = fila[columna.nombre] ?? 'Sin dato'; tr.append(td); }
      if (permiteEliminar) {
        const codigo = fila[entidad === 'referencias' ? 'CodigoReferencia' : 'CodigoPersona'] ?? fila.NumeroCredito;
        const td = document.createElement('td'), boton = document.createElement('button');
        const editar = document.createElement('button');
        editar.type = 'button'; editar.className = 'secundario'; editar.textContent = entidad === 'resumenes' ? 'Recalcular borrador' : 'Editar';
        editar.addEventListener('click', () => abrirFicha(entidad, fila));
        td.append(editar);
        boton.type = 'button'; boton.className = 'secundario'; boton.textContent = 'Eliminar';
        boton.setAttribute('aria-label', `Eliminar ${entidad === 'personas' ? 'persona' : 'referencia'} ${codigo}`);
        boton.addEventListener('click', () => ['personas', 'referencias'].includes(entidad) ? eliminar(entidad, codigo, fila) : borrarContacto(entidad, fila));
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
    const solicitada = new URLSearchParams(location.search).get('consulta');
    if (definiciones.some(x => x.id === solicitada)) el('entidad').value = solicitada;
    for (const id of ['entidad', 'buscar', 'todos']) el(id).disabled = false;
    el('ayuda').textContent = definiciones.find(x => x.id === el('entidad').value).ayuda;
    await consultar(true);
  } catch { el('mensaje').textContent = 'No se pudieron cargar las consultas. Recarga la página para reintentar.'; }
})();

function opcionesCampo(campo, catalogos, departamento) {
  let filas = catalogos[campo.catalogo] || [];
  if (campo.catalogo === 'Municipio') filas = filas.filter(f => String(f.codigoDepartamento) === String(departamento));
  return filas.map(f => {
    const clave = campo.nombre[0].toLowerCase() + campo.nombre.slice(1);
    const nombre = campo.catalogo === 'Persona'
      ? [f.primerNombre, f.segundoNombre, f.primerApellido, f.segundoApellido].filter(Boolean).join(' ')
      : f.nombre || f.descripcion || f.estado || '';
    return new Option(`${f[clave]} · ${nombre}`, String(f[clave]));
  });
}
async function abrirFicha(entidad, fila = null) {
  if (guardandoFicha || eliminando) return;
  const revision = ++versionFicha;
  fichaActual = null;
  el('ficha-campos').replaceChildren(); el('ficha-mensaje').textContent = 'Cargando formulario…';
  el('ficha-titulo').textContent = (fila ? 'Editar ' : 'Agregar ') + definiciones.find(d => d.id === entidad).titulo.toLowerCase();
  el('ficha-guardar').disabled = true;
  el('ficha-dialogo').showModal();
  try {
    const esquema = await json('/api/mantenimiento-personas/' + entidad);
    if (revision !== versionFicha || !el('ficha-dialogo').open) return;
    fichaActual = { entidad, fila, esquema };
    for (const campo of esquema.campos) {
      if (!fila && campo.automatico) continue;
      const label = document.createElement('label'); label.textContent = campo.etiqueta + (campo.opcional ? '' : ' *');
      const input = document.createElement(campo.catalogo ? 'select' : 'input');
      input.name = campo.nombre; input.required = !campo.opcional;
      if (campo.catalogo) input.replaceChildren(new Option('Selecciona…', ''), ...opcionesCampo(campo, esquema.catalogos, fila?.CodigoDepartamento));
      else { input.type = campo.tipo === 'money' ? 'text' : campo.tipo; if (campo.tipo === 'number') { input.min = '1'; input.step = '1'; } else input.maxLength = campo.maximo; }
      if (campo.tipo === 'money') { input.inputMode = 'decimal'; input.pattern = '[0-9]+([.][0-9]{1,2})?'; }
      if (fila && campo.catalogo && ![...input.options].some(o => o.value === String(fila[campo.nombre]))) input.add(new Option(String(fila[campo.nombre]), String(fila[campo.nombre])));
      input.value = fila?.[campo.nombre] ?? '';
      input.disabled = !!fila && (campo.clave || campo.nombre === 'CodigoPersona' || campo.nombre === 'DPI' && !!fila.DPI);
      label.append(input); el('ficha-campos').append(label);
    }
    const departamento = el('ficha-formulario').elements.namedItem('CodigoDepartamento');
    departamento?.addEventListener('change', () => {
      const campo = esquema.campos.find(c => c.nombre === 'CodigoMunicipio');
      const municipio = el('ficha-formulario').elements.namedItem('CodigoMunicipio');
      municipio.replaceChildren(new Option('Selecciona…', ''), ...opcionesCampo(campo, esquema.catalogos, departamento.value));
    });
    el('ficha-mensaje').textContent = entidad === 'referencias' ? 'Selecciona una persona existente. Para cambiar sus nombres o contactos, usa esas consultas.'
      : ['cuotas','resumenes'].includes(entidad) ? 'Solo para borradores. Estas cuotas son una simulación: aprobar las reemplaza por el plan calculado. El resumen se calcula desde las cuotas y los cargos del borrador.' : '';
    el('ficha-guardar').disabled = false;
    el('ficha-campos').querySelector('input:not(:disabled), select:not(:disabled)')?.focus();
  } catch (error) { if (revision === versionFicha) el('ficha-mensaje').textContent = error.message; }
}
function cerrarFicha() { if (guardandoFicha) return; ++versionFicha; el('ficha-dialogo').close(); }
el('cerrar-ficha').addEventListener('click', cerrarFicha);
el('ficha-dialogo').addEventListener('cancel', evento => { if (guardandoFicha) evento.preventDefault(); else ++versionFicha; });
el('nuevo-registro').addEventListener('click', () => abrirFicha(el('entidad').value));
async function enviarFicha(entidad, operacion, datos, fila) {
  const anterior = fila ? Object.fromEntries(Object.entries(fila).map(([k,v]) => [k, v === null ? null : String(v)])) : null;
  const respuesta = await fetch(`/api/mantenimiento-personas/${entidad}/${operacion}`, {
    method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({datos, anterior})
  });
  if (!respuesta.ok) { const error = await respuesta.json(); throw new Error(error.detail || error.title || 'No se pudo guardar.'); }
}
el('ficha-formulario').addEventListener('submit', async evento => {
  evento.preventDefault(); if (guardandoFicha || !fichaActual) return;
  const {entidad, fila, esquema} = fichaActual;
  const datos = {};
  for (const campo of esquema.campos) {
    const input = el('ficha-formulario').elements.namedItem(campo.nombre);
    if (input) datos[campo.nombre] = input.value || null;
  }
  guardandoFicha = true; el('ficha-guardar').disabled = true; el('cerrar-ficha').disabled = true;
  const estados = [...el('ficha-campos').querySelectorAll('input,select')].map(control => [control, control.disabled]);
  estados.forEach(([control]) => control.disabled = true);
  el('ficha-mensaje').textContent = 'Guardando…';
  let exito = false;
  try { await enviarFicha(entidad, fila ? 'editar' : 'crear', datos, fila); exito = true; }
  catch (error) { el('ficha-mensaje').textContent = error.message; }
  finally { guardandoFicha = false; estados.forEach(([control, disabled]) => control.disabled = disabled); el('ficha-guardar').disabled = false; el('cerrar-ficha').disabled = false; }
  if (exito) { cerrarFicha(); await consultar(true); el('mensaje').textContent = 'Registro guardado correctamente.'; }
});
async function borrarContacto(entidad, fila) {
  const financiero = ['cuotas','resumenes'].includes(entidad);
  const detalle = financiero ? `¿Eliminar ${entidad === 'cuotas' ? 'cuota '+fila.Cuota : 'resumen'} del borrador ${fila.NumeroCredito}? Los contratos aprobados están protegidos.`
    : `¿Eliminar el contacto ${fila.Correlativo} de la persona ${fila.CodigoPersona}? Se quitará de todos sus expedientes. La persona se conserva.`;
  if (eliminando || !window.confirm(detalle)) return;
  eliminando = true; ++version; peticion?.abort();
  const controles = [...document.querySelectorAll('#consulta button, #consulta select, #filas button')];
  controles.forEach(c => c.disabled = true);
  let exito = false;
  const claves = financiero ? {NumeroCredito:String(fila.NumeroCredito), ...(entidad === 'cuotas' ? {Cuota:String(fila.Cuota)} : {})}
    : {CodigoPersona:String(fila.CodigoPersona), Correlativo:String(fila.Correlativo)};
  try { await enviarFicha(entidad, 'eliminar', claves, fila); exito = true; }
  catch(error) { el('mensaje').textContent = error.message; }
  finally { eliminando = false; controles.forEach(c => c.disabled = false); }
  if (exito) { await consultar(true); el('mensaje').textContent = financiero ? 'Registro de simulación eliminado.' : 'Contacto eliminado. La persona se conserva.'; }
}
