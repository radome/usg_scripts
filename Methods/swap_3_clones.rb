def swap_clones(sample_names,temp_asset_id,mode)
  ActiveRecord::Base.transaction do
    sample_A = Sample.find_by_name(sample_names[0])
    sample_B = Sample.find_by_name(sample_names[1])
    sample_C = Sample.find_by_name(sample_names[2])
    sample_A_assets = sample_A.assets.map(&:id); sample_A_assets.shift
    sample_B_assets = sample_B.assets.map(&:id); sample_B_assets.shift
    sample_C_assets = sample_B.assets.map(&:id); sample_B_assets.shift
    temp_asset = SampleTube.create
    Asset.find(temp_asset.id).aliquots = Asset.find(temp_asset_id).aliquots.map(&:clone)
    [
      { :from => sample_C.assets.first, :to => temp_asset, :assets => sample_B_assets },
      { :from => sample_B.assets.first, :to => sample_C.assets.first, :assets => sample_A_assets },
      { :from => sample_A.assets.first, :to => sample_B.assets.first, :assets => sample_A_assets },
      { :from => temp_asset, :to => sample_C.assets.first, :assets => sample_B_assets }
    ].each do |details|
      tube_from, tube_to = details[:from], details[:to]
      raise "Too many aliquots in tube_from #{details[:from]}" if tube_from.aliquots.size > 1
      raise "No aliquots in tube_from #{details[:from]}" if tube_from.aliquots.empty?
      raise "Too many aliquots in tube_to #{details[:to]}" if tube_to.aliquots.size > 1
      raise "No aliquots in tube_to #{details[:to]}" if tube_to.aliquots.empty?
      # Find all of the aliquots for the sample in the 'from' tube that exist in the library tube, MX library tube, or lane.  Then
      # update their sample so that it is the sample contained in the 'to' tube.
      aliquots = tube_from.aliquots.first.sample.aliquots.all(:conditions => { :receptacle_id => details[:assets] })
      # Move the library asset link to the correct sample tube
      asset_link = AssetLink.find_by_ancestor_id_and_descendant_id(details[:from].id,details[:assets].first)
      asset_link.update_attribute(:ancestor_id,details[:to].id)
      aliquots.each { |a| a.update_attributes!(:sample => tube_to.aliquots.first.sample) }
      # Now make sure that the requests from the 'from' sample tube are actually from the 'to' sample tube.
      tube_from.requests.select {|r| r.sti_type == "MultiplexedLibraryCreationRequest"}.first.update_attributes!(:asset => tube_to)

      library_tube = Asset.find(details[:assets].first)
      new_name = "#{tube_to.name} #{library_tube.id}"
      library_tube.name = new_name
      library_tube.save!
    end

    temp_asset.destroy
    puts ".... Finished"
    raise "Hell !!! ... test mode" unless mode == 'run'   
  end
end
