def create_and_populate_tag_group(tag_hash,group_name,mode)
  ActiveRecord::Base.transaction do

    if TagGroup.find_by_name(group_name).nil?
      tag_group = TagGroup.new
      tag_group.name = group_name 
      tag_group.save
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
       tag.save
       puts "Created tag: #{tag.map_id} => #{tag.oligo} for #{tag_group.name}"
    end
    raise "Hell!" unless mode == "run"
  end
end
