def change_tags_on_mx(sample_tag_hash,tag1_group_name,tag2_group_name,mx_tube,login,rt_ticket,mode)
  puts "Supply: sample_tag_hash (sample_name => map_id), tag_group (id), mx_tube (id), mode ('test'/'run')\n"
  puts "Running in test mode\n" unless mode == "run"

  ActiveRecord::Base.transaction do
  def set_false_tags(mx, lib_aliquots, false_tag_hash)
    lib_tags = []
    c = false_tag_hash.size
    false_tag_hash.each do |library,tag|
      aliquots = Aliquot.find_all_by_library_id(library)
      aliquots.each do |aliquot|
        if aliquot.receptacle.class == QcTube 
          puts "Ignoring QcTube"
        elsif aliquot.tag_id != -1
          lib_tags.push(aliquot.tag)
          aliquot.tag_id = tag
          # if no lanes all tag2_ids are set to -1 and clash in change_tags
          if mx.children.empty?
            aliquot.tag2_id = nil
          else
            aliquot.tag2_id = tag
          end
          aliquot.save(false)
          lib_aliquots << aliquot
          puts "#{c} >> #{aliquot.receptacle.class.name} aliquot: #{aliquot.id} => Sample: #{aliquot.sample.name} => old tag: #{lib_tags.last.map_id}(#{lib_tags.last.id}) => new tag: #{aliquot.tag.map_id}(#{aliquot.tag_id})"
        end
      end
      c -=1
    end
    return lib_aliquots
  end
  
  def change_tags(mx, lib_aliquots, sample_tag_hash, tag1_group_name, tag2_group_name, user, rt_ticket)
    c = lib_aliquots.size
    version = "change_tag1_tag2_on_mx_tube_and_lanes_v1.0"
    tag_group1 = TagGroup.find_by_name(tag1_group_name)
    tag_group2 = TagGroup.find_by_name(tag2_group_name)
    lib_aliquots.each do |aliquot|
      aliquot.tag_id = tag_group1.tags.select {|t| t.map_id == sample_tag_hash[aliquot.sample.name][0].to_i}.map(&:id).first
      aliquot.tag2_id = tag_group2.tags.select {|t| t.map_id == sample_tag_hash[aliquot.sample.name][1].to_i}.map(&:id).first
      aliquot.save!
      puts "#{c} >> #{aliquot.receptacle.class.name} aliquot: #{aliquot.id} => Sample: #{aliquot.sample.name} => new tag1: #{sample_tag_hash[aliquot.sample.name][0]} => new tag2: #{sample_tag_hash[aliquot.sample.name][1]}"
      c -=1
    end
    lib_aliquots.map(&:library).uniq.each do |lib|
      comment_text = "#{user.login} changed tags requested via RT ticket #{rt_ticket} using #{version}"
      comment_on = lambda { |x| x.comments.create!(:description => comment_text, :user_id => user.id, :title => "Tag change #{rt_ticket}") }
      comment_on.call(lib)
    end
  
    comment_text = "MX tube tags updated via RT#{rt_ticket}"
    comment_on = lambda { |x| x.comments.create!(:description => comment_text, :user_id => user.id, :title => "Tag change #{rt_ticket}") }
    comment_on.call(mx)
    mx.requests.first.batch.touch unless mx.requests.first.batch.nil?
  end
  
  mx = Asset.find(mx_tube)
  lib_aliquots = []
  
  # find the library id's of the mx_tube
  lib_ids = mx.aliquots.map(&:library_id); nil
  user = User.find_by_login login
  samples = mx.aliquots.map(&:sample).flatten.map(&:name); nil
  
  
  keys = sample_tag_hash.keys; nil
  problems = samples - keys
  if problems.empty?
    puts "Hash and mx.aliquots match. Proceeding..."
  else
    puts "Problems...\n#{problems.inspect}\n"
    raise "hash keys and mx samples do not match"
  end
  
  false_tag_hash = Hash[lib_ids.zip((1..sample_tag_hash.size).entries)]
  
  puts "sample_tag_hash: #{sample_tag_hash.inspect}\n\n"
  puts "false_tag_hash: #{false_tag_hash.inspect}"

  puts "Setting false tags on libraries"
  set_false_tags(mx, lib_aliquots, false_tag_hash)

  puts "Assigning new tags"
  change_tags(mx, lib_aliquots, sample_tag_hash, tag1_group_name, tag2_group_name, user, rt_ticket)

  raise "TESTING *********" unless mode == "run"
  end
end

# eg
# sample_tag_hash = {
# "sample1" => [72,1],
# "sample2" => [55,1],
# "sample3" => [61,2],
# "sample4" => [12,2]
# }
# mx_tube = 0123456789
# tag_group = 20
# mode = 'test'