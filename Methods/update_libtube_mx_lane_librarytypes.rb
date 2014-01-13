def update_libtube_mx_lane_librarytypes(mx_tube_id, new_lib_name, mode)
  ActiveRecord::Base.transaction do
    mx = Asset.find mx_tube_id
    mx.aliquots.each do |aliquot|
      aliquots = Aliquot.find_all_by_library_id(aliquot.library_id)
      aliquots.each  do |a| 
        a.update_attributes!(:library_type => new_lib_name)
      end
    end
    raise 'Hell!!' unless mode == 'run'
  end
end