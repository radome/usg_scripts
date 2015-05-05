def change_specific_tags(mx_id,tags,rt_ticket,login,mode)
  ActiveRecord::Base.transaction do
    version = "change_specific_tags v 1.0"
    mx = MultiplexedLibraryTube.find mx_id
    tag_group = mx.aliquots.map(&:tag).map(&:tag_group).uniq.first
    user = User.find_by_login login
    old_tags = tags.keys
    aliquots = Aliquot.find_all_by_library_id(mx.aliquots.select {|a| old_tags.include?(a.tag.map_id)}.map(&:library_id))
    aliquots.each do |aliquot|
      if aliquot.receptacle.class == QcTube 
        puts "Ignoring QcTube"
      else
        aliquot.tag_id = TagGroup.find(tag_group).tags.select {|t| t.map_id == tags[aliquot.tag.map_id]}.map(&:id).first
        aliquot.save!
        aliquot.reload
        puts ">> #{aliquot.receptacle.class.name} aliquot: #{aliquot.id} => Sample: #{aliquot.sample.name} => new tag: #{aliquot.tag.map_id} - #{aliquot.tag_id}"
        lib = aliquot.library
        comment_text = "#{user.login} changed tag from tag_group #{lib.aliquots.first.tag.tag_group.id} - tag #{lib.aliquots.first.tag.map_id} => tag_group #{tag_group} - tag #{tags[aliquot.tag.map_id]} requested via RT ticket #{rt_ticket} using #{version}"
        comment_on = lambda { |x| x.comments.create!(:description => comment_text, :user_id => user.id, :title => "Tag change #{rt_ticket}") }     
        comment_on.call(lib)
      end
    end
    comment_text = "MX tube tags updated via RT#{rt_ticket}"
    comment_on = lambda { |x| x.comments.create!(:description => comment_text, :user_id => user.id, :title => "Tag change #{rt_ticket}") }
    comment_on.call(mx)
    raise "Hell!!!!!" unless mode == 'run'
  end
end


