def reindex_batch(batch_id, mode)
  ActiveRecord::Base.transaction do
    batch = Batch.find_by_id(batch_id)
    batch.assets.map {|l| l.aliquots.map(&:aliquot_index).compact.map(&:destroy)}
    batch.assets.map {|l| AliquotIndexer.index(l)}
    batch.touch
    raise "Hell!!!" unless mode == 'run'
  end
end