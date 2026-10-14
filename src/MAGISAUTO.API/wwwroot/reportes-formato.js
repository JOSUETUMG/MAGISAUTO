/* El dinero llega como texto: se agrupa sin convertirlo a Number ni perder centavos. */
const FormatoReportes = (() => {
  function decimal(valor, porcentaje = false) {
    const s = String(valor);
    if (!/^-?\d+(\.\d+)?$/.test(s)) return s;
    const negativo = s.startsWith('-');
    let [entero, fraccion = ''] = s.replace(/^-/, '').split('.');
    if (porcentaje) {
      entero = (entero + fraccion.padEnd(2, '0').slice(0, 2)).replace(/^0+(?=\d)/, '');
      fraccion = fraccion.slice(2).replace(/0+$/, '');
    } else fraccion = fraccion.padEnd(2, '0');
    return (negativo ? '-' : '') + (porcentaje ? '' : 'Q') + entero.replace(/\B(?=(\d{3})+(?!\d))/g, ',')
      + (fraccion ? '.' + fraccion : '') + (porcentaje ? '%' : '');
  }
  function celda(valor, columna) {
    if (valor === null || valor === undefined) return 'Sin dato';
    if (columna.tipo === 'decimal') return decimal(valor, /^(Tasa|Porcentaje)/.test(columna.nombre));
    if (columna.tipo === 'booleano' || ['VigenteAlCorte', 'GarantiaInsuficiente', 'Anulado'].includes(columna.nombre))
      return valor === true || String(valor) === '1' ? 'Sí' : 'No';
    return String(valor);
  }
  return { decimal, celda };
})();
if (typeof module !== 'undefined') module.exports = FormatoReportes;
