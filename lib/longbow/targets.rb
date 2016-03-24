require 'xcodeproj'
require 'colors'
require 'plist'
require 'utilities'

module Longbow

  def self.update_target directory, target, global_keys, info_keys, icon, launch
    unless directory && target
      Longbow::red '  Invalid parameters. Could not create/update target named: ' + target
      return false
    end

    # Find Project File
    project_paths = []
    Dir.foreach(directory) do |fname|
      project_paths << fname if fname.include? '.xcodeproj'
    end

    # Open The Project
    return false if project_paths.length == 0
    proj = Xcodeproj::Project.open(project_paths[0])

    # Get Main Target's Basic Info
    @target = nil
    proj.targets.each do |t|
      if t.to_s == target
        @target = t
        Longbow::blue '  ' + target + ' found.' unless $nolog
        break
      end
    end

    #puts proj.pretty_print

    # Create Target if Necessary
    main_target = proj.targets.first
    @target = create_target(proj, target) unless @target

    # Plist Creating/Adding
    main_plist = main_target.build_configurations[0].build_settings['INFOPLIST_FILE']
    main_plist_contents = File.read(directory + '/' + main_plist)
    target_plist_path = directory + '/' + main_plist.split('/')[0] + '/' + target + '-info.plist'
    plist_text = Longbow::create_plist_from_old_plist main_plist_contents, info_keys, global_keys
    File.open(target_plist_path, 'w') do |f|
      f.write(plist_text)
    end
    Longbow::green '  - ' + target + '-info.plist Updated.' unless $nolog


    # Add Build Settings
    @target.build_configurations.each do |b|
      # Main Settings
      main_settings = nil
      base_config = nil
      main_target.build_configurations.each do |bc|
        main_settings = bc.build_settings if bc.to_s == b.to_s
        base_config = bc.base_configuration_reference if bc.to_s == b.to_s
      end
      settings = b.build_settings
      main_settings.each_key do |key|
        settings[key] = main_settings[key]
      end

      # Plist & Icons
      settings['INFOPLIST_FILE'] = main_plist.split('/')[0] + '/' + target + '-info.plist'
      settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = Longbow::stripped_text(target) if icon
      settings['ASSETCATALOG_COMPILER_LAUNCHIMAGE_NAME'] = Longbow::stripped_text(target) if launch
      settings['SKIP_INSTALL'] = 'NO'

      if File.exists? directory + '/Pods'
        b.base_configuration_reference = base_config
        settings['PODS_ROOT'] = '${SRCROOT}/Pods'
      end
    end

    # Save The Project
    proj.save
  end

  def self.create_target project, target
    main_target = project.targets.first
    deployment_target = main_target.deployment_target

    # Create New Target
    new_target = Xcodeproj::Project::ProjectHelper.new_target project, :application, target, :ios, deployment_target, project.products_group, 'en'
    if new_target
      # Add Build Phases
      main_target.build_phases.objects.each do |b|
        if b.isa == 'PBXSourcesBuildPhase'
          b.files_references.each do |f|
            new_target.source_build_phase.add_file_reference f
          end
        elsif b.isa == 'PBXFrameworksBuildPhase'
          b.files_references.each do |f|
            new_target.frameworks_build_phase.add_file_reference f
          end
        elsif b.isa == 'PBXResourcesBuildPhase'
          b.files_references.each do |f|
            new_target.resources_build_phase.add_file_reference f
          end
        elsif b.isa == 'PBXShellScriptBuildPhase'
          phase = new_target.new_shell_script_build_phase(name = b.display_name)
          phase.shell_script = b.shell_script
        end
      end

      Longbow::blue '  ' + target + ' created.' unless $nolog
    else
      puts
      Longbow::red '  Target Creation failed for target named: ' + target
      puts
    end

    return new_target
  end

end
