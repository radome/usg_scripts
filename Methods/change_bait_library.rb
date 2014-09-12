def change_bait_library(mx_id,bait_id,mode)
  ActiveRecord::Base.transaction do
    bait_lib = BaitLibrary.find(bait_id)
    mx = Asset.find(mx_id)
    mx.aliquots.map {|a| a.bait_library_id = bait_lib.id; a.save!}
    mx.children.map(&:aliquots).flatten.map {|a| a.bait_library_id = bait_lib.id; a.save!}
    mx.requests_as_source.map(&:submission).each do |submission|
      submission.orders.each do |order|
        order.request_options[:bait_library_name] = bait_lib.name
        order.save!
      end
      submission.requests.each do |request|
        request.request_metadata.update_attributes!(:bait_library => bait_lib) if request.request_type_id == submission.order.request_types[0]
      end
    end
    raise "Testing" unless mode == "run"
  end
end
