/* MAGIS AUTOMOTIZ - script.js
   Funcionalidades:
   - Menú hamburguesa
   - Scroll suave
   - Filtro de vehículos
   - Modal de detalles y galería
   - Simulador de financiamiento
   - Botón flotante WhatsApp
   - Animaciones al hacer scroll
   - Validación de formularios
   - Botón volver arriba
*/

document.addEventListener('DOMContentLoaded', () => {
  /* DATOS DE VEHÍCULOS (ejemplos, imágenes desde Unsplash) */
  const vehicles = [
    {
      id: 1, brand: 'Toyota', model: 'Hilux', year: 2023, fuel: 'Diésel',
      trans: 'Automático', km: 12000, price: 385000, color: 'Blanco',
      gallery: [
        'https://images.unsplash.com/photo-1603731311632-3a6d4b8b0e9b?q=80&w=1600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1612882021037-4b0db7b5b7a8?q=80&w=1600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1563720224554-0f6a2e20fb9b?q=80&w=1600&auto=format&fit=crop'
      ],
      description: 'Toyota Hilux 2023 en excelente estado, ideal para trabajo y aventura.'
    },
    {
      id: 2, brand: 'Toyota', model: 'RAV4', year: 2022, fuel: 'Gasolina',
      trans: 'Automático', km: 22000, price: 310000, color: 'Gris',
      gallery: [
        'https://images.unsplash.com/photo-1549924231-f129b911e442?q=80&w=1600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1563720213923-2f7f8a7a8b9d?q=80&w=1600&auto=format&fit=crop'
      ],
      description: 'Toyota RAV4 2022, cómodo y eficiente.'
    },
    {
      id: 3, brand: 'Toyota', model: 'Corolla', year: 2022, fuel: 'Gasolina',
      trans: 'Automático', km: 15000, price: 185000, color: 'Negro',
      gallery: [
        'https://images.unsplash.com/photo-1542362567-b07e54358753?q=80&w=1600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1563720224554-0f6a2e20fb9b?q=80&w=1600&auto=format&fit=crop'
      ],
      description: 'Toyota Corolla 2022, vehículo familiar y económico.'
    },
    {
      id: 4, brand: 'Toyota', model: 'Fortuner', year: 2023, fuel: 'Diésel',
      trans: 'Automático', km: 8000, price: 450000, color: 'Plata',
      gallery: [
        'https://images.unsplash.com/photo-1601375720371-87b4d0f6be35?q=80&w=1600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1612882021037-4b0db7b5b7a8?q=80&w=1600&auto=format&fit=crop'
      ],
      description: 'Toyota Fortuner 2023, potencia y espacio para la familia.'
    }
  ];

  /* REFERENCIAS A ELEMENTOS */
  const vehiclesGrid = document.getElementById('vehiclesGrid');
  const filterBrand = document.getElementById('filterBrand');
  const filterModel = document.getElementById('filterModel');
  const filterType = document.getElementById('filterType');
  const filterPrice = document.getElementById('filterPrice');
  const btnSearch = document.getElementById('btnSearch');
  const hamburger = document.getElementById('hamburger');
  const mobileMenu = document.getElementById('mobileMenu');
  const mobileLinks = document.querySelectorAll('.mobile-link');
  const backTop = document.getElementById('backTop');

  /* RENDER VEHÍCULOS */
  function formatPrice(q) {
    return 'Q ' + Number(q).toLocaleString('es-GT', {minimumFractionDigits:0});
  }

  function renderVehicles(list) {
    vehiclesGrid.innerHTML = '';
    if (list.length === 0) {
      vehiclesGrid.innerHTML = '<p>No se encontraron vehículos.</p>';
      return;
    }
    list.forEach(v => {
      const card = document.createElement('div');
      card.className = 'card-vehicle';
      card.innerHTML = `
        <img src="${v.gallery[0]}" alt="${v.brand} ${v.model}">
        <div class="card-body">
          <h4>${v.brand} ${v.model}</h4>
          <div class="meta">${v.year} • ${v.fuel} • ${v.trans}</div>
          <div class="price">${formatPrice(v.price)}</div>
          <div class="card-actions">
            <button class="btn btn-outline" data-action="details" data-id="${v.id}">VER DETALLES</button>
            <a class="btn btn-primary" href="https://wa.me/50249579692?text=Hola%20Auto%20Colis%2C%20estoy%20interesado%20en%20el%20veh%C3%ADculo%20${encodeURIComponent(v.brand+' '+v.model)}" target="_blank"><i class="fa-brands fa-whatsapp"></i> CONSULTAR</a>
          </div>
        </div>
      `;
      vehiclesGrid.appendChild(card);
    });
  }

  /* LLENAR FILTROS DE MARCA Y MODELO */
  function populateBrandFilter() {
    const brands = [...new Set(vehicles.map(v => v.brand))];
    filterBrand.innerHTML = '<option value="">MARCA - Todas</option>';
    brands.forEach(b => {
      const opt = document.createElement('option');
      opt.value = b; opt.textContent = b;
      filterBrand.appendChild(opt);
    });
  }

  function populateModelFilter(brand = '') {
    const filtered = brand ? vehicles.filter(v=>v.brand===brand) : vehicles;
    const models = [...new Set(filtered.map(v=>v.model))];
    filterModel.innerHTML = '<option value="">MODELO - Todos</option>';
    models.forEach(m=>{
      const opt = document.createElement('option'); opt.value = m; opt.textContent = m;
      filterModel.appendChild(opt);
    });
  }

  /* FILTRAR */
  function filterVehicles() {
    const t = filterType.value;
    const b = filterBrand.value;
    const m = filterModel.value;
    const p = filterPrice.value;

    let list = vehicles.slice();
    if (t) list = list.filter(v => v.type === t || v.trans === t || v.model === t || v.fuel === t);
    if (b) list = list.filter(v => v.brand === b);
    if (m) list = list.filter(v => v.model === m);

    if (p) {
      const [min,max] = p.split('-').map(Number);
      list = list.filter(v => v.price >= min && v.price <= (isNaN(max) ? Infinity : max));
    }

    renderVehicles(list);
  }

  /* MODAL DETALLES */
  const vehicleModal = document.getElementById('vehicleModal');
  const modalClose = document.getElementById('modalClose');
  const modalMainImage = document.getElementById('modalMainImage');
  const modalThumbs = document.getElementById('modalThumbs');
  const modalTitle = document.getElementById('modalTitle');
  const modalPrice = document.getElementById('modalPrice');
  const modalDesc = document.getElementById('modalDesc');
  const modalMeta = document.getElementById('modalMeta');
  const modalWhats = document.getElementById('modalWhats');
  const specYear = document.getElementById('specYear');
  const specKm = document.getElementById('specKm');
  const specMotor = document.getElementById('specMotor');
  const specFuel = document.getElementById('specFuel');
  const specTrans = document.getElementById('specTrans');
  const specColor = document.getElementById('specColor');
  const modalSimulate = document.getElementById('modalSimulate');

  function openVehicleModal(id) {
    const v = vehicles.find(x => x.id === Number(id));
    if (!v) return;
    modalMainImage.src = v.gallery[0];
    modalThumbs.innerHTML = '';
    v.gallery.forEach((g, idx) => {
      const img = document.createElement('img');
      img.src = g; img.alt = v.brand + ' ' + v.model;
      if (idx === 0) img.classList.add('active');
      img.addEventListener('click', () => {
        modalMainImage.src = g;
        document.querySelectorAll('#modalThumbs img').forEach(i=>i.classList.remove('active'));
        img.classList.add('active');
      });
      modalThumbs.appendChild(img);
    });

    modalTitle.textContent = `${v.brand} ${v.model}`;
    modalPrice.textContent = formatPrice(v.price);
    modalMeta.textContent = `${v.year} • ${v.km.toLocaleString()} km • ${v.fuel}`;
    modalDesc.textContent = v.description || '';
    specYear.textContent = v.year;
    specKm.textContent = v.km.toLocaleString() + ' km';
    specMotor.textContent = v.motor || '2.8L';
    specFuel.textContent = v.fuel;
    specTrans.textContent = v.trans;
    specColor.textContent = v.color;

    modalWhats.href = `https://wa.me/50249579692?text=${encodeURIComponent(`Hola, estoy interesado en el vehículo ${v.brand} ${v.model} publicado en Auto Colis.`)}`;

    vehicleModal.setAttribute('aria-hidden', 'false');
  }

  function closeVehicleModal() {
    vehicleModal.setAttribute('aria-hidden', 'true');
  }

  /* SIMULADOR DE FINANCIAMIENTO */
  const finPrice = document.getElementById('finPrice');
  const finDown = document.getElementById('finDown');
  const finMonths = document.getElementById('finMonths');
  const finRate = document.getElementById('finRate');
  const btnCalc = document.getElementById('btnCalc');
  const resultValue = document.getElementById('resultValue');

  function calculateMonthly(price, down, months, annualRate) {
    const principal = Math.max(0, price - down);
    if (months <= 0) return 0;
    const monthlyRate = (annualRate/100)/12;
    if (monthlyRate === 0) return principal / months;
    const r = monthlyRate;
    const n = months;
    const payment = principal * (r * Math.pow(1+r,n)) / (Math.pow(1+r,n)-1);
    return payment;
  }

  btnCalc.addEventListener('click', (e) => {
    e.preventDefault();
    const price = Number(finPrice.value) || 0;
    const down = Number(finDown.value) || 0;
    const months = Number(finMonths.value) || 12;
    const rate = Number(finRate.value) || 12;
    if (price <= 0) { alert('Indica el precio del vehículo.'); return; }
    if (down < 0) { alert('Enganche inválido'); return; }
    const monthly = calculateMonthly(price, down, months, rate);
    resultValue.textContent = 'Q ' + monthly.toLocaleString('es-GT', {minimumFractionDigits:2});
    resultValue.scrollIntoView({behavior:'smooth', block:'center'});
  });

  /* EVENTOS GLOBALES */
  document.body.addEventListener('click', (e) => {
    const btn = e.target.closest('button[data-action="details"]');
    if (btn) {
      const id = btn.dataset.id;
      openVehicleModal(id);
    }
  });

  modalClose.addEventListener('click', closeVehicleModal);
  vehicleModal.addEventListener('click', (e) => {
    if (e.target === vehicleModal) closeVehicleModal();
  });

  /* FILTROS interacciones */
  filterBrand.addEventListener('change', () => populateModelFilter(filterBrand.value));
  btnSearch.addEventListener('click', (e) => {
    e.preventDefault();
    filterVehicles();
  });

  /* MENÚ hamburguesa */
  hamburger.addEventListener('click', () => {
    hamburger.classList.toggle('open');
    mobileMenu.classList.toggle('open');
  });
  mobileLinks.forEach(l => l.addEventListener('click', () => {
    mobileMenu.classList.remove('open');
    hamburger.classList.remove('open');
  }));

  /* SCROLL SUAVE */
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
      const href = this.getAttribute('href');
      if (!href || href === '#') return;
      e.preventDefault();
      const target = document.querySelector(href);
      if (target) target.scrollIntoView({behavior:'smooth', block:'start'});
    });
  });

  /* BACK TO TOP */
  window.addEventListener('scroll', () => {
    if (window.scrollY > 400) backTop.style.display = 'block'; else backTop.style.display = 'none';
    // animate on scroll simple
    document.querySelectorAll('.fade-up').forEach(el => {
      const rect = el.getBoundingClientRect();
      if (rect.top < window.innerHeight - 80) el.classList.add('visible');
    });
  });
  backTop.addEventListener('click', ()=> window.scrollTo({top:0,behavior:'smooth'}));

  /* FORMULARIO CONTACTO */
  const contactForm = document.getElementById('contactForm');
  contactForm.addEventListener('submit', (e) => {
    e.preventDefault();
    const name = document.getElementById('cname').value.trim();
    const phone = document.getElementById('cphone').value.trim();
    const email = document.getElementById('cemail').value.trim();
    if (!name || !phone || !email) { alert('Completa los campos requeridos.'); return; }
    // Simular envío
    alert('Mensaje enviado. Gracias, en breve nos contactaremos.');
    contactForm.reset();
  });

  /* INICIALIZACIÓN */
  populateBrandFilter();
  populateModelFilter();
  renderVehicles(vehicles);

  /* Animaciones: agregar clase fade-up a secciones para efecto */
  document.querySelectorAll('section, .card-vehicle, .benefit').forEach(el => el.classList.add('fade-up'));

  /* Modal simulador desde modal */
  modalSimulate.addEventListener('click', () => {
    const priceText = modalPrice.textContent.replace(/[^0-9]/g,'');
    const price = Number(priceText) || 0;
    finPrice.value = price;
    window.location.hash = '#finance';
    setTimeout(()=> window.scrollTo({top: document.getElementById('finance').offsetTop - 80, behavior: 'smooth'}), 50);
  });

  /* Ajustes responsive y accesibilidad */
  window.addEventListener('resize', () => {
    if (window.innerWidth > 900) {
      mobileMenu.classList.remove('open');
      hamburger.classList.remove('open');
    }
  });

  /* Smooth initial scroll to top */
  window.scrollTo({top:0,behavior:'smooth'});
});
