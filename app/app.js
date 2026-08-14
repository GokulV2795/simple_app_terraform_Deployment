(function () {
  var root = document.documentElement;
  var themeToggle = document.getElementById('theme-toggle');
  var clockEl = document.getElementById('clock');
  var counterEl = document.getElementById('counter-value');
  var counterBtn = document.getElementById('counter-btn');
  var counterReset = document.getElementById('counter-reset');
  var todoForm = document.getElementById('todo-form');
  var todoInput = document.getElementById('todo-input');
  var todoList = document.getElementById('todo-list');

  function applyTheme(theme) {
    root.setAttribute('data-theme', theme);
    themeToggle.textContent = theme === 'dark' ? 'Light mode' : 'Dark mode';
  }

  var savedTheme = localStorage.getItem('theme');
  applyTheme(savedTheme === 'dark' ? 'dark' : 'light');

  themeToggle.addEventListener('click', function () {
    var next = root.getAttribute('data-theme') === 'dark' ? 'light' : 'dark';
    applyTheme(next);
    localStorage.setItem('theme', next);
  });

  function tickClock() {
    clockEl.textContent = new Date().toLocaleTimeString();
  }
  tickClock();
  setInterval(tickClock, 1000);

  var count = 0;
  counterBtn.addEventListener('click', function () {
    count += 1;
    counterEl.textContent = String(count);
  });
  counterReset.addEventListener('click', function () {
    count = 0;
    counterEl.textContent = String(count);
  });

  function addTodoItem(text) {
    var li = document.createElement('li');

    var span = document.createElement('span');
    span.textContent = text;

    var removeBtn = document.createElement('button');
    removeBtn.type = 'button';
    removeBtn.className = 'todo-remove';
    removeBtn.setAttribute('aria-label', 'Remove note');
    removeBtn.textContent = '×';
    removeBtn.addEventListener('click', function () {
      li.remove();
    });

    li.appendChild(span);
    li.appendChild(removeBtn);
    todoList.appendChild(li);
  }

  todoForm.addEventListener('submit', function (event) {
    event.preventDefault();
    var value = todoInput.value.trim();
    if (!value) {
      return;
    }
    addTodoItem(value);
    todoInput.value = '';
    todoInput.focus();
  });
})();
