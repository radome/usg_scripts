def update_plate_well_tags(plate,sample_tag_hash,tag_group)
  ActiveRecord::Base.transaction do
    plate.wells.each do |well|
      tag = sample_tag_hash[well.map_description]
      well.aliquots.first.update_attributes!(:tag_id => TagGroup.find(tag_group).tags.select {|t| t.map_id == tag}.map(&:id).first) unless tag == nil
    end
  end
end

