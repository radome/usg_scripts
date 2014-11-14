def update_mx_to_isch_tube(mx_ids, mode)
  ActiveRecord::Base.transaction do
    mx_ids.each {|mx_id| Asset.find(mx_id).update_attributes!(:purpose=>Purpose.find_by_name('Lib Pool Norm'))}
    raise "Hell!!!!" unless mode == 'run'
  end
end