'use strict';
(() => {
 const $=id=>document.getElementById(id), base='/api/parametros-credito';
 const campos=['tasaAnualPorcentaje','seguroAutoMensualPorcentaje','seguroVidaMensualPorcentaje','engancheMinimoPorcentaje','comisionPredeterminadaPorcentaje','depreciacionInicialPorcentaje','manejoMensual'];
 let ocupado=false,listo=false,editando=null,soloLectura=false,seleccion=null,accion='',turno=0,lectura;
 const nodo=(tag,texto)=>{const n=document.createElement(tag);n.textContent=texto;return n;};
 function mensaje(id,texto,error=false){$(id).textContent=texto;$(id).hidden=!texto;$(id).classList.toggle('error',error);}
 async function pedir(ruta='',metodo='GET',datos,signal){
  let r,j;try{r=await fetch(base+ruta,{method:metodo,headers:datos?{'Content-Type':'application/json'}:{},body:datos?JSON.stringify(datos):undefined,signal});j=r.status===204?null:await r.json();}
  catch(e){if(e.name==='AbortError')throw e;throw Error('No se pudo comunicar con la aplicación. Revisa la conexión e inténtalo de nuevo.');}
  if(!r.ok)throw Error(j.detail||Object.values(j.errors||{}).flat().join(' ')||'No se pudo completar la operación.');return j;
 }
 function controles(){
  $('nuevo').disabled=ocupado||!listo;$('campos').disabled=ocupado||soloLectura;
  for(const id of ['guardar','cerrar','cancelar','confirmar','criterio','buscar','todos'])$(id).disabled=ocupado;
  $('guardar').hidden=soloLectura;
 }
 async function cargar(){
  const version=++turno;lectura?.abort();lectura=new AbortController();listo=false;controles();
  $('resultados').setAttribute('aria-busy','true');$('filas').replaceChildren();$('contador').textContent='Cargando…';$('vacio').hidden=false;$('vacio').textContent='Cargando configuraciones…';
  const criterio=$('criterio').value.trim();
  try{
   const filas=await pedir(criterio?'?criterio='+encodeURIComponent(criterio):'','GET',undefined,lectura.signal);if(version!==turno)return;
   for(const f of filas){
    const tr=document.createElement('tr');for(const t of [`${f.codigoParametro} · ${f.nombre}`,`${f.activo?'Activa':'Inactiva'}${f.enUso?' · Utilizada':' · Sin usar'}`,f.tasaAnualPorcentaje+'%',f.comisionPredeterminadaPorcentaje+'%'])tr.append(nodo('td',t));
    const td=document.createElement('td'),acciones=document.createElement('div');acciones.className='acciones';
    const agregar=(texto,fn)=>{const b=nodo('button',texto);b.type='button';b.className='secundario';b.setAttribute('aria-label',`${texto}: ${f.nombre}, código ${f.codigoParametro}`);b.addEventListener('click',()=>{if(!ocupado&&listo)fn();});acciones.append(b);};
    agregar(f.enUso||f.activo?'Ver':'Editar',()=>abrir(f,false));agregar('Copiar',()=>abrir(f,true));
    if(!f.activo)agregar('Activar',()=>confirmar(f,'activar'));
    if(!f.activo&&!f.enUso)agregar('Eliminar',()=>confirmar(f,'eliminar'));
    td.append(acciones);tr.append(td);$('filas').append(tr);
   }
   $('contador').textContent=`${filas.length} configuración(es)`;$('vacio').textContent='No hay configuraciones para estos filtros.';$('vacio').hidden=filas.length>0;listo=true;
  }catch(e){if(version!==turno||e.name==='AbortError')return;mensaje('aviso',e.message,true);$('contador').textContent='No disponible';$('vacio').textContent='No se pudo cargar el listado. Pulsa Ver todos para reintentar.';}
  finally{if(version===turno){$('resultados').setAttribute('aria-busy','false');controles();}}
 }
 function abrir(f=null,copia=false){
  editando=copia?null:f;soloLectura=!!(f?.enUso||f?.activo)&&!copia;$('formulario').reset();mensaje('error-editor','');
  $('titulo-editor').textContent=soloLectura?'Consultar configuración':copia?'Copiar configuración':f?'Editar configuración':'Nueva configuración';
  $('ayuda-editor').textContent=soloLectura?'Esta versión está activa o ya forma parte de créditos y se conserva. Usa Copiar para preparar otras condiciones.':editando?'Solo se editan versiones inactivas y sin uso.':'Se guardará inactiva. Revisa sus valores y luego usa Activar para aplicarla a próximos borradores.';
  $('nombre').value=copia?('Copia de '+f.nombre).slice(0,100):f?.nombre??'';
  for(const k of campos)$(k).value=f?.[k]??(k==='manejoMensual'?'25.00':'');
  $('nombre').setCustomValidity('');controles();$('editor').showModal();(soloLectura?$('cerrar'):$('nombre')).focus();
 }
 $('nombre').addEventListener('input',()=>$('nombre').setCustomValidity(''));
 $('formulario').addEventListener('submit',async e=>{
  e.preventDefault();if(ocupado||soloLectura)return;
  const nombre=$('nombre').value.trim();if(!nombre){$('nombre').setCustomValidity('Escribe un nombre.');$('nombre').reportValidity();return;}
  const datos={nombre};for(const k of campos)datos[k]=$(k).value;
  ocupado=true;controles();mensaje('error-editor','');
  try{await pedir(editando?'/'+editando.codigoParametro:'',editando?'PUT':'POST',datos);$('editor').close();$('criterio').value='';mensaje('aviso',editando?'Configuración actualizada.':'Configuración creada inactiva. Actívala cuando esté lista.');await cargar();}
  catch(e){mensaje('error-editor',e.message,true);}finally{ocupado=false;controles();}
 });
 function confirmar(f,a){seleccion=f;accion=a;mensaje('error-accion','');$('titulo-accion').textContent=a==='activar'?'¿Activar esta configuración?':'¿Eliminar esta configuración?';
  $('detalle-accion').textContent=`${f.codigoParametro} · ${f.nombre}. `+(a==='activar'?'Reemplazará la configuración activa para nuevos borradores y para los que vuelvas a guardar. Los créditos aprobados y los borradores sin editar conservan sus condiciones.':'Solo se elimina si sigue inactiva y ningún crédito la utiliza.');$('confirmacion').showModal();$('cancelar').focus();
 }
 $('confirmar').addEventListener('click',async()=>{
  if(ocupado)return;ocupado=true;controles();mensaje('error-accion','');
  try{await pedir('/'+seleccion.codigoParametro+(accion==='activar'?'/activar':''),accion==='activar'?'POST':'DELETE');$('confirmacion').close();$('criterio').value='';mensaje('aviso',accion==='activar'?'Configuración activada. Los contratos existentes conservan sus condiciones.':'Configuración eliminada.');await cargar();}
  catch(e){mensaje('error-accion',e.message,true);}finally{ocupado=false;controles();}
 });
 $('nuevo').addEventListener('click',()=>abrir());$('cerrar').addEventListener('click',()=>$('editor').close());$('cancelar').addEventListener('click',()=>$('confirmacion').close());
 for(const id of ['editor','confirmacion'])$(id).addEventListener('cancel',e=>{if(ocupado)e.preventDefault();});
 $('busqueda').addEventListener('submit',e=>{e.preventDefault();if(!ocupado){mensaje('aviso','');cargar();}});
 $('todos').addEventListener('click',()=>{$('criterio').value='';mensaje('aviso','');cargar();});cargar();
})();
