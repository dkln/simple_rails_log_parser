require 'rubygems'
require 'hirb'

# parse MERB log file
file = ARGV.first
exit unless File.exists?(file)

actions = {}
controller = nil
action = nil
format = nil

# parse log
File.open(file, 'r') do |f|
  while line = f.gets
    # match lines that start with Params:
    if matches = line.match(/\s\sParameters:\s(\{.+\})/)
      params = eval(matches[1])
      controller = params['controller']
      action = params['action'] || 'index'

    elsif matches = line.match(/\s\sProcessing\sby\s(.+)#(.+)\sas\s/)
    # match lines that start with Processing....
      controller = matches[1].gsub(/Controller/, '').downcase
      action = matches[2]

    # match lines that end with ~ {}
    elsif matches = line.match(/Completed.+in\s([0-9\.]+)ms/) and controller and action
      actions[controller] ||= {}
      actions[controller][action] ||= { :count => 0, :action_time => matches[1].to_f / 1000.0 }

      actions[controller][action][:count] += 1
      actions[controller][action][:action_time] += matches[1].to_f

      action = nil
      controller = nil
    end
  end
end

# put in a nice table
table = []

actions.each do |controller, controller_results|
  controller_results.each do |action, action_results|
    table << [controller, action, action_results[:count], action_results[:action_time], action_results[:action_time] / action_results[:count].to_f]
  end
end

# now sort
table.sort! { |a, b| b.last <=> a.last }

puts Hirb::Helpers::Table.render(table, :headers => ['controller', 'action', 'requests', 'total time', 'avg time'])
