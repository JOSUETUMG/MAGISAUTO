// Pruebas de límites monetarios y estados; no requieren navegador ni conexión SQL.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { decimal, celda } = require('../src/MAGISAUTO.API/wwwroot/reportes-formato.js');
const pruebas = [];
function verificar(nombre, valor, esperado) {
  assert.equal(valor, esperado, nombre);
  pruebas.push({ Prueba: nombre, Resultado: 'Correcto' });
}
verificar('Monto mayor al entero seguro mantiene centavos', decimal('9999999999999999.99'), 'Q9,999,999,999,999,999.99');
verificar('Total agregado de alta precisión conserva dígitos', decimal('123456789012345678901234567890123456.78'), 'Q123,456,789,012,345,678,901,234,567,890,123,456.78');
verificar('Reversión neta negativa', decimal('-6311.63'), '-Q6,311.63');
verificar('Centavo', decimal('0.01'), 'Q0.01');
verificar('Cero monetario', decimal('0'), 'Q0.00');
verificar('Tasa anual fraccionaria', decimal('0.125000', true), '12.5%');
verificar('Tasa de seguro pequeña', decimal('0.000500', true), '0.05%');
verificar('Comisión dos por ciento', decimal('0.020000', true), '2%');
verificar('Tasa cero', decimal('0.000000', true), '0%');
verificar('Nulo no se convierte a dinero cero', celda(null, { tipo: 'decimal', nombre: 'SaldoPendiente' }), 'Sin dato');
verificar('Recibo bigint conserva todos sus dígitos', celda('9223372036854775807', { tipo: 'entero', nombre: 'Comprobante' }), '9223372036854775807');
verificar('Pago histórico efectivo', celda(1, { tipo: 'entero', nombre: 'VigenteAlCorte' }), 'Sí');
verificar('Pago histórico no efectivo', celda(0, { tipo: 'entero', nombre: 'VigenteAlCorte' }), 'No');
verificar('Fecha SQL no cambia de zona horaria', celda('2026-10-13 00:01:00', { tipo: 'fechaHora', nombre: 'FechaPago' }), '2026-10-13 00:01:00');
verificar('Tasa recibe formato porcentual', celda('0.125000', { tipo: 'decimal', nombre: 'TasaAnual' }), '12.5%');
const salida = path.join(__dirname, '..', 'artifacts', 'verificacion-reportes');
fs.mkdirSync(salida, { recursive: true });
fs.writeFileSync(path.join(salida, 'formato.json'), JSON.stringify({ Estado: 'Correcto', Pruebas: pruebas }, null, 2) + '\n');
console.log(`Formato de reportes: ${pruebas.length} comprobaciones correctas.`);
