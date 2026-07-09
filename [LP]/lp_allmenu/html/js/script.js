var _resourceName = (function() {
  try { return window.GetParentResourceName(); } catch(e) { return 'Allmenu'; }
})();

/* ── Slider ── */
var _slider = {
  images: ['assets/2f90f681ae977f2e3a26a17b7da205b63be7dd05.png'],
  current: 0,
  timer: null,
  interval: 4000,

  init: function() {
    this.render();
    this.startAuto();
    document.getElementById('slide-prev').addEventListener('click', function() {
      _slider.go(_slider.current - 1);
    });
    document.getElementById('slide-next').addEventListener('click', function() {
      _slider.go(_slider.current + 1);
    });
  },

  render: function() {
    var track = document.getElementById('slider-track');
    var dotsEl = document.getElementById('slide-dots');
    var total = this.images.length;

    track.innerHTML = '';
    dotsEl.innerHTML = '';

    for (var i = 0; i < total; i++) {
      var slide = document.createElement('div');
      slide.className = 'slide';
      var img = document.createElement('img');
      img.src = this.images[i];
      img.alt = '';
      slide.appendChild(img);
      track.appendChild(slide);

      var dot = document.createElement('div');
      dot.className = 'slide-dot' + (i === this.current ? ' active' : '');
      (function(idx) {
        dot.addEventListener('click', function() { _slider.go(idx); });
      })(i);
      dotsEl.appendChild(dot);
    }

    /* hide arrows if only 1 slide */
    var showNav = total > 1;
    document.getElementById('slide-prev').style.display = showNav ? '' : 'none';
    document.getElementById('slide-next').style.display = showNav ? '' : 'none';
    dotsEl.style.display = showNav ? '' : 'none';

    this.updatePosition(false);
  },

  updatePosition: function(animate) {
    var track = document.getElementById('slider-track');
    if (!animate) track.style.transition = 'none';
    track.style.transform = 'translateX(-' + (this.current * 1179) + 'px)';
    if (!animate) {
      track.offsetHeight; /* reflow */
      track.style.transition = '';
    }

    var dots = document.querySelectorAll('.slide-dot');
    for (var i = 0; i < dots.length; i++) {
      dots[i].classList.toggle('active', i === this.current);
    }
  },

  go: function(idx) {
    var total = this.images.length;
    this.current = ((idx % total) + total) % total;
    this.updatePosition(true);
    this.startAuto();
  },

  startAuto: function() {
    var self = this;
    if (this.timer) clearInterval(this.timer);
    if (this.images.length <= 1) return;
    this.timer = setInterval(function() { self.go(self.current + 1); }, this.interval);
  },

  stopAuto: function() {
    if (this.timer) { clearInterval(this.timer); this.timer = null; }
  },

  setBanners: function(urls) {
    this.images = urls && urls.length ? urls : this.images;
    this.current = 0;
    this.render();
    this.startAuto();
  }
};

function showUI() {
  document.getElementById('root').classList.remove('hidden');
  _slider.startAuto();
}

function hideUI() {
  document.getElementById('root').classList.add('hidden');
  _slider.stopAuto();
  fetch('https://' + _resourceName + '/closeMenu', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({})
  }).catch(function() {});
}

function triggerMenu(menuName) {
  fetch('https://' + _resourceName + '/triggerMenu', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ menu: menuName })
  }).catch(function() {});
  hideUI();
}

function renderItems(items) {
  var bigSlot  = document.getElementById('card-big-slot');
  var grid     = document.getElementById('right-grid');
  bigSlot.innerHTML = '';
  grid.innerHTML    = '';

  for (var i = 0; i < items.length; i++) {
    var item = items[i];
    var card = document.createElement('div');
    var isBig = (i === 0);

    card.className = 'menu-card' + (isBig ? ' card-big' : '');
    card.dataset.id = item.id;

    if (item.image) {
      var bg = document.createElement('div');
      bg.className = 'card-bg';
      bg.style.backgroundImage = 'url(' + item.image + ')';
      card.appendChild(bg);
    }

    var title = document.createElement('div');
    title.className = 'card-title';
    title.textContent = item.title;

    var desc = document.createElement('div');
    desc.className = 'card-sub';
    desc.textContent = item.desc;

    card.appendChild(title);
    card.appendChild(desc);

    (function(id) {
      card.addEventListener('click', function() { triggerMenu(id); });
    })(item.id);

    if (isBig) {
      bigSlot.appendChild(card);
    } else {
      grid.appendChild(card);
    }
  }
}

function setPlayerInfo(name, id, avatarUrl) {
  var nameEl = document.getElementById('player-name');
  var idEl   = document.getElementById('player-id');
  var imgEl  = document.getElementById('player-avatar-img');
  if (nameEl) nameEl.textContent = name || 'NAME LASTNAME';
  if (idEl)   idEl.textContent   = 'ID : ' + (id || '???');
  if (imgEl && avatarUrl) imgEl.src = avatarUrl;
}

window.addEventListener('message', function(event) {
  var data = event.data;
  if (!data || !data.type) return;

  switch (data.type) {
    case 'openMenu':
      if (data.name) setPlayerInfo(data.name, data.id, data.avatar);
      if (data.banners) _slider.setBanners(data.banners);
      if (data.items)   renderItems(data.items);
      showUI();
      break;
    case 'closeMenu':
      hideUI();
      break;
  }
});

document.addEventListener('keydown', function(e) {
  if (e.key === 'Escape') hideUI();
});

document.addEventListener('DOMContentLoaded', function() {
  _slider.init();
});
