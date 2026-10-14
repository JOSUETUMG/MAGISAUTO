// Requiere Playwright; servidor local iniciado con la compilación del módulo.
const { chromium, expect } = require('playwright/test');
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const output = path.join(__dirname, '..', 'artifacts', 'verificacion-agencias');
fs.mkdirSync(output, { recursive: true });
const url = process.env.MAGISAUTO_URL || 'http://localhost:5164';
const name = `Ensayo interfaz ${Date.now()}`;
const results = [];
const record = Prueba => results.push({ Prueba, Resultado: 'Correcto' });

(async () => {
  let browser, context, code;
  let estado = 'Fallido';
  try {
    browser = await chromium.launch({ channel: 'msedge', headless: true, timeout: 15000 });
    context = await browser.newContext({ viewport: { width: 1365, height: 900 } });
    const page = await context.newPage();
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    const beforeResponse = await context.request.get(`${url}/api/catalogos/agencias`);
    assert.equal(beforeResponse.status(), 200);
    const before = await beforeResponse.json();
    await page.goto(`${url}/agencias.html`);
    await expect(page.locator('#filas tr')).toHaveCount(before.length);
    record('Listado cargado desde SQL en navegador');
    await page.screenshot({ path: path.join(output, 'agencias-escritorio.png'), fullPage: true });
    await page.getByRole('button', { name: 'Agregar agencia' }).click();
    assert(await page.locator('#codigo').evaluate(el => el.readOnly));
    record('Código automático no editable');
    await page.locator('#nombre').fill(name);
    await page.locator('#region').fill('   ');
    await page.getByRole('button', { name: 'Guardar agencia' }).click();
    assert(await page.locator('#region').evaluate(el => !el.checkValidity()));
    record('Región de espacios rechazada en pantalla');
    await page.locator('#region').fill('Oriente');
    await page.screenshot({ path: path.join(output, 'agencias-formulario.png'), fullPage: true });
    const response = page.waitForResponse(r => r.request().method() === 'POST' && r.url().endsWith('/api/catalogos/agencias'));
    await page.getByRole('button', { name: 'Guardar agencia' }).click();
    const inserted = await response;
    assert.equal(inserted.status(), 201);
    code = (await inserted.json()).codigoAgencia;
    await expect(page.locator('#editor')).not.toBeVisible();
    await expect(page.locator('#filas')).toContainText(name);
    record('Alta desde formulario con código devuelto por SQL');
    await page.locator('#criterio').fill(name);
    await page.getByRole('button', { name: 'Buscar', exact: true }).click();
    await expect(page.locator('#filas tr')).toHaveCount(1);
    record('Búsqueda desde pantalla');
    await page.getByRole('button', { name: `Editar ${name}, código ${code}`, exact: true }).click();
    const edited = `${name} <b>literal</b>`;
    await page.locator('#nombre').fill(edited);
    await page.locator('#region').fill('Región Centro');
    await page.getByRole('button', { name: 'Guardar agencia' }).click();
    await expect(page.locator('#editor')).not.toBeVisible();
    await expect(page.locator('#filas')).toContainText(edited);
    await expect(page.locator('#filas b')).toHaveCount(0);
    await expect(page.locator('#filas')).toContainText('Región Centro');
    record('Edición de ambos campos y HTML mostrado como texto');
    await page.getByRole('button', { name: `Eliminar ${edited}, código ${code}`, exact: true }).click();
    await page.getByRole('button', { name: 'Conservar agencia' }).click();
    await expect(page.locator('#filas')).toContainText(edited);
    record('Cancelar eliminación conserva registro');
    await page.getByRole('button', { name: `Eliminar ${edited}, código ${code}`, exact: true }).click();
    await page.getByRole('button', { name: 'Eliminar agencia', exact: true }).click();
    await expect(page.locator('#confirmacion')).not.toBeVisible();
    await expect(page.locator('#filas tr')).toHaveCount(before.length);
    code = null;
    record('Eliminación confirmada y listado restaurado');
    await page.locator('#criterio').fill(name);
    await page.getByRole('button', { name: 'Buscar', exact: true }).click();
    await expect(page.locator('#filas tr')).toHaveCount(0);
    await expect(page.locator('#vacio')).toBeVisible();
    record('Estado sin coincidencias');
    await page.getByRole('button', { name: 'Ver todas' }).click();
    await expect(page.locator('#filas tr')).toHaveCount(before.length);
    await page.setViewportSize({ width: 390, height: 844 });
    await page.screenshot({ path: path.join(output, 'agencias-movil.png'), fullPage: true });
    assert(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth));
    record('Página sin desbordamiento horizontal a 390px');
    assert.deepEqual(errors, []);
    record('Sin errores JavaScript en el recorrido');
    const after = await (await context.request.get(`${url}/api/catalogos/agencias`)).json();
    assert.deepEqual(after, before);
    record('Datos iniciales conservados');
    estado = 'Correcto';
  } finally {
    try {
      if (code && context) {
        const cleanup = await context.request.delete(`${url}/api/catalogos/agencias/${code}`);
        assert.equal(cleanup.status(), 204, `Limpieza pendiente de agencia temporal ${code}`);
      }
    } finally {
      if (browser) await browser.close();
      fs.writeFileSync(path.join(output, 'resultado-interfaz.json'), JSON.stringify({ Estado: estado, Fecha: new Date().toISOString(), Pruebas: results }, null, 2));
    }
  }
  console.log(`Comprobaciones de interfaz correctas: ${results.length}`);
})().catch(error => { console.error(error.message); process.exitCode = 1; });
