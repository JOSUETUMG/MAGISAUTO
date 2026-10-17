// Prueba de DOM y lógica, no de renderizado ni de disposición visual real.
// Instalar jsdom en artifacts/diseno-dom para ejecutar. API de prueba: loopback/base aislada.
const {JSDOM}=require('../artifacts/diseno-dom/node_modules/jsdom');
const fs=require('node:fs'), path=require('node:path'), assert=require('node:assert/strict');
const root=path.resolve(__dirname,'../src/MAGISAUTO.API/wwwroot');
const base=process.env.MAGIS_TEST_URL || 'http://127.0.0.1:5189';
assert.match(base,/^http:\/\/(127\.0\.0\.1|localhost):\d+$/);
const pruebas=[];
function ok(nombre,condicion){assert.ok(condicion,nombre);pruebas.push({Prueba:nombre,Resultado:'Correcto'});}
const tick=()=>new Promise(r=>setTimeout(r,15));
async function esperar(f){for(let i=0;i<300;i++){if(f())return;await tick();}throw new Error('Tiempo de espera agotado');}
function entorno(nombre){
 const dom=new JSDOM(fs.readFileSync(path.join(root,nombre),'utf8'),{url:base+'/'+nombre,runScripts:'outside-only'});
 const w=dom.window;w.HTMLElement.prototype.scrollIntoView=function(){};
 w.HTMLDialogElement.prototype.showModal=function(){this.open=true;};
 w.HTMLDialogElement.prototype.close=function(){this.open=false;this.dispatchEvent(new w.Event('close'));};
 w.fetch=(url,opts)=>fetch(new URL(url,base),opts);w.AbortController=AbortController;w.Blob=Blob;
 w.print=()=>w.dispatchEvent(new w.Event('afterprint'));
 return dom;
}
(async()=>{
 for(const nombre of fs.readdirSync(root).filter(n=>n.endsWith('.html'))){
  const dom=entorno(nombre),w=dom.window,d=w.document;w.eval(fs.readFileSync(path.join(root,'sitio.js'),'utf8'));await tick();
  ok(nombre+': cuatro grupos y acceso a reportes',d.querySelectorAll('.menu-grupo').length===4 && d.querySelectorAll('.menu-reportes').length===1);
  ok(nombre+': trece destinos y página actual',d.querySelectorAll('.menu-principal a').length===13 && d.querySelectorAll('.menu-principal [aria-current="page"]').length===1);
  const identidad=[...d.querySelectorAll('link[rel="stylesheet"]')].some(link=>new URL(link.href).pathname==='/identidad.css');
  ok(nombre+': recursos de identidad referenciados',identidad && !!d.querySelector('script[src="/sitio.js"]'));
  const grupos=d.querySelectorAll('details');grupos[0].open=true;await tick();grupos[1].open=true;await tick();ok(nombre+': un menú abierto',!grupos[0].open && grupos[1].open);
  grupos[1].querySelector('summary').dispatchEvent(new w.KeyboardEvent('keydown',{key:'Escape',bubbles:true}));ok(nombre+': Escape devuelve foco al menú',!grupos[1].open && d.activeElement===grupos[1].querySelector('summary'));
  for(const dialogo of d.querySelectorAll('dialog')){
   const original=[...dialogo.querySelectorAll('button')].find(b=>/^(cerrar|cancelar|conservar|volver)/.test(b.id));
   if(original){const cerrar=dialogo.querySelector('.cierre-superior button');ok(nombre+': cierre superior '+dialogo.id,!!cerrar);let pulsado=0;original.addEventListener('click',()=>pulsado++);cerrar.click();ok(nombre+': cierre reutiliza control '+dialogo.id,pulsado===1);original.disabled=true;await tick();cerrar.click();ok(nombre+': cierre respeta guardado '+dialogo.id,cerrar.disabled && pulsado===1);}
  }
  if(['auxiliares.html','reportes.html'].includes(nombre))ok(nombre+': acceso en tarjeta',!!d.querySelector('.acceso-modulo strong'));
  dom.window.close();
 }
 const dom=entorno('reportes.html'),w=dom.window,d=w.document;
 w.eval(fs.readFileSync(path.join(root,'reportes-formato.js'),'utf8')+'\n'+fs.readFileSync(path.join(root,'reportes.js'),'utf8'));w.eval(fs.readFileSync(path.join(root,'sitio.js'),'utf8'));
 try { await esperar(()=>!d.getElementById('reporte').disabled); } catch(e) { throw new Error(e.message+': '+d.getElementById('mensaje').textContent); }
 await esperar(()=>!d.getElementById('ejecutar').disabled);
 const definiciones=await (await fetch(base+'/api/reportes')).json();
 for(const reporte of definiciones.reportes){
  d.getElementById('reporte').value=reporte.id;d.getElementById('reporte').dispatchEvent(new w.Event('change'));
  for(const f of reporte.filtros){const control=d.getElementById('f-'+f.nombre);if(f.tipo==='fecha')control.value=f.nombre==='desde'?'2026-10-01':'2026-10-15';if(['cliente','credito'].includes(f.tipo)){await esperar(()=>control.options.length>1);control.selectedIndex=1;}}
  d.getElementById('consulta').dispatchEvent(new w.Event('submit',{cancelable:true}));await esperar(()=>d.getElementById('mensaje').textContent!=='Consultando…');
  ok('Reporte '+reporte.id+': resultado real HTTP representado ('+d.getElementById('mensaje').textContent+')',!d.getElementById('resultados').hidden && d.getElementById('resultados').textContent.includes(reporte.titulo));
  ok('Reporte '+reporte.id+': volver e imprimir disponibles',d.querySelectorAll('.herramientas-reporte button').length===2);
 }
 // Datos controlados para todos los límites de mora y el encadenamiento con plan.
 const columna=(nombre,tipo='texto')=>({nombre,tipo});
 const respuesta=json=>Promise.resolve({ok:true,json:async()=>json});
 const datos=(id,tabla)=>({id,titulo:'Ensayo '+id,nota:'Datos ficticios del ensayo DOM',filtros:{fechaCorte:'2026-10-15'},consultadoEnGuatemala:'2026-10-15',tablas:[tabla]});
 const rangos=['01-30','31-60','61-90','91 o mas'];
 let rutaPlan='',blobCSV;
 w.URL.createObjectURL=blob=>{blobCSV=blob;return 'blob:ensayo';};w.URL.revokeObjectURL=()=>{};
 w.HTMLAnchorElement.prototype.click=function(){};
 w.fetch=(url)=>{
  if(String(url).startsWith('/api/reportes/15?'))return respuesta(datos(15,{titulo:'Mora por rangos',columnas:[columna('Rango'),columna('Creditos','entero')],filas:rangos.map(Rango=>({Rango,Creditos:2}))}));
  if(String(url).startsWith('/api/reportes/2?'))return respuesta(datos(2,{titulo:'Mora',columnas:[columna('NumeroCredito'),columna('DiasMora','entero')],filas:[1,30,31,60,61,90,91,120].map(DiasMora=>({NumeroCredito:'C-'+DiasMora,DiasMora}))}));
  if(String(url).startsWith('/api/reportes/7?')){rutaPlan=String(url);return respuesta(datos(7,{titulo:'Plan',columnas:[columna('NumeroCredito')],filas:[{NumeroCredito:'C-1'}]}));}
  throw new Error('Ruta inesperada '+url);
 };
 d.getElementById('reporte').value=15;d.getElementById('reporte').dispatchEvent(new w.Event('change'));d.getElementById('f-fechaCorte').value='2026-10-15';
 d.getElementById('consulta').dispatchEvent(new w.Event('submit',{cancelable:true}));await esperar(()=>!d.getElementById('resultados').hidden);
 const botones=[...d.querySelectorAll('#resultados button')].filter(b=>b.textContent==='Ver créditos del rango');ok('Mora: acción solo en filas de rango',botones.length===4);
 for(let i=0;i<4;i++){
  botones[i].click();await esperar(()=>d.querySelector('dialog.detalle-reporte tbody'));
  let modal=d.querySelector('dialog.detalle-reporte');const filas=modal.querySelectorAll('tbody tr');ok('Rango '+rangos[i]+': dos límites correctos',filas.length===2 && filas[0].textContent.includes('C-'+[1,31,61,91][i]) && filas[1].textContent.includes('C-'+[30,60,90,120][i]));
  const exportar=[...modal.querySelectorAll('button')].find(b=>b.textContent==='Exportar CSV');exportar.click();ok('CSV del rango '+rangos[i]+': solo dos créditos',(await blobCSV.text()).split('\r\n').length===3);
  if(i===0){[...modal.querySelectorAll('button')].find(b=>b.textContent==='Ver plan').click();await esperar(()=>d.querySelectorAll('dialog.detalle-reporte').length===2);await tick();ok('Plan conserva crédito y fecha de corte',rutaPlan.includes('numeroCredito=C-1') && rutaPlan.includes('fechaCorte=2026-10-15'));const plan=[...d.querySelectorAll('dialog.detalle-reporte')].at(-1);[...plan.querySelectorAll('button')].find(b=>b.textContent==='Cerrar y volver').click();ok('Cerrar plan conserva rango abierto',modal.open && d.querySelectorAll('dialog.detalle-reporte').length===1);}
  [...modal.querySelectorAll('button')].find(b=>b.textContent==='Cerrar y volver').click();ok('Cerrar rango devuelve foco',d.activeElement===botones[i]);
 }
 // Una respuesta tardía del reporte anterior no debe sobreescribir la selección actual.
 let resolver;w.fetch=url=>String(url).startsWith('/api/reportes/1?')?new Promise(r=>resolver=r):respuesta(datos(2,{titulo:'Actual',columnas:[],filas:[]}));
 d.getElementById('reporte').value=1;d.getElementById('reporte').dispatchEvent(new w.Event('change'));d.getElementById('consulta').dispatchEvent(new w.Event('submit',{cancelable:true}));
 d.getElementById('reporte').value=2;d.getElementById('reporte').dispatchEvent(new w.Event('change'));d.getElementById('consulta').dispatchEvent(new w.Event('submit',{cancelable:true}));await tick();
 resolver({ok:true,json:async()=>datos(1,{titulo:'Obsoleto',columnas:[],filas:[]})});await tick();ok('Respuesta tardía descartada',d.getElementById('resultados').textContent.includes('Actual')&&!d.getElementById('resultados').textContent.includes('Obsoleto'));
 dom.window.close();
 fs.writeFileSync(path.resolve(__dirname,'../artifacts/diseno-dom/resultado.json'),JSON.stringify({Estado:'Correcto',Tipo:'DOM sin renderizado visual',Pruebas:pruebas},null,2));
 console.log(pruebas.length+' comprobaciones DOM correctas. No acreditan renderizado visual.');
})().catch(e=>{console.error(e);process.exit(1);});
