'use strict';
(() => {
  const $ = id => document.getElementById(id);
  let definiciones = [], hoy = '', catalogos = null, catalogosCargando = false, version = 0, controlador = null;
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
    for (const t of data.tablas) {
      const seccion = nodo('section', undefined, 'panel resultado-tabla'), resumen = nodo('div', undefined, 'resumen');
      resumen.append(nodo('h3', t.titulo), nodo('span', `${t.filas.length} fila(s)`)); seccion.append(resumen);
      if (!t.filas.length) seccion.append(nodo('p', 'No hay resultados para estos filtros.', 'vacio'));
      else {
        const cont = nodo('div', undefined, 'tabla-contenedor'); cont.tabIndex = 0; cont.setAttribute('role', 'region'); cont.setAttribute('aria-label', t.titulo + '. Desplázate horizontalmente para ver todas las columnas.');
        const tabla = nodo('table'), thead = nodo('thead'), tr = nodo('tr');
        for (const c of t.columnas) { const th = nodo('th', tituloColumna(c.nombre), c.tipo === 'decimal' ? 'numero' : ''); th.scope = 'col'; tr.append(th); }
        if (data.id === 5) { const th = nodo('th', 'Carta'); th.scope = 'col'; tr.append(th); }
        thead.append(tr); tabla.append(thead); const tbody = nodo('tbody');
        for (const fila of t.filas) {
          const row = nodo('tr');
          for (const c of t.columnas) {
            const clase = c.tipo === 'decimal' || c.tipo === 'entero' ? 'numero' : c.tipo === 'texto' ? 'texto-largo' : '';
            row.append(nodo('td', FormatoReportes.celda(fila[c.nombre], c), clase));
          }
          if (data.id === 5) {
            const td = nodo('td'), b = nodo('button', 'Ver carta', 'secundario'); b.type = 'button';
            b.addEventListener('click', () => abrirCarta(fila, data, b)); td.append(b); row.append(td);
          }
          tbody.append(row);
        }
        tabla.append(tbody); cont.append(tabla); seccion.append(cont);
        seccion.append(nodo('p', 'Desplázate horizontalmente para ver todas las columnas. «Sin dato» no equivale a cero.', 'nota'));
      }
      panel.append(seccion);
    }
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
  window.addEventListener('afterprint', () => document.body.classList.remove('imprimir-carta'));
  async function iniciar() {
    try {
      const data = await leer('/api/reportes'); definiciones = data.reportes; hoy = data.fechaGuatemala;
      $('reporte').replaceChildren(...definiciones.map(r => new Option(`${String(r.id).padStart(2, '0')}. ${r.titulo}`, r.id)));
      $('reporte').disabled = false; filtros(); await cargarCatalogos();
    } catch { aviso('No se pudo cargar el módulo. Recarga la página para intentarlo de nuevo.', true); }
  }
  iniciar();
})();
