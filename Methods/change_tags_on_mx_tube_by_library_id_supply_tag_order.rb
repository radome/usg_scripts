def change_tags_on_mx(tag_group,tags,mx_tube,rt_ticket,login,mode)
  version = "change_tag_on_mx_tube_std_supply_tag_order.rb version 2.3"
  puts "Supply: tags (in correct order i.e [1,2,4,8,3,5,6,7], tag_group (id), mx_tube (id), mode ('test'/'run')\n"
  puts "Running in test mode\n" unless mode == "run"
  
  ActiveRecord::Base.transaction do
    def set_false_tags(lib_aliquots, false_tag_hash)
      lib_tags = []
      c = false_tag_hash.size
      false_tag_hash.each do |library_id,tag|
        aliquots = Aliquot.where(library_id:library_id)
        aliquots.each do |aliquot|
          if aliquot.receptacle.class == QcTube 
            puts "Ignoring QcTube"
          elsif aliquot.tag_id != -1
            lib_tags.push(aliquot.tag)
            aliquot.tag_id = tag
            aliquot.save!
            lib_aliquots << aliquot
            puts "#{c} >> #{aliquot.receptacle.class.name} aliquot: #{aliquot.id} => Library: #{aliquot.library.name} => old tag: #{lib_tags.last.map_id} => new tag: #{aliquot.tag_id})"
          end
        end
        c -=1
      end
      return lib_aliquots
    end
  
    def change_tags(mx,lib_aliquots,lib_tag_hash,tag_group,rt_ticket,user,version)
      c = lib_aliquots.size
      version = "change_tags_on_batch_with_hash v 1.1"
      # puts "#{lib_aliquots.inspect}"
      lib_aliquots.each do |aliquot|
        aliquot.tag_id = TagGroup.find(tag_group).tags.select {|t| t.map_id == lib_tag_hash[aliquot.library.name]}.map(&:id).first
        aliquot.save!
        aliquot.reload
        puts "#{c} >> #{aliquot.receptacle.class.name} aliquot: #{aliquot.id} => Library: #{aliquot.library.name} => new tag: #{aliquot.tag.map_id} - #{aliquot.tag_id}"
        c -=1
      end
      lib_aliquots.map(&:library).uniq.each do |lib|
        comment_text = "#{user.login} changed tag from tag_group #{lib.aliquots.first.tag.tag_group.id} - tag #{lib.aliquots.first.tag.map_id} => tag_group #{tag_group} - tag #{lib_tag_hash[lib.aliquots.first.library.name]} requested via RT ticket #{rt_ticket} using #{version}"
        comment_on = lambda { |x| x.comments.create!(:description => comment_text, :user_id => user.id, :title => "Tag change #{rt_ticket}") }     
        comment_on.call(lib)
      end
    
      comment_text = "MX tube tags updated via RT#{rt_ticket}"
      comment_on = lambda { |x| x.comments.create!(:description => comment_text, :user_id => user.id, :title => "Tag change #{rt_ticket}") }
      comment_on.call(mx)
    end
  
    mx = Asset.find(mx_tube)
    lib_aliquots = []

    # find the library id's of the mx_tube
    lib_ids = mx.aliquots.map(&:library_id); nil
    user = User.find_by_login login
    # samples = mx.aliquots.map(&:sample).flatten.map(&:name)
    libs = mx.aliquots.map(&:library).map(&:name)
  
    # sample_tag_hash = Hash[samples.zip(tags)]
    lib_tag_hash = Hash[libs.zip(tags)]
    # keys = sample_tag_hash.keys; nil
    keys = lib_tag_hash.keys; nil
    problems = libs - keys
    if problems.empty?
      puts "Hash and mx.aliquots match. Proceeding..."
    else
      puts "Problems...\n#{problems.inspect}\n"
      raise "hash keys and mx samples do not match"
    end
  

    false_tag_hash = Hash[lib_ids.zip((1..lib_tag_hash.size).entries)]
  
    puts "lib_tag_hash: #{lib_tag_hash.inspect}\n\n"
    puts "false_tag_hash: #{false_tag_hash.inspect}"

    puts "Setting false tags on libraries"
    set_false_tags(lib_aliquots, false_tag_hash)

    puts "Assigning new tags"
    change_tags(mx,lib_aliquots,lib_tag_hash,tag_group,rt_ticket,user,version)

    raise "TESTING *********" unless mode == "run"
    batches = mx.requests.map(&:batch).uniq
    batches.each {|b| b.touch;b.save!;b.broadcast}
  end
end

# change_tags_on_mx(tag_group,tags,mx_tube,rt_ticket,login,mode)

