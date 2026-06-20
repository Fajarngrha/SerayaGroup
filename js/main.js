/* PT Sejahtera Raya Grup - Main JavaScript */

const CONTACT = {
  general: { phone: '6281932699944', email: 'Sejahterarayagrup168@gmail.com' },
  consulting: { phone: '6281932699944', email: 'Sejahterarayagrup168@gmail.com', name: 'Seraya Consulting' },
  organizer: { phone: '6281932699944', email: 'Sejahterarayagrup168@gmail.com', name: 'Seraya Organizer' },
  transportation: { phone: '6281932699944', email: 'Sejahterarayagrup168@gmail.com', name: 'Seraya Transportation' },
  construction: { phone: '6281932699944', email: 'Sejahterarayagrup168@gmail.com', name: 'Seraya Construction' }
};

const HERO_SLIDES = [
  {
    badge: 'Seraya Transportation',
    badgeClass: 'hero__badge--transport',
    title: 'Armada Transportasi & Logistik Lengkap',
    subtitle: 'Solusi transportasi aman, tepat waktu dengan armada terlengkap',
    link: 'transportation.html',
    image: 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=1920&q=80'
  },
  {
    badge: 'Seraya Consulting',
    badgeClass: 'hero__badge--consulting',
    title: 'Konsultan Hukum Korporasi Terpercaya',
    subtitle: 'Solusi hukum profesional untuk kebutuhan bisnis dan pribadi Anda',
    link: 'consulting.html',
    image: 'https://images.unsplash.com/photo-1589829545855-d10d557cf95f?w=1920&q=80'
  },
  {
    badge: 'Seraya Organizer',
    badgeClass: 'hero__badge--organizer',
    title: 'Event Management Excellence',
    subtitle: 'Wujudkan acara impian Anda dengan tim profesional kami',
    link: 'organizer.html',
    image: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=1920&q=80'
  },
  {
    badge: 'Seraya Construction',
    badgeClass: 'hero__badge--construction',
    title: 'Rancang Bangun Profesional',
    subtitle: 'Kualitas, ketepatan waktu, dan standar keselamatan terbaik',
    link: 'construction.html',
    image: 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=1920&q=80'
  }
];

function buildWhatsAppUrl(phone, message) {
  const encoded = encodeURIComponent(message);
  return `https://wa.me/${phone}?text=${encoded}`;
}

function initMobileNav() {
  const toggle = document.querySelector('.nav-toggle');
  const nav = document.querySelector('.nav');
  if (!toggle || !nav) return;

  toggle.addEventListener('click', () => {
    toggle.classList.toggle('active');
    nav.classList.toggle('open');
  });

  document.querySelectorAll('.nav__dropdown-toggle').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      btn.closest('.nav__dropdown').classList.toggle('open');
    });
  });

  document.addEventListener('click', () => {
    document.querySelectorAll('.nav__dropdown').forEach(d => d.classList.remove('open'));
  });
}

function initHeroCarousel() {
  const hero = document.querySelector('.hero');
  if (!hero) return;

  const slidesContainer = hero.querySelector('.hero__slides');
  const contentEl = hero.querySelector('.hero__content');
  const dotsContainer = hero.querySelector('.hero__dots');
  const prevBtn = hero.querySelector('.hero__nav--prev');
  const nextBtn = hero.querySelector('.hero__nav--next');

  let current = 0;
  let interval;

  HERO_SLIDES.forEach((slide, i) => {
    const slideEl = document.createElement('div');
    slideEl.className = `hero__slide${i === 0 ? ' active' : ''}`;
    slideEl.style.backgroundImage = `url('${slide.image}')`;
    slidesContainer.appendChild(slideEl);

    const dot = document.createElement('button');
    dot.className = `hero__dot${i === 0 ? ' active' : ''}`;
    dot.setAttribute('aria-label', `Slide ${i + 1}`);
    dot.addEventListener('click', () => goTo(i));
    dotsContainer.appendChild(dot);
  });

  function renderContent(index) {
    const slide = HERO_SLIDES[index];
    contentEl.innerHTML = `
      <span class="hero__badge ${slide.badgeClass}">${slide.badge}</span>
      <h1 class="hero__title">${slide.title}</h1>
      <p class="hero__subtitle">${slide.subtitle}</p>
      <div class="hero__actions">
        <a href="kontak.html" class="btn btn--gold btn--lg">Konsultasi Gratis</a>
        <a href="${slide.link}" class="btn btn--outline-white btn--lg">Lihat Layanan</a>
      </div>
    `;
  }

  function goTo(index) {
    current = (index + HERO_SLIDES.length) % HERO_SLIDES.length;
    hero.querySelectorAll('.hero__slide').forEach((s, i) => s.classList.toggle('active', i === current));
    hero.querySelectorAll('.hero__dot').forEach((d, i) => d.classList.toggle('active', i === current));
    renderContent(current);
  }

  function startAutoplay() {
    interval = setInterval(() => goTo(current + 1), 6000);
  }

  function resetAutoplay() {
    clearInterval(interval);
    startAutoplay();
  }

  prevBtn?.addEventListener('click', () => { goTo(current - 1); resetAutoplay(); });
  nextBtn?.addEventListener('click', () => { goTo(current + 1); resetAutoplay(); });

  renderContent(0);
  startAutoplay();
}

function initFleetFilter() {
  const filters = document.querySelectorAll('.fleet-filter');
  const cards = document.querySelectorAll('.fleet-card');
  if (!filters.length) return;

  filters.forEach(filter => {
    filter.addEventListener('click', () => {
      filters.forEach(f => f.classList.remove('active'));
      filter.classList.add('active');
      const category = filter.dataset.filter;
      cards.forEach(card => {
        if (category === 'all' || card.dataset.category === category) {
          card.classList.remove('hidden');
        } else {
          card.classList.add('hidden');
        }
      });
    });
  });
}

function initQuoteForm() {
  const form = document.getElementById('quote-form');
  if (!form) return;

  form.addEventListener('submit', (e) => {
    e.preventDefault();
    const data = new FormData(form);
    const message = [
      '*Request Quote - Seraya Transportation*',
      '',
      `Nama: ${data.get('nama')}`,
      `Telepon: ${data.get('telepon')}`,
      `Kendaraan: ${data.get('kendaraan')}`,
      `Tanggal: ${data.get('tanggal')}`,
      `Kota Asal: ${data.get('asal')}`,
      `Kota Tujuan: ${data.get('tujuan')}`,
      data.get('catatan') ? `Catatan: ${data.get('catatan')}` : ''
    ].filter(Boolean).join('\n');

    window.open(buildWhatsAppUrl(CONTACT.transportation.phone, message), '_blank');
  });
}

function initContactForm() {
  const form = document.getElementById('contact-form');
  if (!form) return;

  form.addEventListener('submit', (e) => {
    e.preventDefault();
    const data = new FormData(form);
    const unit = data.get('unit');
    const unitContact = CONTACT[unit] || CONTACT.general;

    const message = [
      `*Pesan dari Website - ${unitContact.name || 'PT Sejahtera Raya Grup'}*`,
      '',
      `Nama: ${data.get('nama')}`,
      `Email: ${data.get('email')}`,
      `Telepon: ${data.get('telepon')}`,
      `Unit Bisnis: ${data.get('unit')}`,
      '',
      `Pesan:`,
      data.get('pesan')
    ].join('\n');

    window.open(buildWhatsAppUrl(unitContact.phone, message), '_blank');
  });
}

function setActiveNav() {
  const path = window.location.pathname.split('/').pop() || 'index.html';
  document.querySelectorAll('.nav__link').forEach(link => {
    const href = link.getAttribute('href');
    if (href === path || (path === 'index.html' && href === 'index.html')) {
      link.classList.add('active');
    }
  });
  if (path === 'kontak.html') {
    document.querySelector('.nav__link[href="kontak.html"]')?.classList.add('active');
  }
}

document.addEventListener('DOMContentLoaded', () => {
  initMobileNav();
  initHeroCarousel();
  initFleetFilter();
  initQuoteForm();
  initContactForm();
  setActiveNav();
});
