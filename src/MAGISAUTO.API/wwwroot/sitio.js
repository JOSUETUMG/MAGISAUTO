'use strict';
(() => {
  const crear = (tag, texto, clase) => { const n = document.createElement(tag); if (texto) n.textContent = texto; if (clase) n.className = clase; return n; };
  const grupos = [
    ['Inventario', [['/', 'Marcas'], ['/lineas.html', 'Líneas de vehículos'], ['/vehiculos.html', 'Vehículos']]],
    ['Personas', [['/clientes.html', 'Clientes'], ['/fiadores.html', 'Fiadores'], ['/vendedores.html', 'Vendedores'], ['/consultas-integradas.html', 'Personas y vínculos']]],
    ['Financiamiento', [['/creditos.html', 'Créditos'], ['/pagos.html', 'Pagos y abonos']]],
    ['Administración', [['/agencias.html', 'Agencias'], ['/auxiliares.html', 'Catálogos auxiliares'], ['/parametros.html', 'Parámetros del crédito']]]
  ];
  const ruta = location.pathname === '/index.html' ? '/' : location.pathname;
  const nav = document.querySelector('nav.catalogos');
  if (nav) {
    nav.replaceChildren(); nav.className = 'menu-principal'; nav.setAttribute('aria-label', 'Navegación principal');
    for (const [nombre, enlaces] of grupos) {
      const grupo = crear('details', '', 'menu-grupo'), titulo = crear('summary', nombre);
      if (enlaces.some(([url]) => url === ruta)) grupo.classList.add('grupo-actual');
      const lista = crear('div', '', 'menu-enlaces');
      for (const [url, texto] of enlaces) { const a = crear('a', texto); a.href = url; if (url === ruta) a.setAttribute('aria-current', 'page'); lista.append(a); }
      grupo.append(titulo, lista); nav.append(grupo);
      grupo.addEventListener('toggle', () => { if (grupo.open) for (const otro of nav.querySelectorAll('details')) if (otro !== grupo) otro.open = false; });
    }
    const reportes = crear('a', 'Consultas y reportes', 'menu-reportes'); reportes.href = '/reportes.html';
    if (ruta === '/reportes.html') reportes.setAttribute('aria-current', 'page'); nav.append(reportes);
    document.addEventListener('click', e => { if (!nav.contains(e.target)) nav.querySelectorAll('details').forEach(d => d.open = false); });
    nav.addEventListener('keydown', e => { if (e.key === 'Escape') { const d = e.target.closest('details'); if (d) { d.open = false; d.querySelector('summary').focus(); } } });
  }
  for (const a of document.querySelectorAll('main > p > a')) {
    const tarjetas = {
      '/consultas-integradas.html': ['Personas y vínculos', 'Busca contactos, referencias y asignaciones en un solo lugar.'],
      '/parametros.html': ['Parámetros del crédito', 'Consulta las condiciones vigentes y prepara nuevas configuraciones.']
    };
    if (tarjetas[a.getAttribute('href')]) {
      const [titulo, descripcion] = tarjetas[a.getAttribute('href')];
      a.className = 'acceso-modulo'; a.replaceChildren(crear('strong', titulo), crear('span', descripcion), crear('b', 'Abrir →'));
    }
  }
  const regreso = {'/consultas-integradas.html': ['/reportes.html', 'Volver a consultas y reportes'], '/parametros.html': ['/auxiliares.html', 'Volver a administración']};
  if (regreso[ruta]) { const [url, texto] = regreso[ruta], a = crear('a', '← ' + texto, 'regreso'); a.href = url; nav?.after(a); }
  // Reutilizar el botón existente conserva los bloqueos de guardado y la limpieza
  // de cada módulo; cerrar desde arriba no salta esas reglas.
  function prepararDialogos() {
    for (const dialogo of document.querySelectorAll('dialog:not([data-cierre-visible])')) {
      const original = [...dialogo.querySelectorAll('button')].find(b => /^(cerrar|cancelar|conservar|volver)/.test(b.id));
      if (!original) continue;
      dialogo.dataset.cierreVisible = 'true';
      const barra = crear('div', '', 'cierre-superior'), cerrar = crear('button', 'Cerrar ×', 'secundario');
      cerrar.type = 'button'; cerrar.setAttribute('aria-label', 'Cerrar ventana');
      cerrar.addEventListener('click', () => { if (!original.disabled) original.click(); });
      const sincronizar = () => { cerrar.disabled = original.disabled; };
      new MutationObserver(sincronizar).observe(original, { attributes: true, attributeFilter: ['disabled'] }); sincronizar();
      barra.append(cerrar); dialogo.prepend(barra);
    }
  }
  prepararDialogos(); new MutationObserver(prepararDialogos).observe(document.body, { childList: true, subtree: true });
  const expediente = document.getElementById('expediente'), volver = document.getElementById('volver');
  if (expediente && volver) {
    const pie = crear('div', '', 'regreso-expediente'), boton = crear('button', '← Volver al listado sin guardar', 'secundario');
    boton.type = 'button'; boton.addEventListener('click', () => { if (!volver.disabled) volver.click(); }); pie.append(boton); expediente.append(pie);
    new MutationObserver(() => boton.disabled = volver.disabled).observe(volver, { attributes: true, attributeFilter: ['disabled'] });
  }
})();
