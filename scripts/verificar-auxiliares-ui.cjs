// UI real con respuestas HTTP simuladas; la integración SQL se prueba en el script .ps1.
const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const [url, salida] = process.argv.slice(2);
const pruebas = [];
let browser;
function comprobar(nombre, valor) { assert.ok(valor, nombre); pruebas.push(nombre); }
(async () => {
  const definiciones = await (await fetch(`${url}/api/catalogos/auxiliares`)).json();
  const datos = Object.fromEntries(definiciones.map(d => [d.id, [{ codigo: 1, descripcion: `Registro ${d.nombre}`, codigoDepartamento: d.usaDepartamento ? 1 : null, requiereReferencia: d.usaReferenciaBancaria ? false : null }]]));
  datos.departamentos = [{ codigo: 1, descripcion: 'Departamento A', codigoDepartamento: null, requiereReferencia: null }, { codigo: 2, descripcion: 'Departamento B', codigoDepartamento: null, requiereReferencia: null }];
  datos.municipios.push({ codigo: 1, descripcion: 'Municipio B', codigoDepartamento: 2, requiereReferencia: null });
  let fallarLectura = false, retrasar = false, llegoLenta = false;
  browser = await chromium.launch({ channel: 'msedge', headless: true });
  const page = await browser.newPage({ viewport: { width: 1366, height: 900 }, locale: 'es-GT' });
  const errores = []; page.on('pageerror', e => errores.push(e.message));
  await page.route('**/api/catalogos/auxiliares**', async route => {
    const req = route.request(), u = new URL(req.url()), partes = u.pathname.split('/').filter(Boolean), slug = partes[3];
    const responder = (status, objeto) => route.fulfill({ status, contentType: 'application/json', body: status === 204 ? '' : JSON.stringify(objeto) });
    if (!slug) return responder(200, definiciones);
    const d = definiciones.find(d => d.id === slug), id = Number(partes[4]), dep = Number(u.searchParams.get('codigoDepartamento'));
    if (req.method() === 'GET') {
      if (fallarLectura) { fallarLectura = false; return responder(503, { detail: 'No fue posible consultar la base de datos.' }); }
      let filas = datos[slug].map(f => ({ ...f }));
      if (dep) filas = filas.filter(f => f.codigoDepartamento === dep);
      const criterio = u.searchParams.get('criterio');
      if (criterio === 'lenta' && retrasar) {
        llegoLenta = true; await new Promise(r => setTimeout(r, 700));
        try { return await responder(200, [{ codigo: 999, descripcion: 'RESULTADO ANTIGUO', codigoDepartamento: null, requiereReferencia: null }]); } catch { return; }
      }
      if (criterio) filas = filas.filter(f => `${f.codigo} ${f.descripcion}`.toLowerCase().includes(criterio.toLowerCase()));
      return responder(200, filas);
    }
    const body = req.method() === 'DELETE' ? null : req.postDataJSON();
    if (req.method() === 'POST') {
      if (datos[slug].some(f => f.codigo === body.codigo && (!d.usaDepartamento || f.codigoDepartamento === body.codigoDepartamento))) return responder(409, { detail: 'Ese código ya existe en el catálogo.' });
      const fila = { codigo: body.codigo, descripcion: body.descripcion, codigoDepartamento: body.codigoDepartamento ?? null, requiereReferencia: body.requiereReferencia ?? null };
      datos[slug].push(fila); return responder(201, fila);
    }
    const indice = datos[slug].findIndex(f => f.codigo === id && (!d.usaDepartamento || f.codigoDepartamento === dep));
    if (req.method() === 'PUT') { Object.assign(datos[slug][indice], body); return responder(200, datos[slug][indice]); }
    if (id === 1) return responder(409, { detail: 'No se puede eliminar: el registro está relacionado con otros datos.' });
    datos[slug].splice(indice, 1); return responder(204, null);
  });
  await page.goto(`${url}/auxiliares.html`);
  const listo = () => page.waitForFunction(() => document.querySelector('#resultados').getAttribute('aria-busy') === 'false' && !document.querySelector('#nuevo').disabled);
  const seleccionar = async slug => { await page.selectOption('#catalogo', slug); await listo(); };
  await listo();
  comprobar('Selector con siete catálogos', await page.locator('#catalogo option').count() === 7);
  for (const d of definiciones) {
    await seleccionar(d.id);
    comprobar(`Título ${d.nombre}`, await page.locator('#titulo-catalogo').textContent() === d.nombre);
    await page.click('#nuevo');
    comprobar(`Campos específicos ${d.id}`, await page.locator('#campo-departamento').isVisible() === d.usaDepartamento && await page.locator('#campo-referencia').isVisible() === d.usaReferenciaBancaria);
    if (d.usaDepartamento) await page.selectOption('#departamento', '2');
    if (d.usaReferenciaBancaria) await page.selectOption('#requiere-referencia', 'false');
    await page.fill('#codigo', '200'); await page.fill('#descripcion', 'Prueba <b>texto</b>');
    await page.click('#guardar'); await page.waitForFunction(() => !document.querySelector('#editor').open); await listo();
    let fila = page.locator('#filas tr').filter({ hasText: 'Prueba <b>texto</b>' });
    comprobar(`Alta visible sin interpretar HTML ${d.id}`, await fila.count() === 1 && await fila.locator('b').count() === 0);
    if (d.usaReferenciaBancaria) comprobar('Opción No se envía como false', datos[d.id].find(f => f.codigo === 200).requiereReferencia === false);
    if (d.usaDepartamento) comprobar('Alta municipal conserva departamento seleccionado', await page.inputValue('#filtro-departamento') === '2');
    await fila.getByRole('button', { name: /^Editar / }).click();
    comprobar(`Clave inmutable ${d.id}`, await page.locator('#codigo').evaluate(e => e.readOnly));
    if (d.usaDepartamento) comprobar('Departamento inmutable al editar municipio', await page.locator('#departamento').isDisabled());
    await page.fill('#descripcion', 'Actualizado');
    if (d.usaReferenciaBancaria) await page.selectOption('#requiere-referencia', 'true');
    await page.click('#guardar'); await page.waitForFunction(() => !document.querySelector('#editor').open); await listo();
    comprobar(`Edición visible ${d.id}`, await page.locator('#filas tr').filter({ hasText: 'Actualizado' }).count() === 1);
    await page.fill('#criterio', 'Actualizado'); await page.click('#buscar'); await listo();
    comprobar(`Búsqueda ${d.id}`, await page.locator('#filas tr').count() === 1);
    await page.locator('#filas tr').getByRole('button', { name: /^Eliminar / }).click();
    await page.click('#conservar');
    comprobar(`Cancelar eliminación conserva ${d.id}`, datos[d.id].some(f => f.codigo === 200));
    await page.locator('#filas tr').getByRole('button', { name: /^Eliminar / }).click();
    await page.click('#eliminar'); await page.waitForFunction(() => !document.querySelector('#confirmacion').open); await listo();
    comprobar(`Eliminación y resultado vacío ${d.id}`, !datos[d.id].some(f => f.codigo === 200) && await page.locator('#vacio').isVisible());
    await page.click('#todos'); await listo();
    comprobar(`Ver todos ${d.id}`, await page.locator('#filas tr').count() >= 1 && await page.inputValue('#criterio') === '');
  }
  await seleccionar('municipios');
  comprobar('Dos municipios con igual código identificados por departamento', await page.locator('#filas tr').count() === 2 && (await page.locator('#filas').textContent()).includes('Departamento B'));
  await page.selectOption('#filtro-departamento', '1'); await listo();
  comprobar('Filtro municipal no muestra otro departamento', await page.locator('#filas tr').count() === 1 && !(await page.locator('#filas').textContent()).includes('Departamento B'));
  await page.screenshot({ path: path.join(salida, 'auxiliares-escritorio.png'), fullPage: true });
  await seleccionar('tipos-pago'); await page.click('#nuevo');
  await page.fill('#codigo', '201'); await page.fill('#descripcion', 'Sin opción'); await page.click('#guardar');
  comprobar('Referencia bancaria exige elección explícita', await page.locator('#editor').evaluate(e => e.open) && !datos['tipos-pago'].some(f => f.codigo === 201));
  await page.keyboard.press('Escape');
  await seleccionar('departamentos'); await page.click('#nuevo');
  await page.fill('#codigo', '1'); await page.fill('#descripcion', 'Duplicado'); await page.click('#guardar');
  await page.locator('#error-editor').waitFor({ state: 'visible' });
  comprobar('Duplicado conserva diálogo y datos', (await page.locator('#error-editor').textContent()).includes('ya existe') && await page.inputValue('#descripcion') === 'Duplicado');
  await page.fill('#descripcion', '   '); await page.click('#guardar');
  comprobar('Descripción de espacios rechazada', await page.locator('#descripcion').evaluate(e => !e.validity.valid));
  await page.keyboard.press('Escape');
  await page.locator('#filas tr').first().getByRole('button', { name: /^Eliminar / }).click(); await page.click('#eliminar');
  await page.locator('#error-eliminar').waitFor({ state: 'visible' });
  comprobar('Dependencia informa y conserva registro', (await page.locator('#error-eliminar').textContent()).includes('relacionado') && datos.departamentos.some(f => f.codigo === 1));
  await page.click('#conservar');
  fallarLectura = true; await page.click('#todos');
  await page.waitForFunction(() => document.querySelector('#contador').textContent === 'No disponible');
  comprobar('Error de conexión elimina resultados anteriores', await page.locator('#filas tr').count() === 0 && await page.locator('#nuevo').isDisabled());
  await page.click('#todos'); await listo();
  comprobar('Reintentar lectura recupera registros', await page.locator('#filas tr').count() === 2);
  retrasar = true; await page.fill('#criterio', 'lenta'); await page.click('#buscar');
  await new Promise(r => setTimeout(r, 100)); comprobar('Solicitud lenta enviada', llegoLenta);
  await seleccionar('tipos-telefono'); await new Promise(r => setTimeout(r, 800));
  comprobar('Respuesta antigua no sobrescribe catálogo nuevo', !(await page.locator('#filas').textContent()).includes('RESULTADO ANTIGUO') && await page.inputValue('#catalogo') === 'tipos-telefono');
  await page.locator('#nuevo').focus(); await page.keyboard.press('Enter');
  comprobar('Abrir formulario con teclado', await page.locator('#editor').evaluate(e => e.open));
  await page.keyboard.press('Escape');
  comprobar('Escape cierra formulario', !await page.locator('#editor').evaluate(e => e.open));
  await page.setViewportSize({ width: 390, height: 844 }); await seleccionar('municipios');
  comprobar('Móvil sin desbordamiento de página', await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth));
  await page.screenshot({ path: path.join(salida, 'auxiliares-movil.png'), fullPage: true });
  await page.click('#nuevo');
  comprobar('Diálogo móvil cabe en pantalla', await page.locator('#editor').evaluate(e => e.getBoundingClientRect().width <= innerWidth));
  await page.screenshot({ path: path.join(salida, 'auxiliares-formulario-movil.png'), fullPage: true });
  comprobar('Sin excepciones JavaScript', errores.length === 0);
  fs.writeFileSync(path.join(salida, 'interfaz.json'), JSON.stringify({ estado: 'Correcto', fecha: new Date().toISOString(), navegador: 'Edge headless', alcance: 'Página real con HTTP simulado; SQL validado por separado', pruebas }, null, 2));
  console.log(`Interfaz: ${pruebas.length} comprobaciones correctas.`);
})().catch(e => {
  fs.writeFileSync(path.join(salida, 'interfaz.json'), JSON.stringify({ estado: 'Fallido', fecha: new Date().toISOString(), error: e.message, pruebas }, null, 2));
  console.error(e.message); process.exitCode = 1;
}).finally(async () => { if (browser) await browser.close(); });
