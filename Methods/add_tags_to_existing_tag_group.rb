def add_tags_to_existing_tag_group(tag_oligo_hash,tag_group_id)
  ActiveRecord::Base.transaction do
    tag_group = TagGroup.find_by_id(tag_group_id) or raise "Can't find tag group with is #{tag_group_id}"
    # check for unique oligo sequence
    already_present = []
    oligos = tag_group.tags.map(&:oligo)
    tag_oligo_hash.each do |index,seq|
      already_present << [index,seq] if oligos.include?(seq)
    end
    if already_present.empty?
      tag_oligo_hash.each do |index,seq|
        tag=Tag.new
        tag.oligo = seq
        tag.map_id = index
        tag.tag_group_id = tag_group.id
        tag.save!
        puts "Created tag: #{tag.map_id} => #{tag.oligo} for #{tag_group.name}"
      end; nil
    else
      puts "Repeat oligo sequence in additional tags"
      already_present.each {|a| puts "#{a[0]} => #{a[1]}"}; nil
    end
  end
end
