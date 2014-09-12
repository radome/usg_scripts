# samples = [
# [<sample id>,"<new_name>"],
# [<sample id>,"<new_name>"]
# ]

class Sample
 def with_sample_renaming(&block)
   send(:can_rename_sample=, true)
   yield
 ensure
   send(:can_rename_sample=, false)
 end
end

def update_sample_name_and_assets(samples,mode)
  ActiveRecord::Base.transaction do
    samples.each do |sample_info|
      sample = Sample.find_by_id sample_info[0]
      if sample.nil? 
        puts "Unable to find sample #{sample}"
      else
        sample.with_sample_renaming do
          sample.name = sample_info[1]
          sample.assets.select {|a| a.class == SampleTube}.map {|st| st.name = sample_info[1]; st.save!}
          sample.assets.select {|a| a.class == PacBioLibraryTube}.map {|pbt| pbt.name = sample_info[1]; pbt.save!}
          sample.assets.select {|a| a.class == LibraryTube}.map {|lt| lt.name = sample_info[1]+" "+"#{lt.id.to_s}"; lt.save!}
          
          sample.save(false)
        end
      end
    end
    raise "Hell!!!" unless mode == 'run'
  end
end