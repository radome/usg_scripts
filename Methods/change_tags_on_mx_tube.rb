def change_tags_on_mx(tags,tag_group,mx_tube,mode,rt_ticket,login)
  version = "change_tag_on_mx_tube_std_order.rb version 2.0"
  puts "Supply: tags (in correct order i.e [1,2,4,8,3,5,6,7], tag_group (id), mx_tube (id), mode ('test'/'run')\n"
  puts "Running in test mode\n" unless mode == "run"
  
  ActiveRecord::Base.transaction do
  def set_false_tags(lib_aliquots, false_tag_hash)
    ActiveRecord::Base.transaction do
      lib_tags = []
      c = false_tag_hash.size
      false_tag_hash.each do |library,tag|
        # aliquots = Asset.find(library).aliquots.first.sample.aliquots
        aliquots = Aliquot.find_all_by_library_id(library)
        aliquots.each do |aliquot|
          if aliquot.receptacle.class == QcTube 
            puts "Ignoring QcTube"
          elsif
            aliquot.tag_id != -1
            lib_tags.push(aliquot.tag)
            aliquot.tag_id = tag
            aliquot.save!
            lib_aliquots << aliquot
            puts "#{c} >> #{aliquot.receptacle.class.name} aliquot: #{aliquot.id} => Sample: #{aliquot.sample.name} => old tag: #{lib_tags.last.map_id} => new tag: #{aliquot.tag.map_id}"
          end
        end
      c -=1
      end
    end
  end
  
  def change_tags(mx, lib_aliquots, sample_tag_hash, tag_group, rt_ticket, user, version)
    c = lib_aliquots.size
    lib_aliquots.map(&:library).uniq.each do |lib|
      comment_text = "#{user.login} changed tag from tag_group #{lib.aliquots.first.tag.tag_group.id} - tag #{lib.aliquots.first.tag.map_id} => tag_group #{tag_group} - tag #{sample_tag_hash[lib.aliquots.first.sample.name]} requested via RT ticket #{rt_ticket} using #{version}"
      comment_on = lambda { |x| x.comments.create!(:description => comment_text, :user_id => user.id, :title => "Tag change #{rt_ticket}") }     
      comment_on.call(lib)
    end
    lib_aliquots.each do |aliquot|
      puts "#{c} >> #{aliquot.receptacle.class.name} aliquot: #{aliquot.id} => Sample: #{aliquot.sample.name} => new tag: #{sample_tag_hash[aliquot.sample.name]}"
      aliquot.tag_id = TagGroup.find(tag_group).tags.select {|t| t.map_id == sample_tag_hash[aliquot.sample.name]}.map(&:id).first
      c -=1
    end
    comment_text = "MX tube tags updated via RT#{rt_ticket}"
    comment_on = lambda { |x| x.comments.create!(:description => comment_text, :user_id => user.id, :title => "Tag change #{rt_ticket}") }
    comment_on.call(mx)  
  end
  
  user = User.find_by_login login
  mx = Asset.find(mx_tube)
  lib_aliquots = []

  # find the library id's of the mx_tube
  lib_ids = mx.aliquots.map(&:library_id)
  
  samples = mx.aliquots.map(&:sample).flatten.map(&:name)
  
  sample_tag_hash = Hash[samples.zip(tags)]

  false_tag_hash = Hash[lib_ids.zip((1..sample_tag_hash.size).entries)]
  
  puts "sample_tag_hash: #{sample_tag_hash.inspect}\n\n"
  puts "false_tag_hash: #{false_tag_hash.inspect}"

  puts "Setting false tags on libraries"
  set_false_tags(lib_aliquots, false_tag_hash)

  puts "Assigning new tags"
  change_tags(mx,lib_aliquots,sample_tag_hash,tag_group,rt_ticket,user,version)

  raise "TESTING *********" unless mode == "run"
  end
end
