// DOM y peticiones del formulario; no certifica renderizado ni impresión.
const {JSDOM}=require('../artifacts/diseno-dom/node_modules/jsdom');
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const base=process.env.MAGIS_TEST_URL||'http://127.0.0.1:5191';
assert.match(base,/^http:\/\/(127\.0\.0\.1|localhost):\d+$/);
const root=path.resolve(__dirname,'../src/MAGISAUTO.API/wwwroot'),pruebas=[];
const ok=(n,v)=>{assert.ok(v,n);pruebas.push({Prueba:n,Resultado:'Correcto'});};
const esperar=async f=>{for(let i=0;i<400;i++){if(f())return;await new Promise(r=>setTimeout(r,15));}throw Error('Espera agotada');};
(async()=>{
 const dom=new JSDOM(fs.readFileSync(path.join(root,'consultas-integradas.html'),'utf8'),{url:base+'/consultas-integradas.html',runScripts:'outside-only'});
 const w=dom.window,d=w.document;let envio,liberar;
 w.HTMLDialogElement.prototype.showModal=function(){this.open=true;};w.HTMLDialogElement.prototype.close=function(){this.open=false;};
 w.AbortController=AbortController;w.confirm=()=>false;
 w.fetch=async (url,opts)=>{
  if(opts?.method==='POST'){envio={url,body:JSON.parse(opts.body)};return new Promise(resolve=>liberar=()=>resolve(new Response(null,{status:204})));}
  return fetch(new URL(url,base),opts);
 };
 w.eval(fs.readFileSync(path.join(root,'consultas-integradas.js'),'utf8'));
 w.eval(fs.readFileSync(path.join(root,'sitio.js'),'utf8'));
 await esperar(()=>!d.getElementById('entidad').disabled && !d.getElementById('resultado').hidden);
 ok('Ocho consultas visibles',d.getElementById('entidad').options.length===8);
 for(const entidad of ['personas','telefonos','direcciones','referencias','cuotas','resumenes']){
  const sel=d.getElementById('entidad');sel.value=entidad;sel.dispatchEvent(new w.Event('change'));
  await esperar(()=>!d.getElementById('resultado').hidden);
  ok(entidad+': alta accesible',!d.getElementById('nuevo-registro').hidden);
  d.getElementById('nuevo-registro').click();
  await esperar(()=>!d.getElementById('ficha-guardar').disabled);
  ok(entidad+': diálogo abierto y cierre explícito',d.getElementById('ficha-dialogo').open && !!d.querySelector('#ficha-dialogo .cierre-superior button'));
  const form=d.getElementById('ficha-formulario');
  if(entidad==='personas')ok('Código de persona automático',!form.elements.namedItem('CodigoPersona'));
  if(['telefonos','direcciones'].includes(entidad))ok(entidad+': correlativo automático',!form.elements.namedItem('Correlativo'));
  if(entidad==='direcciones'){
   const dep=form.elements.namedItem('CodigoDepartamento');dep.selectedIndex=1;dep.dispatchEvent(new w.Event('change'));
   ok('Municipios se actualizan con departamento',form.elements.namedItem('CodigoMunicipio').options.length>1);
  }
  if(entidad==='resumenes')ok('Resumen no permite inventar importes',!form.elements.namedItem('TotalIntereses') && !form.elements.namedItem('TotalNetoRecaudable'));
  d.getElementById('cerrar-ficha').click();ok(entidad+': cierre funciona',!d.getElementById('ficha-dialogo').open);
 }
 const sel=d.getElementById('entidad');sel.value='personas';sel.dispatchEvent(new w.Event('change'));await esperar(()=>!d.getElementById('resultado').hidden);
 d.getElementById('nuevo-registro').click();await esperar(()=>!d.getElementById('ficha-guardar').disabled);
 const form=d.getElementById('ficha-formulario');form.elements.namedItem('PrimerNombre').value='Ensayo DOM';form.elements.namedItem('PrimerApellido').value='Sin escritura';
 form.dispatchEvent(new w.Event('submit',{cancelable:true}));await esperar(()=>!!envio);
 ok('Alta envía campos y no código automático',envio.url.endsWith('/personas/crear') && envio.body.datos.PrimerNombre==='Ensayo DOM' && !('CodigoPersona' in envio.body.datos));
 ok('Durante guardado se bloquea cierre',d.getElementById('cerrar-ficha').disabled);
 ok('Durante guardado se bloquean campos',form.elements.namedItem('PrimerNombre').disabled);
 const cancel=new w.Event('cancel',{cancelable:true});d.getElementById('ficha-dialogo').dispatchEvent(cancel);ok('Escape no cierra durante guardado',cancel.defaultPrevented);
 liberar();await esperar(()=>!d.getElementById('ficha-dialogo').open);ok('Guardado cierra y refresca',true);
 sel.value='fiadores-creditos';sel.dispatchEvent(new w.Event('change'));await esperar(()=>!d.getElementById('resultado').hidden);
 ok('Vínculos siguen administrándose en su expediente',d.getElementById('nuevo-registro').hidden);
 dom.window.close();
 const salida=path.resolve(__dirname,'../artifacts/verificacion-mantenimiento-dom');fs.mkdirSync(salida,{recursive:true});
 fs.writeFileSync(path.join(salida,'resultado.json'),JSON.stringify({Estado:'Correcto',Fecha:new Date().toISOString(),Pruebas:pruebas},null,2));
 console.log(`${pruebas.length} comprobaciones DOM correctas; sin escrituras SQL.`);
})().catch(e=>{console.error(e);process.exitCode=1;});
