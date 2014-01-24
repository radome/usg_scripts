def change_tags_on_batch(sample_tag_hash,tag_group,mx_tube,mode)
  puts "Supply: sample_tag_hash (sample_name => map_id), tag_group (id), mx_tube (id), mode ('test'/'run')\n"
  puts "Running in test mode\n" unless mode == "run"

  ActiveRecord::Base.transaction do
  def set_false_tags(lib_aliquots, false_tag_hash)
    lib_tags = []
    c = false_tag_hash.size
    false_tag_hash.each do |library,tag|
      aliquots = Asset.find(library).aliquots.first.sample.aliquots
      aliquots.each do |aliquot|
        if aliquot.tag_id != -1
          lib_tags.push(aliquot.tag)
          aliquot.tag_id = tag
          aliquot.save!
          lib_aliquots << aliquot
          puts "#{c} >> Aliquot: #{aliquot.id} => Sample: #{aliquot.sample.name} => old tag: #{lib_tags.last.map_id} => new tag: #{aliquot.tag.map_id}"
        end
      end
      c -=1
    end
    return lib_aliquots
  end
  
  def change_tags(lib_aliquots, sample_tag_hash, tag_group)
    c = lib_aliquots.size
    lib_aliquots.each do |aliquot|   
      aliquot.tag_id = TagGroup.find(tag_group).tags.select {|t| t.map_id == sample_tag_hash[aliquot.sample.name]}.map(&:id).first
      aliquot.save!
      puts "#{c} >> Aliquot: #{aliquot.id} => Sample: #{aliquot.sample.name} => new tag: #{sample_tag_hash[aliquot.sample.name]}"
      c -=1
    end
  end
  
  mx = Asset.find(mx_tube)
  lib_aliquots = []
  
  # find the library id's of the mx_tube
  lib_ids = mx.aliquots.map(&:library_id)
  
  samples = mx.aliquots.map(&:sample).flatten.map(&:name)
  keys = sample_tag_hash.keys; nil
  problems = samples - keys
  if problems.empty?
    puts "Hash and mx.aliquots match. Proceeding..."
  else
    puts "Problems...\n#{problems.inspect}\n"
    raise "hash keys and mx samples do not match"
  end
  
  false_tag_hash = Hash[lib_ids.zip((1..sample_tag_hash.size).entries)]
  
  puts "sample_tag_hash: #{sample_tag_hash.inspect}\n\n"
  puts "false_tag_hash: #{false_tag_hash.inspect}"

  puts "Setting false tags on libraries"
  set_false_tags(lib_aliquots, false_tag_hash)

  puts "Assigning new tags"
  change_tags(lib_aliquots, sample_tag_hash, tag_group)

  raise "TESTING *********" unless mode == "run"
  end
end
