'use strict';
(() => {
  const $ = id => document.getElementById(id);
  let definiciones = [], hoy = '', catalogos = null, catalogosCargando = false, version = 0, controlador = null, secuenciaDetalle = 0;
  const etiquetas = {
    NumeroCredito: 'Crédito', CodigoDeudor: 'Código de cliente', CodigoVendedor: 'Código de vendedor', CodigoEmpleado: 'Código de empleado',
    CodigoPago: 'Código de pago', CodigoTipoPago: 'Código del medio', CodigoFiador: 'Código de fiador', CodigoAgencia: 'Código de agencia',
    CodigoMarca: 'Código de marca', CodigoLinea: 'Código de línea', Comprobante: 'Recibo', Descripcion: 'Medio de pago',
    FechaAprobacion: 'Aprobación', FechaVencimiento: 'Vencimiento', FechaPago: 'Fecha y hora del pago', FechaAnulacion: 'Fecha y hora de anulación',
    FechaNacimiento: 'Nacimiento', FechaValoracion: 'Fecha de valoración', PrimerVencimientoPendiente: 'Primer vencimiento pendiente',
    MontoFinanciado: 'Monto financiado', PrecioContado: 'Precio al contado', TotalIntereses: 'Intereses del plan', TotalNetoRecaudable: 'Total contractual de cuotas',
    TasaAnual: 'Tasa anual', PorcentajeComision: 'Comisión (%)', ManejoCuenta: 'Manejo de cuenta', SeguroAuto: 'Seguro de automóvil', SeguroVida: 'Seguro de vida',
    ReferenciaBancaria: 'Referencia bancaria', RegistradoPor: 'Registrado por', AnuladoPor: 'Anulado por', MotivoAnulacion: 'Motivo de anulación',
    Observacion: 'Observación', CorreoElectronico: 'Correo electrónico', CartaFelicitacion: 'Carta de felicitación', EdadQueCumple: 'Edad que cumple',
    VigenteAlCorte: 'Pago efectivo al corte', GarantiaInsuficiente: 'Valor registrado menor que capital', Estado: 'Estado actual', Plazo: 'Plazo (meses)',
    SaldoPendiente: 'Saldo pendiente', CapitalPendiente: 'Capital pendiente', InteresPendiente: 'Interés pendiente',
    ManejoPendiente: 'Manejo pendiente', SeguroAutoPendiente: 'Seguro auto pendiente', SeguroVidaPendiente: 'Seguro vida pendiente',
    Capital: 'Capital', Interes: 'Interés', Anulado: 'Anulado actualmente', ValorDepreciado: 'Valor depreciado',
    CostoFinanciamientoYCargos: 'Costo de financiamiento y cargos', DesembolsoTotalCliente: 'Desembolso contractual total del cliente',
    PerdidaValorEstimada: 'Pérdida estimada de valor', MargenGarantia: 'Margen de garantía'
  };
  const tituloColumna = nombre => etiquetas[nombre] || nombre.replace(/([a-záéíóú])([A-Z])/g, '$1 $2');
  const nodo = (tag, texto, clase) => { const n = document.createElement(tag); if (texto !== undefined) n.textContent = texto; if (clase) n.className = clase; return n; };
  const seleccion = () => definiciones.find(r => r.id === Number($('reporte').value));
  function aviso(texto, error = false) { $('mensaje').textContent = texto; $('mensaje').className = 'aviso' + (error ? ' error' : ''); $('mensaje').hidden = !texto; }
  async function leer(url, signal) {
    const r = await fetch(url, { signal, cache: 'no-store' });
    let data;
    try { data = await r.json(); }
    catch { throw new Error('El servidor no devolvió una respuesta válida. Revisa que la aplicación esté iniciada e intenta nuevamente.'); }
    if (!r.ok) throw new Error(data.detail || (data.errors ? Object.values(data.errors).flat().join(' ') : data.title) || 'No se pudo completar la consulta.');
    return data;
  }
  function invalidar() {
    version++; controlador?.abort(); controlador = null;
    $('resultados').replaceChildren(); $('resultados').hidden = true; $('resultados').setAttribute('aria-busy', 'false');
    $('inicio').hidden = false; aviso(''); habilitar();
  }
  function habilitar() {
    const r = seleccion();
    $('ejecutar').disabled = !r || (!catalogos && r.filtros.some(f => ['cliente', 'credito'].includes(f.tipo))) || !!controlador;
  }
  function opciones(control, tipo) {
    control.replaceChildren(new Option('Selecciona una opción', ''));
    const lista = tipo === 'cliente' ? catalogos?.clientes : catalogos?.creditos;
    for (const item of lista || []) control.add(tipo === 'cliente'
      ? new Option(`${item.nombre} (${item.codigoDeudor})`, item.codigoDeudor)
      : new Option(`${item.numeroCredito} · ${item.estado}`, item.numeroCredito));
    control.disabled = !catalogos;
  }
  function filtros() {
    invalidar(); const r = seleccion(); $('filtros').replaceChildren();
    if (!r) return;
    $('utilidad').textContent = r.utilidad; $('nota').textContent = r.nota;
    for (const f of r.filtros) {
      const cont = nodo('div'), label = nodo('label', f.etiqueta), id = `f-${f.nombre}`;
      label.htmlFor = id;
      let input;
      if (['cliente', 'credito'].includes(f.tipo)) { input = nodo('select'); opciones(input, f.tipo); }
      else {
        input = nodo('input'); input.type = f.tipo === 'fecha' ? 'date' : 'number';
        if (f.tipo === 'fecha') { input.max = '9998-12-31'; input.value = f.nombre === 'desde' ? hoy.slice(0, 8) + '01' : hoy; }
        else {
          input.min = f.minimo; input.max = f.maximo; input.step = '1';
          input.value = f.nombre === 'mes' ? Number(hoy.slice(5, 7)) : f.nombre === 'anio' ? Number(hoy.slice(0, 4)) : f.predeterminado ?? '';
        }
      }
      input.id = id; input.name = f.nombre; input.required = true;
      input.addEventListener('input', invalidar); input.addEventListener('change', invalidar);
      cont.append(label, input); $('filtros').append(cont);
    }
    habilitar();
  }
  async function cargarCatalogos() {
    if (catalogosCargando) return;
    catalogosCargando = true; $('reintentar').disabled = true;
    try {
      catalogos = await leer('/api/reportes/catalogos'); $('aviso-catalogos').hidden = true;
      for (const f of seleccion()?.filtros || []) if (['cliente', 'credito'].includes(f.tipo)) opciones($(`f-${f.nombre}`), f.tipo);
    } catch { catalogos = null; $('aviso-catalogos').hidden = false; }
    finally { catalogosCargando = false; $('reintentar').disabled = false; habilitar(); }
  }
  function abrirCarta(fila, data, boton) {
    $('carta-periodo').textContent = `Felicitación del mes ${data.filtros.mes} de ${data.filtros.anio}`;
    $('carta-cliente').textContent = fila.Cliente;
    $('carta-texto').textContent = fila.CartaFelicitacion;
    $('carta-dialogo').showModal();
    $('carta-dialogo').addEventListener('close', () => { document.body.classList.remove('imprimir-carta'); boton.focus(); }, { once: true });
  }
  function botonAccion(texto, accion) {
    const b = nodo('button', texto, 'secundario'); b.type = 'button'; b.addEventListener('click', () => accion(b)); return b;
  }
  function ventana(titulo, origen) {
    const d = nodo('dialog', undefined, 'detalle-reporte'), h = nodo('h2', titulo), cuerpo = nodo('div');
    h.id = 'detalle-' + (++secuenciaDetalle); d.setAttribute('aria-labelledby', h.id);
    const pie = nodo('div', undefined, 'botones-dialogo');
    const cerrar = botonAccion('Cerrar y volver', () => d.close()); cerrar.id = 'cerrar-' + h.id;
    pie.append(cerrar); d.append(h, cuerpo, pie); document.body.append(d);
    const ctrl = new AbortController();
    d.addEventListener('close', () => { ctrl.abort(); d.remove(); if (origen?.isConnected) origen.focus(); }, { once:true });
    d.showModal(); return { d, cuerpo, signal:ctrl.signal };
  }
  function ficha(fila, tabla, origen) {
    const v = ventana('Detalle del registro', origen), dl = nodo('dl', undefined, 'ficha-reporte');
    for (const c of tabla.columnas) dl.append(nodo('dt', tituloColumna(c.nombre)), nodo('dd', FormatoReportes.celda(fila[c.nombre], c)));
    v.cuerpo.append(dl);
  }
  async function verPlan(numero, corte, origen) {
    const v = ventana('Plan del crédito ' + numero, origen); v.cuerpo.append(nodo('p', 'Cargando plan…', 'aviso'));
    try {
      const data = await leer('/api/reportes/7?' + new URLSearchParams({ numeroCredito:numero, fechaCorte:corte }), v.signal);
      if (!v.d.open) return;
      v.cuerpo.replaceChildren(nodo('p', 'Fecha de corte: ' + corte, 'aclaracion'), nodo('p', data.nota));
      for (const t of data.tablas) v.cuerpo.append(tablaResultado(t, data));
      const a = nodo('a', 'Ver pagos actuales de este crédito →', 'regreso'); a.href = '/pagos.html?credito=' + encodeURIComponent(numero); v.cuerpo.append(a);
    } catch(e) { if (e.name !== 'AbortError' && v.d.open) v.cuerpo.replaceChildren(nodo('p', e.message, 'aviso error')); }
  }
  async function verRango(fila, data, origen) {
    const rangos = {'01-30':[1,30], '31-60':[31,60], '61-90':[61,90], '91 o mas':[91,Infinity]};
    const rango = rangos[fila.Rango]; if (!rango) return;
    const v = ventana('Créditos con mora de ' + fila.Rango + ' días', origen); v.cuerpo.append(nodo('p', 'Cargando créditos…', 'aviso'));
    try {
      const detalle = await leer('/api/reportes/2?' + new URLSearchParams({ fechaCorte:data.filtros.fechaCorte, diasMinimos:rango[0] }), v.signal);
      if (!v.d.open) return;
      const t = detalle.tablas[0]; t.filas = t.filas.filter(f => Number(f.DiasMora) >= rango[0] && Number(f.DiasMora) <= rango[1]);
      t.titulo = 'Créditos del rango';
      v.cuerpo.replaceChildren(nodo('p', `Corte: ${data.filtros.fechaCorte}. ${t.filas.length} crédito(s). Clasificados por su cuota pendiente más antigua.`, 'aclaracion'));
      if (t.filas.length !== Number(fila.Creditos)) v.cuerpo.append(nodo('p', 'La cantidad cambió desde la consulta inicial. Cierra y vuelve a consultar el reporte para actualizar el resumen.', 'aviso'));
      v.cuerpo.append(tablaResultado(t, detalle));
    } catch(e) { if (e.name !== 'AbortError' && v.d.open) v.cuerpo.replaceChildren(nodo('p', e.message, 'aviso error')); }
  }
  function acciones(fila, t, data) {
    const salida = [];
    if (data.id === 5) salida.push(botonAccion('Ver carta', b => abrirCarta(fila, data, b)));
    if (data.id === 15) salida.push(botonAccion('Ver créditos del rango', b => verRango(fila, data, b)));
    if (fila.NumeroCredito && [1,2,6,9,10,11,12,16,17,18,20].includes(data.id))
      salida.push(botonAccion('Ver plan', b => verPlan(fila.NumeroCredito, data.filtros.fechaCorte || data.filtros.hasta, b)));
    if (t.columnas.length >= 8 && data.id !== 5) salida.push(botonAccion('Leer registro', b => ficha(fila, t, b)));
    return salida;
  }
  function exportar(t, data) {
    // Las celdas de texto no pueden convertirse en fórmulas al abrir el CSV.
    const celda = valor => { let s = String(valor ?? ''); if (/^[\s]*[=+@-]/.test(s)) s = "'" + s; return '"' + s.replaceAll('"','""') + '"'; };
    const lineas = [t.columnas.map(c => celda(tituloColumna(c.nombre))).join(',')];
    for (const f of t.filas) lineas.push(t.columnas.map(c => celda(f[c.nombre])).join(','));
    const url = URL.createObjectURL(new Blob(['\uFEFF' + lineas.join('\r\n')], {type:'text/csv;charset=utf-8'}));
    const contexto = Object.values(data.filtros).join('-').replace(/[^a-z0-9-]/gi,'-');
    const a = nodo('a'); a.href = url; a.download = `MAGISAUTO-reporte-${data.id}-${contexto}-${t.titulo.replace(/[^a-z0-9]/gi,'-')}.csv`; a.click(); setTimeout(() => URL.revokeObjectURL(url), 1000);
  }
  function tablaResultado(t, data) {
    const seccion = nodo('section', undefined, 'panel resultado-tabla'), resumen = nodo('div', undefined, 'resumen');
    resumen.append(nodo('h3', t.titulo), nodo('span', `${t.filas.length} fila(s)`));
    if (t.filas.length) resumen.append(botonAccion('Exportar CSV', () => exportar(t, data)));
    seccion.append(resumen);
    if (!t.filas.length) { seccion.append(nodo('p', 'No hay resultados para estos filtros.', 'vacio')); return seccion; }
    const cont = nodo('div', undefined, 'tabla-contenedor'); cont.tabIndex = 0; cont.setAttribute('role','region'); cont.setAttribute('aria-label',t.titulo + '. Desplaza para ver las columnas.');
    const tabla = nodo('table'), thead = nodo('thead'), tr = nodo('tr');
    for (const c of t.columnas) { const th = nodo('th',tituloColumna(c.nombre),c.tipo === 'decimal' ? 'numero' : ''); th.scope='col'; tr.append(th); }
    const tieneAcciones = t.filas.some(f => acciones(f,t,data).length > 0);
    if (tieneAcciones) { const th = nodo('th','Acciones','columna-acciones'); th.scope='col'; tr.append(th); }
    thead.append(tr); tabla.append(thead); const tbody=nodo('tbody');
    for (const fila of t.filas) {
      const row=nodo('tr');
      for (const c of t.columnas) row.append(nodo('td',FormatoReportes.celda(fila[c.nombre],c), ['decimal','entero'].includes(c.tipo)?'numero':c.tipo==='texto'?(/Observacion|Motivo|Carta|Direccion/.test(c.nombre)?'texto-largo':'texto-corto'):''));
      if (tieneAcciones) { const td=nodo('td',undefined,'columna-acciones'), grupo=nodo('div',undefined,'acciones-reporte'); grupo.append(...acciones(fila,t,data)); td.append(grupo); row.append(td); }
      tbody.append(row);
    }
    const nota = nodo('p', undefined, 'nota');
    nota.append(nodo('span', 'Desplaza horizontalmente para ver todas las columnas. ', 'instruccion-desplazamiento'), document.createTextNode('«Sin dato» no equivale a cero.'));
    tabla.append(tbody);cont.append(tabla);seccion.append(cont,nota); return seccion;
  }
  function mostrar(data, r) {
    const panel = $('resultados'); panel.replaceChildren();
    const cab = nodo('div', undefined, 'encabezado-resultados'); cab.append(nodo('h2', data.titulo));
    cab.append(nodo('p', r.filtros.map(f => {
      let valor = data.filtros[f.nombre];
      if (f.tipo === 'cliente') valor = `${catalogos?.clientes.find(c => String(c.codigoDeudor) === valor)?.nombre || 'Cliente'} (${valor})`;
      return `${f.etiqueta}: ${valor}`;
    }).join(' · ')));
    cab.append(nodo('p', `Consultado: ${data.consultadoEnGuatemala} · Guatemala`));
    cab.append(nodo('p', data.nota, 'aclaracion')); panel.append(cab);
    const herramientas = nodo('div', undefined, 'herramientas-reporte');
    herramientas.append(botonAccion('Volver a filtros', () => { $('consulta').scrollIntoView({behavior:'smooth'}); $('reporte').focus(); }), botonAccion('Imprimir reporte', () => { document.body.classList.add('imprimir-reporte'); window.print(); }));
    panel.append(herramientas);
    for (const t of data.tablas) panel.append(tablaResultado(t, data));
    panel.hidden = false; $('inicio').hidden = true;
  }
  $('consulta').addEventListener('submit', async e => {
    e.preventDefault(); if (!$('consulta').reportValidity()) return;
    invalidar(); const r = seleccion(), actual = version;
    const query = new URLSearchParams(); for (const f of r.filtros) query.set(f.nombre, $(`f-${f.nombre}`).value);
    controlador = new AbortController(); habilitar(); aviso('Consultando…'); $('resultados').setAttribute('aria-busy', 'true');
    try {
      const data = await leer(`/api/reportes/${r.id}?${query}`, controlador.signal);
      if (actual !== version) return;
      mostrar(data, r); aviso('Consulta completada.');
    } catch (err) { if (actual === version && err.name !== 'AbortError') aviso(err.message || 'No fue posible consultar. Intenta nuevamente.', true); }
    finally { if (actual === version) { controlador = null; habilitar(); $('resultados').setAttribute('aria-busy', 'false'); } }
  });
  $('reporte').addEventListener('change', filtros);
  $('reintentar').addEventListener('click', cargarCatalogos);
  $('cerrar-carta').addEventListener('click', () => $('carta-dialogo').close());
  $('imprimir-carta').addEventListener('click', () => { document.body.classList.add('imprimir-carta'); window.print(); });
  window.addEventListener('afterprint', () => document.body.classList.remove('imprimir-carta', 'imprimir-reporte'));
  async function iniciar() {
    try {
      const data = await leer('/api/reportes'); definiciones = data.reportes; hoy = data.fechaGuatemala;
      $('reporte').replaceChildren(...definiciones.map(r => new Option(`${String(r.id).padStart(2, '0')}. ${r.titulo}`, r.id)));
      $('reporte').disabled = false; filtros(); await cargarCatalogos();
    } catch { aviso('No se pudo cargar el módulo. Recarga la página para intentarlo de nuevo.', true); }
  }
  iniciar();
})();
