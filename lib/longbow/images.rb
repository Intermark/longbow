$:.push File.expand_path('../', __FILE__)
require 'mini_magick'
require 'colors'
require 'xcodeproj'
require 'open-uri'

module Longbow

  # Images
  def self.create_images directory, t, obj
    # Bad Params
    if !directory || !t || !obj
      return false
    end

    # Get Device Information
    iPhone = false
    iPad = false
    if obj['devices']
      obj['devices'].each do |d|
        iPhone = true if d == 'iPhone'
        iPad = true if d == 'iPad'
      end
    end

    # Resize Icons
    resize_icons directory, t, iPhone, iPad

    # Resize Launch Images
    resize_launch_images directory, t

    # Write JSON for Icon Assets
    write_json_for_icons directory, t, iPhone, iPad

    # Write JSON for Launch Assets
    write_json_for_launch_images directory, t

  end


  # Create & Resize Icons
  def self.resize_icons directory, t, iPhone, iPad
    # Set Up
    target = t['name']

    # Get Image Information
    img_path = ''
    if t['icon_url']
      img_path = self.path_for_downloaded_image_from_url directory, target, t['icon_url'], 'icons'
    elsif t['icon_path']
      img_path = directory + '/' + t['icon_path']
    end

    # Make directory
    img_dir = make_asset_directory directory, target, '.appiconset/'

    # Size for iPhone
    if iPhone
      image = MiniMagick::Image.open(img_path)
      return false unless image
      ['120x120', '114x114', '80x80', '58x58', '57x57', '29x29'].each do |size|
        resize_image_to_directory img_dir, image, size, 'icon'
      end
    end

    # iPad
    if iPad
      image = MiniMagick::Image.open(img_path)
      return false unless image
      ['152x152', '144x144', '100x100', '80x80', '76x76', '72x72', '58x58', '50x50', '40x40', '29x29'].each do |size|
        resize_image_to_directory img_dir, image, size, 'icon'
      end
    end

    Longbow::green ('  - Created Icon images for ' + target) unless $nolog
    return true
  end


  # Create & Resize Launch Images
  def self.resize_launch_images directory, t
    # Set Up
    target = t['name']

    ['launch_phone_p', 'launch_phone_l', 'launch_tablet_p', 'launch_tablet_l'].each do |key|
      img_path = ''
      if t[key + '_url']
        img_path = self.path_for_downloaded_image_from_url directory, key + '_' + target, t[key + '_url'], 'launch'
      elsif t[key + '_path']
        img_path = directory + '/' + t[key + '_path']
      else
        next
      end

      # Make directory
      img_dir = make_asset_directory directory, target, '.launchimage/'

      # Make resize sizes
      sizes = []
      if key == 'launch_phone_p'
        sizes = ['640x1136','640x960']
      elsif key == 'launch_phone_l'
        sizes = ['1136x640','960x640']
      elsif key == 'launch_tablet_p'
        sizes = ['1536x2048','768x1024']
      elsif key == 'launch_tablet_l'
        sizes = ['2048x1536','1024x768']
      end

      # Resize Images
      sizes.each do |size|
        image = MiniMagick::Image.open(img_path)
        return false unless image
        resize_image_to_directory img_dir, image, size, key + '_'
      end
    end

    Longbow::green ('  - Created Launch images for ' + target) unless $nolog
    return true
  end


  # Resize Image to Directory
  def self.resize_image_to_directory directory, image, size, tag
    sizes = size.split('x')
    new_w = Integer(sizes[0])
    new_h = Integer(sizes[1])
    w = image[:width]
    h = image[:height]
    if w < h
      m = new_w.to_f/w
      new_size = new_w.to_s + 'x' + (h*m).to_i.to_s
    else
      m = new_h.to_f/h
      new_size = (w*m).to_i.to_s + 'x' + new_h.to_s
    end

    image.resize new_size
    image.crop size + '+0+0' unless new_size == size
    image.write  directory + '/' + tag + size + '.png'
  end


  # Create JSON
  def self.write_json_for_icons directory, t, iPhone, iPad
    # Set Up
    target = t['name']

    # Make directory
    img_dir = make_asset_directory directory, target, '.appiconset/'

    # Write the JSON file
    File.open(img_dir + '/Contents.json', 'w') do |f|
      f.write('{ "images" : [ ')

      if iPhone
        f.write( '{ "size" : "29x29", "idiom" : "iphone", "filename" : "icon58x58.png", "scale" : "2x" }, { "size" : "40x40", "idiom" : "iphone", "filename" : "icon80x80.png", "scale" : "2x" }, { "size" : "60x60", "idiom" : "iphone", "filename" : "icon120x120.png", "scale" : "2x" }, { "size" : "29x29", "idiom" : "iphone", "filename" : "icon29x29.png", "scale" : "1x" }, { "size" : "57x57", "idiom" : "iphone", "filename" : "icon57x57.png", "scale" : "1x" }, { "size" : "57x57", "idiom" : "iphone", "filename" : "icon114x114.png", "scale" : "2x" }' + (iPad ? ',' : ''))
      end

      if iPad
        f.write( '{ "idiom" : "ipad", "size" : "29x29", "scale" : "1x", "filename" : "icon29x29.png" }, { "idiom" : "ipad", "size" : "29x29", "scale" : "2x", "filename" : "icon58x58.png" }, { "idiom" : "ipad", "size" : "40x40", "scale" : "1x", "filename" : "icon40x40.png" }, { "idiom" : "ipad", "size" : "40x40", "scale" : "2x", "filename" : "icon80x80.png" }, { "idiom" : "ipad", "size" : "76x76", "scale" : "1x", "filename" : "icon76x76.png" }, { "idiom" : "ipad", "size" : "76x76", "scale" : "2x", "filename" : "icon152x152.png" }, { "idiom" : "ipad", "size" : "50x50", "scale" : "1x", "filename" : "icon50x50.png" }, { "idiom" : "ipad", "size" : "50x50", "scale" : "2x", "filename" : "icon100x100.png" }, { "idiom" : "ipad", "size" : "72x72", "scale" : "1x", "filename" : "icon72x72.png" }, { "idiom" : "ipad", "size" : "72x72", "scale" : "2x", "filename" : "icon144x144.png" }')
      end

      f.write(' ], "info" : { "version" : 1, "author" : "xcode" }, "properties" : { "pre-rendered" : true } }')
    end

    # Return true
    Longbow::green ('  - Created Images.xcassets icon set for ' + target) unless $nolog
    return true
  end


  # JSON for Launch Images
  def self.write_json_for_launch_images directory, t
    # Set Up
    target = t['name']
    phone_portrait = t['launch_phone_p_url'] || t['launch_phone_p_path']
    phone_landscape = t['launch_phone_l_url'] || t['launch_phone_l_path']
    tablet_portrait = t['launch_tablet_p_url'] || t['launch_tablet_p_path']
    tablet_landscape = t['launch_tablet_l_url'] || t['launch_tablet_l_path']
    return false unless phone_portrait || phone_landscape || tablet_landscape || tablet_portrait

    # Make Directory
    img_dir = make_asset_directory directory, target, '.launchimage/'

    File.open(img_dir + '/Contents.json', 'w') do |f|
      f.write('{"images" : [')

      if phone_portrait
        f.write('{
      "orientation" : "portrait",
      "idiom" : "iphone",
      "extent" : "full-screen",
      "minimum-system-version" : "7.0",
      "filename" : "launch_phone_p_640x960.png",
      "scale" : "2x"
    },
    {
      "extent" : "full-screen",
      "idiom" : "iphone",
      "subtype" : "retina4",
      "filename" : "launch_phone_p_640x1136.png",
      "minimum-system-version" : "7.0",
      "orientation" : "portrait",
      "scale" : "2x"
    }')
        f.write ',' if phone_landscape || tablet_portrait || tablet_landscape
      end

      if phone_landscape
        f.write('{
      "orientation" : "landscape",
      "idiom" : "iphone",
      "extent" : "full-screen",
      "minimum-system-version" : "7.0",
      "filename" : "launch_phone_l_960x640.png",
      "scale" : "2x"
    },
    {
      "extent" : "full-screen",
      "idiom" : "iphone",
      "subtype" : "retina4",
      "filename" : "launch_phone_l_1136x640.png",
      "minimum-system-version" : "7.0",
      "orientation" : "landscape",
      "scale" : "2x"
    }')
        f.write ',' if tablet_portrait || tablet_landscape
      end

      if tablet_portrait
        f.write('{
      "orientation" : "portrait",
      "idiom" : "ipad",
      "extent" : "full-screen",
      "filename" : "launch_tablet_p_768x1024.png",
      "minimum-system-version" : "7.0",
      "scale" : "1x"
    },
    {
      "orientation" : "portrait",
      "idiom" : "ipad",
      "extent" : "full-screen",
      "filename" : "launch_tablet_p_1536x2048.png",
      "minimum-system-version" : "7.0",
      "scale" : "2x"
    }')
        f.write ',' if tablet_landscape
      end

      if tablet_landscape
        f.write('{
      "orientation" : "landscape",
      "idiom" : "ipad",
      "extent" : "full-screen",
      "filename" : "launch_tablet_l_1024x768.png",
      "minimum-system-version" : "7.0",
      "scale" : "1x"
    },
    {
      "orientation" : "landscape",
      "idiom" : "ipad",
      "extent" : "full-screen",
      "filename" : "launch_tablet_l_2048x1536.png",
      "minimum-system-version" : "7.0",
      "scale" : "2x"
    }')
      end

      f.write('],"info" : {"version" : 1,"author" : "xcode"}}')
    end

    # Return true
    Longbow::green ('  - Created Images.xcassets launch image set for ' + target) unless $nolog
    return true
  end


  # Asset Directory Methods
  def self.make_asset_directory directory, target, path_extension
    asset_path = assets_file_path directory
    full_path = asset_path + '/' + target + path_extension
    FileUtils::mkdir_p full_path
    return full_path
  end

  def self.assets_file_path directory
    asset_path = ''
    Dir.glob(directory + '/**/*/').each do |d|
      searching = 'Images.xcassets/'
      asset_path = d if d.slice(d.length - searching.length, searching.length) == searching
      break if asset_path.length > 0
    end

    return asset_path
  end


  # Download Image from URL
  def self.path_for_downloaded_image_from_url directory, filename, url, folder
    img_path = directory + '/resources/'+ folder + '/'
    img_file_name = filename + '.png'
    FileUtils::mkdir_p img_path
    File.open(img_path + img_file_name, 'wb') do |f|
      f.write open(url).read
    end

    return img_path + img_file_name
  end


end