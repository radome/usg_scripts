def change_library_type_name(lane_ids, lib_type_name = "Chromium single cell")
  ActiveRecord::Base.transaction do
    lib_ids = Lane.where(id: lane_ids).map(&:aliquots).flatten.map(&:library_id)
    Aliquot.where(library_id: lib_ids).each {|a| a.library_type = lib_type_name; a.save!}; nil
    batches = Lane.where(id: lane_ids).map(&:creation_batches).flatten.uniq
    puts "#{batches.map(&:id)}"
    batches.map {|b| b.touch}; nil
  end
end

# select DISTINCT(entity_id_lims) from iseq_flowcell where BINARY pipeline_id_lims LIKE '%chromium single cell%';