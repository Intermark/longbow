$:.push File.expand_path('../../', __FILE__)
require 'fileutils'
require 'longbow/colors'
require 'longbow/targets'
require 'longbow/images'
require 'longbow/json'
require 'json'

command :shoot do |c|
  c.syntax = 'longbow shoot [options]'
  c.summary = 'Creates/updates a target or all targets in your workspace or project.'
  c.description = ''
  c.option '-n', '--name NAME', 'Target name from the corresponding longbow.json file.'
  c.option '-d', '--directory DIRECTORY', 'Path where the .xcodeproj or .xcworkspace file && the longbow.json file live.'
  c.option '-u', '--url URL', 'URL of a longbow formatted JSON file.'
  c.option '-i', '--images', 'Set this flag to not recreate images in the longbow file.'
  c.option '-l', '--launchscreenimages', 'Set this flag to create launch screen images.'

  c.action do |args, options|
    # Check for newer version
    Longbow::check_for_newer_version unless $nolog

    # Set Up
    @target_name = options.name ? options.name : nil
    @directory = options.directory ? options.directory : Dir.pwd
    @noimages = options.images ? true : false
    @lsimages = options.launchscreenimages ? true : false
    @url = options.url ? options.url : nil
    @targets = []

    # Create JSON object
    if @url
      obj = Longbow::json_object_from_url @url
    else
      obj = Longbow::json_object_from_directory @directory
    end

    # Break if Bad
    unless obj || Longbow::lint_json_object(obj)
      Longbow::red "\n  Invalid JSON. Please lint the file, and try again.\n"
      next
    end


    # Check for Target Name
    if @target_name
      obj['targets'].each do |t|
        @targets << t if t['name'] == @target_name
      end

      if @targets.length == 0
        Longbow::red "\n  Couldn't find a target named #{@target_name} in the longbow.json file.\n"
        next
      end
    else
      @targets = obj['targets']
    end

    # Begin
    @targets.each do |t|
      icon = t['icon_url'] || t['icon_path']
      launch = nil
      if @lsimages
        launch = t['launch_phone_p_url'] || t['launch_phone_p_path'] || t['launch_phone_l_url'] || t['launch_phone_l_path'] || t['launch_tablet_p_url'] || t['launch_tablet_p_path'] || t['launch_tablet_l_url'] || t['launch_tablet_l_path']
      end
      Longbow::update_target @directory, t['name'], obj['global_info_keys'], t['info_plist'], icon, launch
      Longbow::create_images(@directory, t, obj, @lsimages) unless @noimages
      Longbow::green "  Finished: #{t['name']}\n" unless $nolog
    end
  end
end
