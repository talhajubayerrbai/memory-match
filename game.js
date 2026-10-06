(function () {
  const EMOJIS = ['🍎','🍊','🍋','🍇','🍓','🎸','🚀','🐶',
                  '🌈','⚡','🎩','🦋','🍕','🎯','🔥','💎'];
  // 8 pairs = 16 cards
  const PAIRS = EMOJIS.slice(0, 8);

  let cards, flipped, matched, locked, moves;

  function shuffle(arr) {
    const a = arr.slice();
    for (let i = a.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [a[i], a[j]] = [a[j], a[i]];
    }
    return a;
  }

  function init() {
    const deck = shuffle([...PAIRS, ...PAIRS]);
    flipped = [];
    matched = 0;
    locked = false;
    moves = 0;
    document.getElementById('moves').textContent = 'Moves: 0';

    const board = document.getElementById('board');
    board.innerHTML = '';
    document.getElementById('status').textContent = 'Match all pairs to win!';

    cards = deck.map((emoji, i) => {
      const card = document.createElement('div');
      card.className = 'card';
      card.dataset.emoji = emoji;
      card.dataset.index = i;
      card.innerHTML =
        '<div class="card-inner">' +
        '<div class="card-front">?</div>' +
        '<div class="card-back">' + emoji + '</div>' +
        '</div>';
      card.addEventListener('click', onCardClick);
      board.appendChild(card);
      return card;
    });
  }

  function onCardClick() {
    if (locked) return;
    if (this.classList.contains('flipped')) return;
    if (this.classList.contains('matched')) return;

    this.classList.add('flipped');
    flipped.push(this);

    if (flipped.length === 2) {
      locked = true;
      moves++;
      document.getElementById('moves').textContent = 'Moves: ' + moves;
      const [a, b] = flipped;
      if (a.dataset.emoji === b.dataset.emoji) {
        a.classList.add('matched');
        b.classList.add('matched');
        a.classList.remove('flipped');
        b.classList.remove('flipped');
        flipped = [];
        locked = false;
        matched++;
        if (matched === PAIRS.length) {
          document.getElementById('status').textContent = '🎉 You win! All pairs matched!';
        }
      } else {
        setTimeout(function () {
          a.classList.remove('flipped');
          b.classList.remove('flipped');
          flipped = [];
          locked = false;
        }, 900);
      }
    }
  }

  document.getElementById('new-game').addEventListener('click', init);
  init();
}());
