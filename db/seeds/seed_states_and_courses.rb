# db/seeds/states_and_courses.rb

puts "Seeding states..."

state_names = %w[
  Alabama Alaska Arizona Arkansas California Colorado Connecticut Delaware Florida Georgia
  Hawaii Idaho Illinois Indiana Iowa Kansas Kentucky Louisiana Maine Maryland
  Massachusetts Michigan Minnesota Mississippi Missouri Montana Nebraska Nevada
  New\ Hampshire New\ Jersey New\ Mexico New\ York North\ Carolina North\ Dakota
  Ohio Oklahoma Oregon Pennsylvania Rhode\ Island South\ Carolina South\ Dakota
  Tennessee Texas Utah Vermont Virginia Washington West\ Virginia Wisconsin Wyoming
]

state_names.each do |state_name|
  cleaned_name = state_name.gsub("\\", "") # handle escaped spaces
  State.find_or_create_by!(name: cleaned_name) do |state|
    state.slug = cleaned_name.parameterize
  end
end

puts "Seeded #{State.count} states."

puts "Associating courses with states..."

Course.find_each do |course|
  next if course.state.blank?

  state = State.find_by(name: course.state.strip)
  if state
    course.update!(state_id: state.id) if course.respond_to?(:state_id)
  else
    puts "⚠️ No matching state found for course #{course.id} (#{course.name}) with state '#{course.state}'"
  end
end

puts "✅ Done associating courses."
