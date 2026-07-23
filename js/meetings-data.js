/* ==========================================================================
   Upcoming PTA meetings — EDIT THIS FILE to update the meetings page.

   Add new meetings to the top of the list. Meetings whose date is in the
   past are hidden automatically, so there is no need to delete old ones
   right away.

   Fields:
     date     "YYYY-MM-DD" (used for sorting and hiding past meetings)
     title    short name of the meeting
     when     human-readable time & place line
     agenda   list of agenda items (shown as bullets)
   ========================================================================== */

const MEETINGS = [
  {
    date: "2026-09-01",
    title: "September PTA Meeting · Reunión de septiembre",
    when: "Tue Sep 1 · 6:00–7:30 PM · School library (childcare provided)",
    agenda: [
      "Welcome back & introductions — bienvenidos",
      "This year's budget: what we're funding and why",
      "Fall Fiesta planning kickoff (volunteers needed!)",
      "Open floor: your questions & ideas",
    ],
  },
  {
    date: "2026-10-06",
    title: "October PTA Meeting · Reunión de octubre",
    when: "Tue Oct 6 · 6:00–7:30 PM · School library (childcare provided)",
    agenda: [
      "Fall Fiesta final logistics",
      "Teacher wishlist grants — vote",
      "Día de los Muertos celebration planning",
    ],
  },
  {
    date: "2026-11-03",
    title: "November PTA Meeting · Reunión de noviembre",
    when: "Tue Nov 3 · 6:00–7:30 PM · School library (childcare provided)",
    agenda: [
      "Fall Fiesta recap & thank-yous",
      "Winter giving drive",
      "Mid-year budget check-in",
    ],
  },
];

/* ---- Rendering (no need to edit below this line) ------------------------- */

function renderMeetings() {
  const list = document.querySelector('.meeting-list');
  if (!list) return;

  const today = new Date().toISOString().slice(0, 10);
  const upcoming = MEETINGS
    .filter((m) => m.date >= today)
    .sort((a, b) => a.date.localeCompare(b.date));

  if (upcoming.length === 0) {
    list.innerHTML = '<p class="lead">No meetings scheduled right now — check the calendar below or join a WhatsApp group to hear when the next one lands.</p>';
    return;
  }

  const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  list.innerHTML = upcoming
    .map((m) => {
      const [, month, day] = m.date.split('-').map(Number);
      const agenda = m.agenda.map((item) => `<li>${item}</li>`).join('');
      return `
        <article class="meeting">
          <div class="meeting-date">
            <div class="month">${MONTHS[month - 1]}</div>
            <div class="day">${day}</div>
          </div>
          <div>
            <h3>${m.title}</h3>
            <p class="when">${m.when}</p>
            <h4>Agenda</h4>
            <ul>${agenda}</ul>
          </div>
        </article>`;
    })
    .join('');
}

renderMeetings();
