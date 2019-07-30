def destroy_tube(barcode)
  t = Tube.find_by_barcode(barcode)
  raise "Unable to find tube #{barcode}" if t.nil?
  als=AssetLink.where(ancestor_id: t.id); nil
  als.each {|l| l.update_attribute(ancestor_id: nil)}
  als=AssetLink.where(descendant_id: t.id); nil
  als.each {|l| l.update_attribute(:ancestor_id, nil)}
  als.each {|l| l.update_attribute(:descendant_id, nil)}
  t.transfer_requests_as_target.map(&:cancel_before_started!)
  t.transfer_requests_as_target.map(&:destroy)
  t.destroy
end
