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

samples.each do |sample_info|
  sample = Sample.find sample_info[0]
  if sample.nil? 
    puts "Unable to find sample #{sample}"
  else
    sample.with_sample_renaming do
      sample.name = sample_info[1]
      sample.assets.select {|a| a.class == SampleTube}.map {|st| st.name = sample_info[1]; st.save!}
      sample.assets.select {|a| a.class == LibraryTube}.map {|lt| lt.name = sample_info[1]+" "+"#{lt.id.to_s}"; lt.save!}
      sample.save!
    end
  end
end