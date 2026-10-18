const {JSDOM}=require('../artifacts/diseno-dom/node_modules/jsdom');
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'../src/MAGISAUTO.API/wwwroot'),checks=[];
const ok=(n,b)=>{assert.ok(b,n);checks.push({Prueba:n,Resultado:'Correcto'});};
const wait=async f=>{for(let i=0;i<100;i++){if(f())return;await new Promise(r=>setTimeout(r,10));}throw Error('Espera agotada');};
const response=(x,status=200)=>({ok:status<400,status,json:async()=>x});
function page(name){const dom=new JSDOM(fs.readFileSync(path.join(root,name+'.html'),'utf8'),{url:'http://localhost/'+name+'.html',runScripts:'outside-only'});const w=dom.window;w.HTMLDialogElement.prototype.showModal=function(){this.open=true;};w.HTMLDialogElement.prototype.close=function(){this.open=false;};return dom;}
(async()=>{
 const dom=page('pagos'),w=dom.window,d=w.document;
 let removed=false,requests=0,decision=false,prompt='',release;
 const payment={codigoPago:'9007199254740993',comprobante:'17',numeroCredito:'ENSAYO-01',cliente:'Temporal',cuota:1,monto:'1000.00',fechaPago:'2026-10-16T10:00:00',fechaAnulacion:'2026-10-17T10:00:00',estado:'ANULADO',medioPago:'Efectivo',capital:'900',interes:'100',manejoCuenta:'0',seguroAuto:'0',seguroVida:'0',comisionEfectiva:'0'};
 w.confirm=s=>{prompt=s;return decision;};
 w.fetch=async(url,opts={})=>{
  if(opts.method==='DELETE'){requests++;ok('Identificador bigint intacto',url.endsWith('/9007199254740993'));return new Promise(resolve=>release=()=>{removed=true;resolve(response(null,204));});}
  if(url.endsWith('/catalogos'))return response({creditos:[],tiposPago:[]});
  if(url.includes('?'))return response(removed?[]:[payment]);
  return response(payment);
 };
 w.eval(fs.readFileSync(path.join(root,'pagos.js'),'utf8')+'\nwindow.__pintar=pintarRecibo;');
 await wait(()=>d.querySelector('#filas button'));d.querySelector('#filas button').click();await wait(()=>d.getElementById('recibo').open);
 const btn=d.getElementById('eliminar-pago');ok('Anulado muestra eliminar y oculta anular',!btn.hidden&&d.getElementById('anular').hidden);
 btn.click();ok('Cancelar no envia DELETE',requests===0);ok('Confirmacion explica perdida historica',prompt.includes('cortes anteriores')&&prompt.includes('No se puede deshacer'));
 decision=true;btn.click();btn.click();ok('Envio unico y controles bloqueados',requests===1&&btn.disabled&&d.getElementById('cerrar-recibo').disabled);
 release();await wait(()=>d.getElementById('contador').textContent==='0 pago(s)');ok('Recibo cerrado y lista actualizada',!d.getElementById('recibo').open);ok('Mensaje de borrado historico',d.getElementById('aviso').textContent.includes('históricos'));
 w.__pintar({...payment,fechaAnulacion:null,estado:'EFECTIVO'});ok('Pago efectivo oculta eliminar',btn.hidden&&!d.getElementById('anular').hidden);btn.click();ok('Guardia impide borrar efectivo',requests===1);dom.window.close();
 const veh=page('vehiculos'),v=veh.window,vd=v.document;
 v.fetch=async url=>response(url.includes('catalogos')?{marcas:[],lineas:[],tiposGarantia:[]}:[]);
 v.eval(fs.readFileSync(path.join(root,'vehiculos.js'),'utf8')+'\nwindow.__abrir=abrirValoraciones;');
 v.__abrir({codigoGarantia:1,marca:'Toyota',linea:'Corolla',vin:'TEMPORAL',tieneHistorialContractual:false});
 ok('Vehiculo libre permite registrar valoracion',!vd.getElementById('nueva-valoracion').disabled);
 ok('Ayuda distingue valoracion previa y contractual',vd.getElementById('aviso-valoraciones').textContent.includes('valoraciones previas'));
 vd.getElementById('nueva-valoracion').click();ok('Formulario previo abre y tiene cancelar',vd.getElementById('editor-valoracion').open&&!!vd.getElementById('cancelar-valoracion'));vd.getElementById('cancelar-valoracion').click();ok('Cancelar valoracion cierra',!vd.getElementById('editor-valoracion').open);
 await new Promise(r=>setTimeout(r,30));veh.window.close();
 fs.mkdirSync(path.resolve(__dirname,'../artifacts/verificacion-crud-entrega'),{recursive:true});fs.writeFileSync(path.resolve(__dirname,'../artifacts/verificacion-crud-entrega/dom.json'),JSON.stringify({Estado:'Correcto',Alcance:'DOM con API simulada; no certifica renderizado ni reemplaza HTTP/SQL',Pruebas:checks},null,2));console.log(checks.length+' comprobaciones DOM correctas.');
})().catch(e=>{console.error(e);process.exitCode=1;});
