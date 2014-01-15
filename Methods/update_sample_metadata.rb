# Takes sample_ids array and updates sample metadata
# will need to add further field updates where necessary

def update_samples(sample_ids, common_name, taxon_id, mode)
  ActiveRecord::Base.transaction do
    samples.each do |sample|
      sample_metadata = Sample.find_by_id(sample).sample_metadata
      if sample_metadata.nil?
        puts "unable to find sample #{sample}"
      else
        puts "changing common_name from #{sample_metadata.sample_common_name} => #{common_name}"
        sample_metadata.update_attributes(:sample_common_name => common_name)
        puts "changing taxon id from #{sample_metadata.sample_taxon_id} => #{taxon_id}"
        sample_metadata.update_attributes(:sample_taxon_id => taxon_id)
        sample_metadata.save!
      end
    end
    raise "Test mode" unless mode == 'run'
  end
end
