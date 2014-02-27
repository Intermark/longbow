require 'fileutils'

command :update do |c|
  c.syntax = 'longbow update [options]'
  c.summary = 'Updates from the .longbow.json file'
  c.description = ''

  c.option '-n', '--name NAME', 'Target name from the corresponding .longbow.json file.'
  c.option '-d', '--directory DIRECTORY', 'Path where the .xcproj or .xcworkspace file && the .longbow.json file live.'
  c.option '-s', '--screenshots', 'Creates screenshots from where the current .longbow.screens file lives.'

  c.action do |args, options|
    # Set Up
    @target_name = options.name
    @directory = options.directory ? options.directory : Dir.pwd
    @screenshots = options.screenshots ? options.screenshots : false

    # Check for .longbow.json
    @json_path = @directory + '/.longbow.json'
    if !File.exists?(@json_path)
      puts "Couldn't find .longbow.json at " + @json_path
      puts
      puts "Run this command to install the correct files:"
      puts
      puts "longbow install"
      puts
      puts
      next
    end

    # Begin
    puts @target_name ? 'Target: ' + @target_name : 'No Target!'
    puts @directory
    puts @screenshots
  end
end