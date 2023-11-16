# frozen_string_literal: true

tournament = Tournament.find_by_identifier('')

singles = Event.create(name: 'Singles', game_count: 3, roster_type: :single, tournament: tournament)
doubles = Event.create(name: 'Doubles', game_count: 3, roster_type: :double, tournament: tournament)
team = Event.create(name: 'Team', game_count: 3, roster_type: :team, tournament: tournament)

tournament.shifts = [
  Shift.new(display_order: 1, name: 'SD1', description: 'Saturday 9am-3pm', events: [singles, doubles]),
  Shift.new(display_order: 2, name: 'SD2', description: 'Friday 5-11pm', events: [singles, doubles]),
  Shift.new(display_order: 3, name: 'T1', description: 'Thursday 7-10pm', events: [team]),
  Shift.new(display_order: 4, name: 'T2', description: 'Saturday 4:30-8pm', events: [team]),
]
