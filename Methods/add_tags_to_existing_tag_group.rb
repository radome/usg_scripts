def add_tags_to_existing_tag_group(tag_hash,tag_group_id, mode)
  ActiveRecord::Base.transaction do
    tag_group = TagGroup.find_by_id(tag_group_id) or raise "Can't find tag group with is #{tag_group_id}"
    # check for unique oligo sequence in tag_hash
    checks = tag_hash.values.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }.select {|k,v| v>1}
    if checks.empty?
      # check that oligo seq is not in existing in tag_group
      already_present = []
      oligos = tag_group.tags.map(&:oligo)
      tag_hash.each do |index,seq|
        already_present << [index,seq] if oligos.include?(seq)
      end
      if already_present.empty?
        # Add tags to existing tag group
        tag_hash.each do |index,seq|
          tag=Tag.new
          tag.oligo = seq
          tag.map_id = index
          tag.tag_group_id = tag_group.id
          tag.save!
          puts "Created tag: #{tag.map_id} => #{tag.oligo} for #{tag_group.name}"
        end; nil
      else
        puts "Non unique sequence between existing oligo and additional oligo in tag list"
        already_present.each {|a| tag = tag_group.tags.select {|t| t.oligo == a[1]}.first; puts "#{a[0]} => #{a[1]} :: Existing #{tag.map_id} => #{tag.oligo}"}; nil
      end
    else
      puts "Oligo sequences are not uniq within additional tags list"
      errors = []
      checks.each do |check|
        errors << tag_hash.select {|k,v| v == check[0]}
      end; nil
      errors.each {|error| error.map {|e| puts "tag #{e[0]} => #{e[1]}"}} ;nil      
    end
  end
  raise "Hell!!!" unless mode == 'run'
end
