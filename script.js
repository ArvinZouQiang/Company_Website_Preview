const header = document.querySelector("[data-header]");
const nav = document.querySelector("[data-nav]");
const navToggle = document.querySelector("[data-nav-toggle]");
const navLinks = [...document.querySelectorAll(".site-nav a[href^='#']")];
const sections = [...document.querySelectorAll(".section-observe[id]")];

if (new URLSearchParams(window.location.search).get("desktop") === "1") {
  document.body.classList.add("force-desktop-preview");
}

function setHeaderState() {
  header.classList.toggle("is-scrolled", window.scrollY > 18);
}

function closeNav() {
  document.body.classList.remove("nav-open");
  header.classList.remove("nav-active");
  nav.classList.remove("is-open");
  navToggle.setAttribute("aria-expanded", "false");
}

setHeaderState();
window.addEventListener("scroll", setHeaderState, { passive: true });

navToggle.addEventListener("click", () => {
  const isOpen = nav.classList.toggle("is-open");
  document.body.classList.toggle("nav-open", isOpen);
  header.classList.toggle("nav-active", isOpen);
  navToggle.setAttribute("aria-expanded", String(isOpen));
});

navLinks.forEach((link) => {
  link.addEventListener("click", closeNav);
});

const activeObserver = new IntersectionObserver(
  (entries) => {
    const visible = entries
      .filter((entry) => entry.isIntersecting)
      .sort((a, b) => b.intersectionRatio - a.intersectionRatio)[0];

    if (!visible) return;

    navLinks.forEach((link) => {
      link.classList.toggle("is-active", link.getAttribute("href") === `#${visible.target.id}`);
    });
  },
  {
    threshold: [0.28, 0.45, 0.62],
    rootMargin: "-18% 0px -56% 0px",
  }
);

sections.forEach((section) => activeObserver.observe(section));

const track = document.querySelector("[data-evidence-track]");
const prev = document.querySelector("[data-evidence-prev]");
const next = document.querySelector("[data-evidence-next]");
let evidenceIndex = 0;

function updateEvidence(direction) {
  const cards = [...track.children];
  const visibleCount = window.matchMedia("(max-width: 1080px)").matches ? 2 : 3;
  const maxIndex = Math.max(cards.length - visibleCount, 0);
  evidenceIndex = Math.min(Math.max(evidenceIndex + direction, 0), maxIndex);
  const cardWidth = cards[0].getBoundingClientRect().width;
  const gap = Number.parseFloat(getComputedStyle(track).columnGap || "0");
  track.style.transform = `translateX(-${evidenceIndex * (cardWidth + gap)}px)`;
}

prev?.addEventListener("click", () => updateEvidence(-1));
next?.addEventListener("click", () => updateEvidence(1));
window.addEventListener("resize", () => {
  evidenceIndex = 0;
  if (track) track.style.transform = "translateX(0)";
});

const founderCarousel = document.querySelector("[data-founder-carousel]");
const founderSlides = [...document.querySelectorAll(".founder-slide")];
const founderPrev = document.querySelector("[data-founder-prev]");
const founderNext = document.querySelector("[data-founder-next]");
const founderDots = document.querySelector("[data-founder-dots]");
let founderIndex = 0;
let founderTimer;

function showFounderSlide(index) {
  if (!founderSlides.length) return;

  founderIndex = (index + founderSlides.length) % founderSlides.length;
  founderSlides.forEach((slide, slideIndex) => {
    slide.classList.toggle("is-active", slideIndex === founderIndex);
  });

  [...founderDots.children].forEach((dot, dotIndex) => {
    dot.classList.toggle("is-active", dotIndex === founderIndex);
    dot.setAttribute("aria-current", dotIndex === founderIndex ? "true" : "false");
  });
}

function restartFounderTimer() {
  window.clearInterval(founderTimer);
  founderTimer = window.setInterval(() => showFounderSlide(founderIndex + 1), 4800);
}

if (founderCarousel && founderDots && founderSlides.length) {
  founderSlides.forEach((_, index) => {
    const dot = document.createElement("button");
    dot.type = "button";
    dot.className = "founder-dot";
    dot.setAttribute("aria-label", `查看第 ${index + 1} 张邹老师照片`);
    dot.addEventListener("click", () => {
      showFounderSlide(index);
      restartFounderTimer();
    });
    founderDots.append(dot);
  });

  founderPrev?.addEventListener("click", () => {
    showFounderSlide(founderIndex - 1);
    restartFounderTimer();
  });

  founderNext?.addEventListener("click", () => {
    showFounderSlide(founderIndex + 1);
    restartFounderTimer();
  });

  founderCarousel.addEventListener("mouseenter", () => window.clearInterval(founderTimer));
  founderCarousel.addEventListener("mouseleave", restartFounderTimer);
  showFounderSlide(0);
  restartFounderTimer();
}

const caseCards = [...document.querySelectorAll(".case-card")];
const caseLightbox = document.querySelector("[data-case-lightbox]");
const caseLightboxImage = document.querySelector("[data-case-lightbox-image]");
const caseLightboxTitle = document.querySelector("[data-case-lightbox-title]");
const caseLightboxNote = document.querySelector("[data-case-lightbox-note]");
const caseCloseButtons = [...document.querySelectorAll("[data-case-close]")];
const casePrev = document.querySelector("[data-case-prev]");
const caseNext = document.querySelector("[data-case-next]");
let caseIndex = 0;

function showCaseImage(index) {
  if (!caseCards.length || !caseLightbox || !caseLightboxImage) return;

  caseIndex = (index + caseCards.length) % caseCards.length;
  const card = caseCards[caseIndex];
  const title = card.dataset.caseTitle || "案例证据";
  const note = card.dataset.caseNote || "";
  caseLightboxImage.src = card.dataset.caseImage;
  caseLightboxImage.alt = `${title}放大图`;
  caseLightboxTitle.textContent = title;
  caseLightboxNote.textContent = note;
}

function openCaseLightbox(index) {
  showCaseImage(index);
  caseLightbox.hidden = false;
  document.body.classList.add("case-lightbox-open");
}

function closeCaseLightbox() {
  if (!caseLightbox) return;
  caseLightbox.hidden = true;
  document.body.classList.remove("case-lightbox-open");
}

caseCards.forEach((card, index) => {
  card.addEventListener("click", () => openCaseLightbox(index));
});

caseCloseButtons.forEach((button) => {
  button.addEventListener("click", closeCaseLightbox);
});

casePrev?.addEventListener("click", () => showCaseImage(caseIndex - 1));
caseNext?.addEventListener("click", () => showCaseImage(caseIndex + 1));

window.addEventListener("keydown", (event) => {
  if (!caseLightbox || caseLightbox.hidden) return;

  if (event.key === "Escape") closeCaseLightbox();
  if (event.key === "ArrowLeft") showCaseImage(caseIndex - 1);
  if (event.key === "ArrowRight") showCaseImage(caseIndex + 1);
});
