def create_tag_group_and_add_tags(tag_hash,group_name,mode)
  ActiveRecord::Base.transaction do    
    checks = tag_hash.values.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }.select {|k,v| v>1}
    if checks.empty?
      if TagGroup.find_by_name(group_name).nil?
        tag_group = TagGroup.new
        tag_group.name = group_name 
        tag_group.save!
        puts "Tag group name: #{tag_group.name} => created"
      else
        tag_group = TagGroup.find_by_name(group_name)
        raise "Tag group name: #{tag_group.name} already exists" # hash this out to add tags to group
      end

      tag_hash.each do |index,seq|
         tag=Tag.new
         tag.oligo = seq
         tag.map_id = index
         tag.tag_group_id = tag_group.id
         tag.save!
         puts "Created tag: #{tag.map_id} => #{tag.oligo} for #{tag_group.name}"
      end
      puts "Find it here http://sequencescape.psd.sanger.ac.uk:6600/tag_groups/#{tag_group.id}"
      raise "Hell!" unless mode == "run"
    else
      puts "Oligo sequences are not uniq, tag group not created"
      errors = []
      checks.each do |check|
        errors << tag_hash.select {|k,v| v == check[0]}
      end; nil
      errors.each {|error| error.map {|e| puts "tag #{e[0]} => #{e[1]}"}} ;nil
    end
  end
end
