def change_phix_in_batch(batch_id,phix_barcode,mode)
  ActiveRecord::Base.transaction do
    sb = SpikedBuffer.find_by_barcode(phix_barcode.to_s)
    lane_ids = Batch.find(batch_id).assets.map(&:id); nil
    links = AssetLink.find_all_by_descendant_id(lane_ids).select {|al| al.ancestor.class.name == "SpikedBuffer"}; nil
    links.select {|l| l.direct == false}.map {|link| link.update_attribute(:ancestor_id, sb.parent.id)}
    links.select {|l| l.direct == true}.map {|link| link.update_attribute(:ancestor_id, sb.id)}
    puts "Batch #{batch_id} updating PhiX.."
    Batch.find(batch_id).touch
    puts "..updated"
  end
end
