def destroy_tube(t)
  als=AssetLink.where(ancestor_id: t.id); nil
  als.each {|l| l.update_attribute(ancestor_id: nil)}
  als=AssetLink.where(descendant_id: t.id); nil
  als.each {|l| l.update_attribute(:ancestor_id, nil)}
  als.each {|l| l.update_attribute(:descendant_id, nil)}
  t.transfer_requests_as_target.map(&:cancel_before_started!)
  t.transfer_requests_as_target.map(&:destroy)
  t.destroy
end
