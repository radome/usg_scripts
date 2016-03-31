def having_added_extra_aliquots_to_lane_add_indices(mx_id, mode)
  ActiveRecord::Base.transaction do
    mx = MultiplexedLibraryTube.find_by_id(mx_id)
    mx.children.map {|l| l.aliquots.map(&:aliquot_index).compact.map(&:destroy)}
    mx.children.map {|l| AliquotIndexer.index(l)}
    mx.requests.map(&:batch).uniq.first.touch
    raise "Hell!!!" unless mode == 'run'
  end
end
