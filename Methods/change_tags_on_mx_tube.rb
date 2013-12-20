def change_tags_on_batch(tags,tag_group,mx_tube,mode)
  puts "Supply: tags (in correct order i.e [1,2,4,8,3,5,6,7], tag_group (id), mx_tube (id), mode ('test'/'run')\n"
  puts "Running in test mode\n" unless mode == "run"

  ActiveRecord::Base.transaction do
  def set_false_tags(library_and_tag_hash)
    ActiveRecord::Base.transaction do
      # puts "#{library_and_tag_hash.inspect}\n\n"
      lib_tags = []
      library_and_tag_hash.each do |library,tag|
        aliquots = Aliquot.find_all_by_library_id(library)
        lib_tags.push(aliquots.first.tag)
          aliquots.each do |aliquot|   
            aliquot.tag_id = tag
            aliquot.save!
            # puts "#{aliquot.inspect}\n"
            puts "Aliquot: #{aliquot.id} => Sample: #{aliquot.sample.name} => old tag: #{lib_tags.last.map_id} => new tag: #{tag}"
          end
      end
    end
  end
  
  def change_tags(libraries, sample_tag_hash, tag_group)
    ActiveRecord::Base.transaction do
      lib_tags = []
      libraries.each do |library|
        aliquots = Aliquot.find_all_by_library_id(library)
          aliquots.each do |aliquot|   
            aliquot.tag_id = TagGroup.find(tag_group).tags.select {|t| t.map_id == sample_tag_hash[aliquot.sample.name]}.map(&:id).first
            aliquot.save!
            puts "Aliquot: #{aliquot.id} => Sample: #{aliquot.sample.name} => new tag: #{aliquot.tag.map_id}"
          end
      end
    end
  end
  
  mx = Asset.find(mx_tube)

  # find the library id's of the mx_tube
  lib_ids = mx.aliquots.map(&:library_id)
  
  if lib_ids.size == tags.size
    puts "lib <=> tag count ok"
  else
    puts "Library count: #{lib_ids.size} tag count: #{tags.size}"
    break
  end
  
  samples = mx.aliquots.map(&:sample).flatten.map(&:name)
  
  sample_tag_hash = Hash[samples.zip(tags)]

  false_tag_hash = Hash[lib_ids.zip((1..sample_tag_hash.size).entries)]
  
  puts "sample_tag_hash: #{sample_tag_hash.inspect}\n\n"
  puts "false_tag_hash: #{false_tag_hash.inspect}"

  puts "Setting false tags on libraries"
  set_false_tags(false_tag_hash)

  puts "Assigning new tags"
  change_tags(lib_ids,sample_tag_hash,tag_group)

  raise "TESTING *********" unless mode == "run"
  end
end
