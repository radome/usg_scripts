# This is for sample tubes only not wells
def create_and_populate_asset_groups(sample_group_hash, study_id, mode)
  ActiveRecord::Base.transaction do
    puts "Creating #{sample_group_hash.first[1]}"
    @ag = AssetGroup.create!(:name => sample_group_hash.first[1], :study_id => study_id)
    sample_group_hash.each do |sample_name,ag_name|
      sample = Sample.find_all_by_name(sample_name).map.select {|s| s.name == sample_name}.first
      sample_tube = sample.assets.first
      if ag_name == @ag.name
        @ag.assets << sample_tube
        @ag.save!
        puts "#{@ag.assets.map(&:name).inspect}"
      else
        puts "http://production.psd.sanger.ac.uk:6600/studies/#{study_id}/asset_groups/#{@ag.id}"
        puts "Creating #{ag_name}"
        @ag = AssetGroup.create!(:name => ag_name, :study_id => study_id)
        @ag.assets << sample_tube
        @ag.save!
        puts "#{@ag.assets.map(&:name).inspect}"
      end
    end; nil
    puts "http://production.psd.sanger.ac.uk:6600/studies/#{study_id}/asset_groups/#{@ag.id}"
    raise "Hell!!!!" unless mode == 'run'
  end
end
